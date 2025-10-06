using Decisions                 # reexports DecisionNetworks + DecisionProblems
using StaticArrays, Random


@enum LTAct Left=1 Right=2 Up=3 Down=4 LeftUp=5 RightUp=6 LeftDown=7 RightDown=8 Measure=9
const Pos = SVector{2,Int}

"""
State for n agents:
- robots: SVector{N,Pos}
- t:      target position
Make N a type param so it's concrete: LTnState{N}
"""
struct LTnState{N}
    robots::SVector{N,Pos}
    t::Pos
end

in_bounds(p::Pos, size::Pos) = (1 <= p[1] <= size[1]) & (1 <= p[2] <= size[2])

# Move one robot by an enum action with obstacle/bounds checks
function move_robot_enum(size::Pos, blocked::BitArray{2}, p::Pos, a::LTAct)
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

# One step lazy random-walk for the target (stay/N/E/S/W if legal)
function step_target(rng::AbstractRNG, size::Pos, blocked::BitArray{2}, t::Pos)
    candidates = Pos[t,
                     t + SVector(-1,0), t + SVector(1,0),
                     t + SVector(0,-1), t + SVector(0,1)]
    candidates = [p for p in candidates if in_bounds(p, size) && !blocked[p...]]
    candidates[rand(rng, 1:length(candidates))]
end

# ========= n-agent cooperative MG =========
"""
    LaserTagCoopMG(; n=2, size=(10,7), n_obstacles=9, rng=MersenneTwister(20))

Build an n-agent fully observable cooperative Markov Game:
- State  s = (robots::SVector{n,Pos}, t::Pos)
- Actions a[i] ∈ LTAct (plated over i=1..n)
- Transition: robots move by their actions; target random-walks
- Reward: shared scalar (cooperative): +100 if any robot tags target, step costs otherwise
"""
function LaserTagCoopMG(; n::Int=2, size=(10,7), n_obstacles=9, rng=MersenneTwister(20))
    @assert n >= 1
    sizev = SVector(size...)
    blocked = falses(size...)
    obstacles = Set{Pos}()

    # Obstacles
    while length(obstacles) < n_obstacles
        o = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
        if !blocked[o...]
            push!(obstacles, o); blocked[o...] = true
        end
    end

    # Sample n distinct robot starts not on obstacles
    robots = Pos[]
    while length(robots) < n
        rpos = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
        if !blocked[rpos...] && !(rpos in robots)
            push!(robots, rpos)
        end
    end
    robotsv = SVector{n,Pos}(robots)

    # Sample target not on obstacles and not overlapping robots
    t0 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    while blocked[t0...] || any(r->r==t0, robots)
        t0 = SVector(rand(rng, 1:sizev[1]), rand(rng, 1:sizev[2]))
    end

    # ---- Initial state distribution (deterministic here) ----
    initial = @ConditionalDist @NamedTuple{s::LTnState{n}} begin
        rand(rng; ) = (; s = LTnState{n}(robotsv, t0))
    end

    # ---- Transition: sp | s, a (a is SVector{n,LTAct}) ----
    transition = @ConditionalDist LTnState{n} begin
        function rand(rng; s::LTnState{n}, a)
            # move robots independently
            new_robots = ntuple(i->move_robot_enum(sizev, blocked, s.robots[i], a[i]), n)
            robots_next = SVector{n,Pos}(new_robots)

            # if any robot already at target after moving, terminate
            if any(i->robots_next[i]==s.t, 1:n)
                return DecisionNetworks.Terminal()
            end

            # target step
            t_next = step_target(rng, sizev, blocked, s.t)

            # if any robot caught target after target moves, terminate
            if any(i->robots_next[i]==t_next, 1:n)
                return DecisionNetworks.Terminal()
            end

            LTnState{n}(robots_next, t_next)
        end
    end

    # ---- Shared (cooperative) reward: r | s, a, sp ----
    reward = @ConditionalDist Float64 begin
        function rand(rng; s::LTnState{n}, a, sp)
            # +100 on capture (Terminal() means captured this step)
            captured = (sp isa DecisionNetworks.Terminal)
            # per-agent step costs
            step_cost(ai::LTAct) = (ai == Measure ? -2.0 : -1.0)
            base = sum(step_cost, a)
            captured ? (100.0 + base) : base
        end
    end

    # ---- Per-agent action space ----
    a_space = FiniteSpace((Left, Right, Up, Down, LeftUp, RightUp, LeftDown, RightDown, Measure))

    # ---- Assemble the MG DecisionProblem ----
    MG(DiscountedReward(0.997), initial, (; i = n);
       a = a_space,   # plated action node a[i]
       sp = transition,
       r  = reward)
end

# ========= A trivial n-agent joint policy (independent uniform) =========

import DecisionProblems: DecisionAlgorithm, DecisionProblem, solve

struct RandomCoopSolver <: DecisionAlgorithm end

function solve(::RandomCoopSolver, dp::DecisionProblem)
    # For a plated action node a[i], this returns a per-agent ConditionalDist:
    pol = @ConditionalDist LTAct begin
        rand(rng; s, i) = rand(rng, DecisionNetworks.support(dp[:a]))  # same support for all i
    end
    (; a = pol)
end

# ========= Example run =========

function run_coop_episode(; n=3, steps=10, rng=MersenneTwister(0))
    prob = LaserTagCoopMG(n=n, rng=rng)
    t = 0
    simulate!(vals -> begin
        t += 1
        # vals[:a] :: SVector{n,LTAct}, vals[:r] :: Float64, vals[:sp] :: LTnState{n} or Terminal
        println("step $t | a=$(vals[:a])  r=$(vals[:r])")
        t >= steps
    end, RandomCoopSolver(), prob)
end
