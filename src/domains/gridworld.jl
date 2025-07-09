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

iceworld_transition(; p_slip, nrows, ncols) = @ConditionalDist Tuple{Int, Int} begin
    function support(; kw...)
        if isempty(kw)
            GridPointSpace(nrows, ncols)
        else
            FiniteSpace(
                [d for d in rel_dirs(kw[:s], kw[:a]) if is_in_bounds(d, nrows, ncols)]
            )
        end
    end

    function rand(rng; s, a)
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

function Iceworld(nrows, ncols, targ; holes=[], p_forward=1.0)

    transition = CategoricalDist((:state, :action)) do (state, action)

        if state == targ
            return Terminal()
        end

        

        p_slide = (1 - p_forward) / 2

        p_left    = (is_in_bounds(left,    nrows, ncols)) ? p_slide   : 0
        p_right   = (is_in_bounds(right,   nrows, ncols)) ? p_slide   : 0
        p_forward = (is_in_bounds(forward, nrows, ncols)) ? p_forward : 0
        p_stay = 1 - (p_forward + p_left + p_right)
        Dict(
            foward    => p_forward,
            rel_left  => p_left,
            rel_right => p_right,
            state     => p_stay
        )
    end

    reward = DeterministicDist((:s, :a, :sp)) do (s, a, sp)
        if sp == targ
            return 10
        elseif sp ∈ holes
            return -100
        else
            return -0.01
        end
    end

    MDP(transition, reward)
end







# ====


@with_kw struct FourByThreeGridWorld <: DMProblem
    pr_forward::Real = 0.8
end

const FourByThreeGridWorldState = DMState{1, 2, Int}
const FourByThreeGridWorldAction = DMAction{1, 1, Int}
const FourByThreeGridWorldReward = DMReward{1, 1, Real}

#const LEFT = 1     # Defined in `tiger.jl`.
#const RIGHT = 2    # Defined in `tiger.jl`.
const UP = 3
const DOWN = 4

# NOTE: States are (x, y) as though on a plot with the origin (0, 0) on the bottom left corner.
DecisionMaking.𝒮(𝒫::FourByThreeGridWorld) = DMIterator{FourByThreeGridWorldState}(1:4, 1:3)
DecisionMaking.𝒜(𝒫::FourByThreeGridWorld) = DMIterator{FourByThreeGridWorldAction}(1:4)
DecisionMaking.ℛ(𝒫::FourByThreeGridWorld) = DMIterator{FourByThreeGridWorldReward}(-1:1)

function DecisionMaking.initialstate(𝒫::FourByThreeGridWorld; s::DMNothingOrMissing=missing)
    state = FourByThreeGridWorldState(1, 1)
    return ismissing(s) ? DMDeterministicDistribution(state) : state
end

function DecisionMaking.T(𝒫::FourByThreeGridWorld, s::DMState, a::DMAction;
        s′::DMStateOrMissing=missing,
        agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
    )
    pr_s′_stay = 0.0
    pr_s′_forward = 𝒫.pr_forward
    pr_s′_rel_left = (1.0 - 𝒫.pr_forward) / 2.0
    pr_s′_rel_right = (1.0 - 𝒫.pr_forward) / 2.0

    s′_stay = (s[1], s[2])
    if a == UP
        s′_forward = (s[1], s[2] + 1)
        s′_rel_left = (s[1] - 1, s[2])
        s′_rel_right = (s[1] + 1, s[2])
    elseif a == DOWN
        s′_forward = (s[1], s[2] - 1)
        s′_rel_left = (s[1] + 1, s[2])
        s′_rel_right = (s[1] - 1, s[2])
    elseif a == LEFT
        s′_forward = (s[1] - 1, s[2])
        s′_rel_left = (s[1], s[2] - 1)
        s′_rel_right = (s[1], s[2] + 1)
    elseif a == RIGHT
        s′_forward = (s[1] + 1, s[2])
        s′_rel_left = (s[1], s[2] + 1)
        s′_rel_right = (s[1], s[2] - 1)
    else
        s′_forward = s′_stay
        s′_rel_left = s′_stay
        s′_rel_right = s′_stay
    end

    #println("STATE (stay): ", s′_stay[1], " ", s′_stay[2], " with probability ", pr_s′_stay)
    #println("FORWARD: ", s′_forward[1], " ", s′_forward[2], " with probability ", pr_s′_forward)
    #println("LEFT: ", s′_rel_left[1], " ", s′_rel_left[2], " with probability ", pr_s′_rel_left)
    #println("RIGHT: ", s′_rel_right[1], " ", s′_rel_right[2], " with probability ", pr_s′_rel_right)

    # Special: If the agent goes out of bounds or tries to enter an obstacle, then collide with it.
    isoutofbounds(x, y) = x < 1 || y < 1 || x > 4 || y > 3
    if isoutofbounds(s′_forward[1], s′_forward[2]) || (s′_forward[1] == 2 && s′_forward[2] == 2)
        pr_s′_stay += pr_s′_forward
        pr_s′_forward = 0.0
    end
    if isoutofbounds(s′_rel_left[1], s′_rel_left[2]) || (s′_rel_left[1] == 2 && s′_rel_left[2] == 2)
        pr_s′_stay += pr_s′_rel_left
        pr_s′_rel_left = 0.0
    end
    if isoutofbounds(s′_rel_right[1], s′_rel_right[2]) || (s′_rel_right[1] == 2 && s′_rel_right[2] == 2)
        pr_s′_stay += pr_s′_rel_right
        pr_s′_rel_right = 0.0
    end

    ad(rng::AbstractRNG) = begin
        target = rand(rng)
        if target ≤ pr_s′_stay
            return FourByThreeGridWorldState(s′_stay)
        elseif target ≤ pr_s′_stay + pr_s′_forward
            return FourByThreeGridWorldState(s′_forward)
        elseif target ≤ pr_s′_stay + pr_s′_forward + pr_s′_rel_left
            return FourByThreeGridWorldState(s′_rel_left)
        else
            return FourByThreeGridWorldState(s′_rel_right)
        end
    end

    if ismissing(s′)
        𝒮′ = [FourByThreeGridWorldState(s′_stay)]
        if pr_s′_forward > 0.0
            push!(𝒮′, FourByThreeGridWorldState(s′_forward))
        end
        if pr_s′_rel_left > 0.0
            push!(𝒮′, FourByThreeGridWorldState(s′_rel_left))
        end
        if pr_s′_rel_right > 0.0
            push!(𝒮′, FourByThreeGridWorldState(s′_rel_right))
        end
        return DMImplicitDistribution(𝒮′, ad)
    else
        if s′[1] == s′_stay[1] && s′[2] == s′_stay[2]
            return pr_s′_stay
        elseif s′[1] == s′_forward[1] && s′[2] == s′_forward[2]
            return pr_s′_forward
        elseif s′[1] == s′_rel_left[1] && s′[2] == s′_rel_left[2]
            return pr_s′_rel_left
        elseif s′[1] == s′_rel_right[1] && s′[2] == s′_rel_right[2]
            return pr_s′_rel_right
        else
            return 0.0
        end
    end
end

function DecisionMaking.R(𝒫::FourByThreeGridWorld, s::DMState, a::DMAction;
        r::DMNothingOrMissing=missing,
        agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
    )
    if s[1] == 4 && s[2] == 3
        reward = FourByThreeGridWorldReward(1.0)
    elseif s[1] == 4 && s[2] == 2
        reward = FourByThreeGridWorldReward(-1.0)
    else
        reward = FourByThreeGridWorldReward(0.0)
    end

    return ismissing(r) ? DMDeterministicDistribution(reward) : reward
end

DecisionMaking.iscountablyinfinite(𝒫::FourByThreeGridWorld, T::Type{<:DMState};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false
DecisionMaking.iscountablyinfinite(𝒫::FourByThreeGridWorld, T::Type{<:DMReward};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false

DecisionMaking.iscontinuous(𝒫::FourByThreeGridWorld, T::Type{<:DMState};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false
DecisionMaking.iscontinuous(𝒫::FourByThreeGridWorld, T::Type{<:DMReward};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false

DecisionMaking.isdeterministic(𝒫::FourByThreeGridWorld, T::Type{<:DMState};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false
DecisionMaking.isdeterministic(𝒫::FourByThreeGridWorld, T::Type{<:DMReward};
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = true

DecisionMaking.order(𝒫::FourByThreeGridWorld, T::Type{<:DMState}) = DMIterator{Tuple{DMIndex, DMIndex}}(1:1, 1:2)
DecisionMaking.order(𝒫::FourByThreeGridWorld, T::Type{<:DMReward}) = DMIterator{Tuple{DMIndex, DMIndex}}(1:1, 1:1)

DecisionMaking.isterminal(𝒫::FourByThreeGridWorld, s::DMState)::Bool = false

DecisionMaking.ismonotonic(𝒫::FourByThreeGridWorld;
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false

DecisionMaking.hasbelief(𝒫::FourByThreeGridWorld;
    agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
)::Bool = false

DecisionMaking.discountfactor(𝒫::FourByThreeGridWorld, 𝒥::DMFiniteHorizonObjective) = 1.0
DecisionMaking.horizon(𝒫::FourByThreeGridWorld, 𝒥::DMFiniteHorizonObjective) = 100
DecisionMaking.discountfactor(𝒫::FourByThreeGridWorld, 𝒥::DMInfiniteHorizonObjective) = 0.95
DecisionMaking.horizon(𝒫::FourByThreeGridWorld, 𝒥::DMInfiniteHorizonObjective) = Inf
