using StaticArrays, Random


@enum TAct Left=1 Right=2 Up=3 Down=4 Measure=5
const Pos = SVector{2,Int}

struct T2State
    r1::Pos
    r2::Pos
    t::Pos
end

in_bounds(p::Pos, sz::Pos) = (1 <= p[1] <= sz[1]) & (1 <= p[2] <= sz[2])

# One-step robot move under enum action with bounds/obstacles
function move_robot(sz::Pos, blocked::BitArray{2}, p::Pos, a::TAct)
    δ = a === Left      ? SVector(0,-1) :
        a === Right     ? SVector(0, 1) :
        a === Up        ? SVector(-1,0) :
        a === Down      ? SVector( 1,0) :
        SVector(0,0)   # Measure ⇒ no movement
    np = p + δ
    (in_bounds(np, sz) && !blocked[np...]) ? np : p
end

# Target candidate positions (lazy random walk: stay/N/E/S/W)
function target_candidates(sz::Pos, blocked::BitArray{2}, t::Pos)
    cands = Pos[t,
                t + SVector(-1,0), t + SVector(1,0),
                t + SVector(0,-1), t + SVector(0,1)]
    [p for p in cands if in_bounds(p, sz) && !blocked[p...]]
end

function TagCoop2_explicit(; size=(2,2), n_obstacles=1, rng=MersenneTwister(20))
    sz = SVector(size...)
    blocked = falses(size...)
    obstacles = Set{Pos}()

    # obstacles
    while length(obstacles) < n_obstacles
        o = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
        if !blocked[o...]
            push!(obstacles, o); blocked[o...] = true
        end
    end

    # initial robots (distinct, not blocked)
    r1 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
    while blocked[r1...] ; r1 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2])) ; end
    r2 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
    while blocked[r2...] || r2 == r1
        r2 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
    end

    # initial target (not blocked, not on robots)
    t0 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
    while blocked[t0...] || t0 == r1 || t0 == r2
        t0 = SVector(rand(rng, 1:sz[1]), rand(rng, 1:sz[2]))
    end

    initial = @ConditionalDist @NamedTuple{s::T2State} begin
        # Deterministic:
        support(; ) = (; s = T2State(r1, r2, t0))
        pdf(x; )    = (x == (; s = T2State(r1, r2, t0)) ? 1.0 : 0.0)
        rand(rng; ) = (; s = T2State(r1, r2, t0))
        # In case we want uniform initial?
    end

    transition = @ConditionalDist T2State begin
        function support(; s, a)
            if isnothing(s) || isnothing(a)
                els = map(Iterators.product(1:size[1], 1:size[2], 
                                            1:size[1], 1:size[2], 
                                            1:size[1], 1:size[2])) do (x1, y1, x2, y2, xt, yt)
                    T2State(
                        SVector((x1, y1)),
                        SVector((x2, y2)),
                        SVector((xt, yt)),
                    )
                end
                return FiniteSpace(els)
            end

            # robot moves (deterministic)
            new_r1 = move_robot(sz, blocked, s.r1, a[1])
            new_r2 = move_robot(sz, blocked, s.r2, a[2])

            # capture right after robot move → only Terminal possible
            if (new_r1 == s.t) || (new_r2 == s.t)
                return (Terminal(),)
            end

            # otherwise target random-walks uniformly over candidates
            cands = target_candidates(sz, blocked, s.t)
            # Split candidate moves into those that cause capture and those that don't
            captured = [t′ for t′ in cands if (new_r1 == t′) || (new_r2 == t′)]
            safe     = [t′ for t′ in cands if (new_r1 != t′) && (new_r2 != t′)]

            # Support includes Terminal (if any captured moves) and all nonterminal next states
            outs = Any[]
            if !isempty(captured)
                push!(outs, Terminal())
            end
            append!(outs, [T2State(new_r1, new_r2, t′) for t′ in safe])
            Tuple(outs)
        end

        function pdf(sp; s, a)
            new_r1 = move_robot(sz, blocked, s.r1, a[1])
            new_r2 = move_robot(sz, blocked, s.r2, a[2])

            # Immediate capture after robot move
            if (new_r1 == s.t) || (new_r2 == s.t)
                return sp isa Terminal ? 1.0 : 0.0
            end

            cands = target_candidates(sz, blocked, s.t)
            n = length(cands)                        # uniform over candidates
            captured = count(t′ -> (new_r1==t′) || (new_r2==t′), cands)

            if sp isa Terminal
                return captured / n
            else
                # sp must be T2State(new_r1,new_r2,t′) for some t′ not captured
                (sp isa T2State) || return 0.0
                (sp.r1 == new_r1 && sp.r2 == new_r2 && sp.t ∈ cands && sp.t != new_r1 && sp.t != new_r2) || return 0.0
                return 1.0 / n
            end
        end

        function rand(rng; s, a)
            new_r1 = move_robot(sz, blocked, s.r1, a[1])
            new_r2 = move_robot(sz, blocked, s.r2, a[2])

            # Immediate capture after robot move
            if (new_r1 == s.t) || (new_r2 == s.t)
                return Terminal()
            end

            cands = target_candidates(sz, blocked, s.t)
            t′ = cands[Random.rand(rng, 1:length(cands))]  # uniform random-walk
            ((new_r1 == t′) || (new_r2 == t′)) ? Terminal() : T2State(new_r1, new_r2, t′)
        end
    end

    reward = @ConditionalDist Float64 begin
        function rand(rng; s, a, sp, i)
            captured = (sp isa Terminal)
            step_cost(ai::TAct) = (ai == Measure ? -2.0 : -1.0)
            base = step_cost(a[1]) + step_cost(a[2])
            captured ? (100.0 + base) : base
        end
        # `support` and `pdf` are optional for rewards; omitted for brevity.
    end

    # ---- Per-agent action space (plated node a[i]) ----
    a_space = FiniteSpace((Left, Right, Up, Down, Measure))

    MG(DiscountedReward(0.99), initial, (; i = 2);
       a = a_space,
       sp = transition,
       r  = reward)
end