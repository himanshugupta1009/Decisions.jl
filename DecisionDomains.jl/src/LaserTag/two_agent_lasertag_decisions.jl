using DecisionNetworks
using DecisionProblems
using StaticArrays, Random
# using Distributions        # optional if you use pdf/support helpers that need it

# --- Action set as an enum (isbits & StaticArrays-friendly) ---
@enum LTAct Left=1 Right=2 Up=3 Down=4 LeftUp=5 RightUp=6 LeftDown=7 RightDown=8 Measure=9

const Pos = SVector{2,Int}

# 2-agent state, isbits
struct LT2State
    r1::Pos
    r2::Pos
    t::Pos
end

in_bounds(p::Pos, size::Pos) = (1 <= p[1] <= size[1]) & (1 <= p[2] <= size[2])

# move one robot by enum action with bounds/obstacle checks
function move_robot(size::Pos, blocked::BitArray{2}, p::Pos, a::LTAct)
    δ = a === Left      ? SVector(0,-1) :
        a === Right     ? SVector(0, 1) :
        a === Up        ? SVector(-1,0) :
        a === Down      ? SVector( 1,0) :
        a === LeftUp    ? SVector(-1,-1) :
        a === RightUp   ? SVector(-1, 1) :
        a === LeftDown  ? SVector( 1,-1) :
        a === RightDown ? SVector( 1, 1) :
        SVector(0,0)   # Measure ⇒ no movement
    np = p + δ
    (in_bounds(np, size) && !blocked[np...]) ? np : p
end

# one-step lazy random walk for the target (stay/N/E/S/W if legal)
function step_target(rng::AbstractRNG, size::Pos, blocked::BitArray{2}, t::Pos)
    candidates = Pos[t,
                     t + SVector(-1,0), t + SVector(1,0),
                     t + SVector(0,-1), t + SVector(0,1)]
    candidates = [p for p in candidates if in_bounds(p, size) && !blocked[p...]]
    candidates[rand(rng, 1:length(candidates))]
end


"""
    LaserTagCoop2(; size=(10,7), n_obstacles=9, rng=MersenneTwister(20))

2-agent fully observable cooperative Markov Game.
State s = (r1, r2, t)
Actions a[i] ∈ LTAct for i=1,2
Shared reward.
"""
function LaserTagCoop2(; size=(10,7), n_obstacles=9, rng=MersenneTwister(20))
    sizev = SVector(size...)
    blocked = falses(size...)
    obstacles = Set{Pos}()

    # obstacles
    while length(obstacles) < n_obstacles
        o = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
        if !blocked[o...]
            push!(obstacles, o); blocked[o...] = true
        end
    end

    # initial robot positions (distinct, not blocked)
    r1 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    while blocked[r1...] ; r1 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2])) ; end

    r2 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    while blocked[r2...] || r2 == r1
        r2 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    end

    # initial target (not blocked, not on either robot)
    t0 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    while blocked[t0...] || t0 == r1 || t0 == r2
        t0 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    end

    # initial node: just s (MGs don’t need belief/memory, right?)
    initial = @ConditionalDist @NamedTuple{s::LT2State} begin
        rand(rng; ) = (; s = LT2State(r1, r2, t0))
    end

    # transition: sp | s, a   (a is stacked -> SVector{2,LTAct})
    transition = @ConditionalDist LT2State begin
        function rand(rng; s, a)
            new_r1 = move_robot(sizev, blocked, s.r1, a[1])
            new_r2 = move_robot(sizev, blocked, s.r2, a[2])

            # capture if any robot reaches the target after robot move
            if (new_r1 == s.t) || (new_r2 == s.t)
                return DecisionNetworks.Terminal()
            end

            t_next = step_target(rng, sizev, blocked, s.t)

            # capture after target moves
            if (new_r1 == t_next) || (new_r2 == t_next)
                return DecisionNetworks.Terminal()
            end

            LT2State(new_r1, new_r2, t_next)
        end
    end

    reward = @ConditionalDist Float64 begin
        function rand(rng; s, a, sp, i)
            captured = (sp isa DecisionNetworks.Terminal)
            step_cost(ai::LTAct) = (ai == Measure ? -2.0 : -1.0)
            base = step_cost(a[1]) + step_cost(a[2])
            captured ? (100.0 + base) : base
        end
    end

    # per-agent action space
    a_space = FiniteSpace((Left, Right, Up, Down, LeftUp, RightUp, LeftDown, RightDown, Measure))

    #MG: 2-agent plate i=1:2, action nodes are plated a[i]
    MG(
        DiscountedReward(0.99),
        initial, 
        (; i = 2);
        a = a_space,
        sp = transition,
        r  = reward
    )
end


#=
solver


import DecisionProblems: DecisionAlgorithm, DecisionProblem, solve
import DecisionNetworks: support  # ensure we call the right `support`

struct RandomCoopSolver <: DecisionAlgorithm end

function solve(::RandomCoopSolver, dp::DecisionProblem)
    # For a plated action node a[i], Decisions calls rand(rng; s, i) for each agent i
    pol = @ConditionalDist LTAct begin
        rand(rng; s, i) = rand(rng, support(dp[:a]))  # same space for both agents
    end
    (; a = pol)
end


# run to terminal (capture) and get discounted return
coop_lt_prob = LaserTagCoop2()
coop_lt_solver = RandomCoopSolver()
simulate!(coop_lt_solver, coop_lt_prob) do vals
    println(vals)  # vals is a NamedTuple with keys :a, :r, :sp
end

# or: fixed N steps (using the callback)
function run_2p_episode(; steps=10, rng=MersenneTwister(0))
    prob = LaserTagCoop2(rng=rng)
    t = 0
    simulate!(vals -> begin
        t += 1
        # vals[:a] :: SVector{2,LTAct}, vals[:r] :: Float64, vals[:sp] :: LT2State or Terminal
        println("step $t | a=$(vals[:a])  r=$(vals[:r])")
        t >= steps
    end, RandomCoopSolver(), prob)
end


=#


