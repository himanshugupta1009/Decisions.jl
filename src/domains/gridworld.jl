using Decisions

struct GridPointSpace <: Space{Tuple{Int, Int}}
    nrows::Int
    ncols::Int
end

Base.in(p::Tuple{Int, Int}, g::GridPointSpace) =
    (p[1] <= g.nrows) && (p[2] <= g.ncols) && (p[1] > 0) && (p[2] > 0)

Base.length(g::GridPointSpace) = g.nrows * g.ncols
Base.iterate(g::GridPointSpace) = iterate(Iterators.product(1:g.nrows, 1:g.ncols))
Base.iterate(g::GridPointSpace, state) = iterate(Iterators.product(1:g.nrows, 1:g.ncols), state)


@enum Cardinal NORTH EAST SOUTH WEST

function is_in_bounds(p, nrows, ncols)
    (p[1] <= nrows) && (p[2] <= ncols) && (p[1] > 0) && (p[2] > 0)
end

function rel_dirs(s, a)
    (forward, left, right) = if a == NORTH
        (s[1]-1, s[2]), (s[1], s[2]-1), (s[1], s[2]+1)
    elseif a == EAST
        (s[1], s[2]+1), (s[1]-1, s[2]), (s[1]+1, s[2])
    elseif a == SOUTH
        (s[1]+1, s[2]), (s[1], s[2]+1), (s[1], s[2]-1)
    else
        (s[1], s[2]-1), (s[1]+1, s[2]), (s[1]-1, s[2])
    end
    (forward, left, right, s)
end

function Iceworld(; p_slip, nrows, ncols, holes, target)
    transition = @ConditionalDist Tuple{Int, Int} begin
        function support(; s, a)
            if ismissing(s) && ismissing(a)
                GridPointSpace(nrows, ncols)
            else
                FiniteSpace(
                    [d for d in rel_dirs(kw[:s], kw[:a]) if is_in_bounds(d, nrows, ncols)]
                )
            end
        end

        function rand(rng; s, a)
            if s == target
                return Terminal()
            end

            forward, left, right, stay = rel_dirs(s, a)
            p_f = is_in_bounds(forward, nrows, ncols) ? (1-p_slip) : 0.0
            p_l = is_in_bounds(left,    nrows, ncols) ? (p_slip/2) : 0.0
            p_r = is_in_bounds(right,   nrows, ncols) ? (p_slip/2) : 0.0

            r = rand(rng)
            r > p_f             || return forward
            r > p_f + p_r       || return right
            r > p_f + p_r + p_l || return left
            stay
        end

        function logpdf(sp; s, a)
            is_in_bounds(sp, nrows, ncols) || return -Inf
            
            forward, left, right, stay = rel_dirs(s, a)
            if sp == left || sp == right
                p_slip/2
            elseif sp == forward
                1-p_slip
            elseif sp == stay
                p_stay = 0
                p_stay += is_in_bounds(forward, nrows, ncols) ? (1-p_slip) : 0
                p_stay += is_in_bounds(left,    nrows, ncols) ? (p_slip/2) : 0 
                p_stay += is_in_bounds(right,   nrows, ncols) ? (p_slip/2) : 0 
                p_stay
            else
                -Inf
            end |> log
        end
    end


    reward = @ConditionalDist Real begin
        function rand(rng; s, a, sp)
            if sp == target
               10
            elseif sp ∈ holes
                -20
            else 
                -0.01
            end
        end
    end

    Decisions.MDP_DN(;
        sp=transition,
        r=reward,
        a=FiniteSpace([NORTH, SOUTH, EAST, WEST])
    )
end

mdp = Iceworld(; p_slip=0.3, nrows=10, ncols=10, holes=(), target=(10, 10))

π = @ConditionalDist Cardinal begin
    function rand(rng; s, m)
        rand(rng, [NORTH, SOUTH, EAST, WEST])
    end
end

μ = @ConditionalDist Nothing begin
    rand(rng; m, s, a) = nothing
end

sample(mdp, (; a=π, mp=μ), (; s=(1, 1))) do output
    println(output)
    false
end