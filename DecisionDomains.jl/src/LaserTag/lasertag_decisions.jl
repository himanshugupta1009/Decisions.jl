using DecisionNetworks
using DecisionProblems
using POMDPTools
include("lasertag_pomdp.jl")  # POMDPs.jl LaserTag model

"""
LaserTagDecisionsPOMDP(; pomdp = DiscreteLaserTagPOMDP())
Wrap an existing LaserTag POMDP using Decisions.jl
"""
function LaserTagDecisionsPOMDP(; pomdp = DiscreteLaserTagPOMDP())

    # Belief updater
    up = POMDPTools.DiscreteUpdater(pomdp)
    # Initial belief over LTState
    m0 = POMDPs.initialize_belief(up, POMDPs.initialstate(pomdp))

    # Delegates to POMDPs.transition(m, s, a)
    lt_transition = @ConditionalDist LTState begin
        function support(; s, a)
            # Global query: tell Decisions the full state space type/range.
            if isnothing(s) || isnothing(a)
                # For discrete models, POMDPTools.ordered_states gives the (finite) state list
                POMDPTools.ordered_states(pomdp)
            else
                Distributions.support(POMDPs.transition(pomdp, s, a))
            end
        end
        function rand(rng; s, a)
            if POMDPs.isterminal(pomdp, s)
                return DecisionNetworks.Terminal()
            else
                return rand(rng, POMDPs.transition(pomdp, s, a))
            end
        end
        function pdf(sp; s, a)
            # If we emit Terminal() above, we can return 0.0 here unless our model
            # has explicit mass on a terminal symbol; (Can be modified as needed.
            Distributions.pdf(POMDPs.transition(pomdp, s, a), sp)
        end
    end

    # Delegates to POMDPs.reward(m, s, a, sp)
    lt_reward = @ConditionalDist Float64 begin
        rand(rng; s, a, sp) = POMDPs.reward(pomdp, s, a, sp)
    end

    # For LaserTag, the model defines: POMDPs.observation(m, a, sp) -> no dependence on s
    # Decisions.jl's POMDP accepts s,a,sp for parents of o, so we include s as well.
    # But we don't use it in the implementation.
    lt_observation = @ConditionalDist SVector{5,Int} begin
        function support(; s, a, sp)
            if isnothing(a) || isnothing(sp)
                # Global observation space for introspection
                POMDPTools.ordered_observations(pomdp)
            else
                Distributions.support(POMDPs.observation(pomdp, a, sp))
            end
        end
        function rand(rng; s, a, sp)
            rand(rng, POMDPs.observation(pomdp, a, sp))
        end
        function pdf(o; s, a, sp)
            Distributions.pdf(POMDPs.observation(pomdp, a, sp), o)
        end
    end

    # Deterministic belief update via POMDPTools.DiscreteUpdater
    lt_memory = @ConditionalDist typeof(m0) begin
        support(; m, a, o) = POMDPs.update(up, m, a, o)   # single belief-point support?
        rand(rng; m, a, o) = POMDPs.update(up, m, a, o)
        function pdf(mp; m, a, o)
            # deterministic: probability 1 if equal to the true update, else 0
            POMDPs.update(up, m, a, o) == mp ? 1.0 : 0.0
        end
    end

    # ---------- Initial memory (belief at t=0) ----------
    # lt_initial = @ConditionalDist @NamedTuple{m::typeof(m0)} begin
    #     support(; ) = m0
    #     pdf(m; )    = (m == m0 ? 1.0 : 0.0)
    #     rand(rng; )    = m0
    # end

    lt_initial = @ConditionalDist @NamedTuple{s::LTState, m::typeof(m0)} begin
        # sample s ~ m0 and set m = m0
        rand(rng; ) = (; s = rand(rng, m0), m = m0)
        support(; )   = [ (; s = s, m = m0) for s in POMDPTools.ordered_states(pomdp) ]
    end

    # Actions in our model are Symbols. For single-agent POMDPs this is fine.
    # (No agent plate here, so we won’t hit StaticArrays issues from Symbols.)
    lt_action = @ConditionalDist Symbol begin
        support(; m) = POMDPs.actions(pomdp)                  # e.g. (:left, :right, …)
        rand(rng; m) = rand(rng, POMDPs.actions(pomdp))       # uniform random (override later)
    end

    # ---------- Assemble Decisions.POMDP decision problem ----------
    return DecisionProblems.POMDP(
        DiscountedReward(POMDPs.discount(pomdp)),   # use your model’s gamma
        lt_initial;                                  # initial memory/belief node
        sp = lt_transition,                          # state transition
        r  = lt_reward,                              # reward
        o  = lt_observation,                         # observation
        mp = lt_memory,                              # belief update
        a  = lt_action                               # action decision node
    )
end


"""
episode_lasertag_decisions(; steps=10, 
                rng = MersenneTwister(0), pomdp=DiscreteLaserTagPOMDP())

Runs a random policy for `steps` steps on the Decisions-wrapped LaserTag POMDP.
Returns a vector of NamedTuples with (t, a, r, o) and the discounted return.
"""

struct RandomSolver <: DecisionAlgorithm end

function DecisionProblems.solve(::RandomSolver, dp::DecisionProblem)
    # sample uniformly from the declared action space of the problem
    pol = @ConditionalDist Symbol begin
        rand(rng; m) = rand(rng, DecisionNetworks.support(dp[:a];m=m))   
        # dp[:a] is the action node; support(...) is the space
    end
    (; a = pol)   # MUST be a NamedTuple keyed by action node names
end

function episode_lasertag_decisions(; steps=10, rng = MersenneTwister(0), 
                                pomdp = DiscreteLaserTagPOMDP())

    lt_prob = LaserTagDecisionsPOMDP(; pomdp)
    lt_random_solver = RandomSolver()
    
    traj = NamedTuple[]
    G = 0.0
    γ = POMDPs.discount(pomdp)
    t = 0
    println("Starting Episode...")
    #Q: How to pass an rng here?
    #Q: How to set a particular initial state?
    simulate!(lt_random_solver, lt_prob) do vals
        t += 1
        println("Step $t: a=$(vals[:a]), r=$(vals[:r]), o=$(vals[:o])")
        push!(traj, (; t, a = vals[:a], r = vals[:r], o = vals[:o]))
        G += (γ^(t-1)) * vals[:r]
        t >= steps
    end
    return (; traj, G)
end


#=

using DecisionNetworks
using DecisionProblems
using POMDPTools
using POMDPs

include("DecisionDomains.jl/src/LaserTag/lasertag_decisions.jl")
lt_prob = LaserTagDecisionsPOMDP()
lt_solver = RandomSolver()

episode_lasertag_decisions()

simulate!(lt_solver, lt_prob) do vals
    println(vals)
    false  # run forever (Ctrl-C to stop)
end

=#
