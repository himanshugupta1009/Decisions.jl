import DecisionNetworks: support
import DecisionProblems: DecisionAlgorithm, DecisionProblem, solve
include("two_agent_lasertag_decisions.jl")

"""
    induce_mdp_from_mg(mg::DecisionProblem; i::Int=1, π_opponent)

Given a 2-agent MG DecisionProblem `mg` (fully observable),
fix the other agent's policy `π_opponent` (a ConditionalDist over the per-agent action),
and return an MDP DecisionProblem for agent i.

Assumes MG has nodes: a[i], sp | s,a, and r[i] | s,a,sp,i   (MG_DN default).
If reward is shared (single scalar), code handles that.
"""
function induce_mdp_from_mg(mg::DecisionProblem; i::Int=1, π_opponent)
    @assert i == 1 || i == 2
    opp = (i == 1 ? 2 : 1)

    γ_mg = DecisionProblems.objective(mg).discount             # Discount factor (DiscountedReward)
    γ = γ_mg isa Number ? γ_mg : γ_mg[1]

    init_mdp = mg.initial

    A_i = support(mg[:a])           # per-agent action space (enum, etc.)

    # --- Transition sp | s, a_i  (internally samples opponent action from π_opponent)
    sp_mdp = @ConditionalDist LT2State begin
        function rand(rng; s, a)  # here `a` is the *single-agent* action for agent i
            # Build joint action for the MG:
            a_opp = rand(rng, π_opponent; s=s, i=opp)
            a_joint = if i == 1
                SVector(a, a_opp)
            else
                SVector(a_opp, a)
            end
            # Delegate to MG transition:
            rand(rng, mg[:sp]; s=s, a=a_joint)
        end
    end

    # --- Reward r | s, a_i, sp  (pull agent i's payoff from MG reward node)
    r_mdp = @ConditionalDist Float64 begin
        function rand(rng; s, a, sp)
            a_opp = rand(rng, π_opponent; s=s, i=opp)
            a_joint = (i == 1) ? SVector(a, a_opp) : SVector(a_opp, a)

            # Two cases: MG has per-agent reward r[i] or a shared scalar r
            if haskey(nodes(network(mg)), :r) && getfield(nodes(network(mg))[:r], :is_plated) === true
                # per-agent reward node: r[i] | s,a,sp,i
                rand(rng, mg[:r]; s=s, a=a_joint, sp=sp, i=i)
            else
                # shared reward node: r | s,a,sp (ignore i)
                rand(rng, mg[:r]; s=s, a=a_joint, sp=sp)
            end
        end
    end

    a_i = FiniteSpace(A_i)

    return MDP(DiscountedReward(γ), init_mdp;
               sp = sp_mdp,
               r  = r_mdp,
               a  = a_i)
end


# Simple opponent policy: uniform over its action space
function uniform_opponent_policy(mg)
    @ConditionalDist eltype(support(mg[:a])) begin
        rand(rng; s, i) = rand(rng, support(mg[:a]))
    end
end

# A random solver for the demo
struct RandomMDPSolver <: DecisionAlgorithm end
function solve(::RandomMDPSolver, dp::DecisionProblem)
    pol = @ConditionalDist eltype(support(dp[:a])) begin
        rand(rng; s) = rand(rng, support(dp[:a]))
    end
    (; a = pol)
end

# Iterative Best Response
function IBR_two_player(mg::DecisionProblem; max_iters=10)
    # Start with uniform opponent for agent 2
    π2 = uniform_opponent_policy(mg)

    for k in 1:max_iters
    # (Optional) check convergence of policies / values and break

        println("IBR iteration $k")

        # Best response for agent 1 against π2
        mdp1 = induce_mdp_from_mg(mg; i=1, π_opponent=π2)
        # <- solve mdp1 with an MDP solver to get π1*
        br1 = solve(RandomMDPSolver(), mdp1)

        # Now fix agent 1 and compute best response for agent 2
        π1 = br1.a  # per-state policy for agent 1
        mdp2 = induce_mdp_from_mg(mg; i=2, π_opponent=π1)
        br2 = solve(RandomMDPSolver(), mdp2)

        # Update opponent policies
        π2 = br2.a
    end
end

#=

include("DecisionDomains.jl/src/LaserTag/fsp_lasertag.jl")
coop_lt_prob = LaserTagCoop2()
IBR_two_player(coop_lt_prob; max_iters=5)

=#




#=
uniform_opponent(mg) = @ConditionalDist eltype(support(mg[:a])) begin
    rand(rng; s, i) = rand(rng, support(mg[:a]))
end

function induce_mdp_from_LaserTagMG(mg::DecisionProblems.DecisionProblem;
                                    i::Int=1,
                                    π_opponent)
    @assert i==1 || i==2
    opp = 3 - i

    γ_mg = DecisionProblems.objective(mg).discount[1]   # Discount factor from DiscountedReward
    γ = γ_mg isa Number ? γ_mg : γ_mg[i]   # pick agent i’s scalar γ
    A_i = support(mg[:a])                       # per-agent action space (enum values)
    a_i_space = FiniteSpace(A_i)

    # Reuse MG initial (usually (; s=...));
    initial = mg.initial

    # --- Induced transition: sp | s, a_i ---
    sp_mdp = @ConditionalDist LT2State begin
        function rand(rng; s, a)      # here `a` is the *single-agent* action
            a_opp = rand(rng, π_opponent; s=s, i=opp)
            a_joint = (i==1) ? SVector(a, a_opp) : SVector(a_opp, a)
            rand(rng, mg[:sp]; s=s, a=a_joint)  # delegate to MG transition
        end
    end

    # --- Induced reward: r | s, a_i, sp ---
    r_mdp = @ConditionalDist Float64 begin
        function rand(rng; s, a, sp)
            a_opp = rand(rng, π_opponent; s=s, i=opp)
            a_joint = (i==1) ? SVector(a, a_opp) : SVector(a_opp, a)
            # Per-agent reward node (MG_DN default): r[i] | s,a,sp,i
            rand(rng, mg[:r]; s=s, a=a_joint, sp=sp, i=i)
        end
    end

    MDP(DiscountedReward(γ), initial;
        sp = sp_mdp,
        r  = r_mdp,
        a  = a_i_space)
end

mg   = LaserTagCoop2()
π2   = uniform_opponent(mg)
mdp1 = induce_mdp_from_LaserTagMG(mg; i=1, π_opponent=π2)

=#