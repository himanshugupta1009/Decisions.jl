
@with_kw struct ValueIteration <: DecisionAlgorithm
    max_iterations::Int = 100
end

# There is no update_hyperparameters!(...).

function ValueIteration(prob::DecisionNetwork)
    reward_space = support(prob[:r])
    state_space = support(prob[:sp])

    # Finite and discrete only
    states = [s for s in state_space]

    discountfactor = 0.1

    V = zeros(eltype(reward_space), length(states))
    random_action_dist = UniformDist(support(prob[:a]))
    π = [random_action_dist() for s in state_space]

    for _ in 1:1000
        for s in state_space
            Vs_best = zero(reward_space)
            a_best = random_action_dist()

            for a in 𝒜(Π.𝒫)
                Vs = zero(reward_space)
                for sp in support(prob[:sp])
                    Vs += prob[:r](; s, a, sp)
                    Vs += discountfactor * prob[:sp](sp; s, a) * V[sp]
                end

                if Vs_best < Vs
                    Vs_best, a_best = Vs, a
                end
            end

            # Actually update / store Vs
        end
    end

end


function update_parameters(agent::DecisionAgent, behavior::ConditionalDist)

end

function behavior(::DecisionNetwork, ::DecisionAgent) end

function DecisionMaking.initialvars!(Π::VI)

    r₀ = similar(first(ℛ(Π.𝒫)))
    for s in 𝒮(Π.𝒫)
        Π.vars.V[s] = similar(r₀)
        Π.vars.π[s] = rand(Π.rng, 𝒜(Π.𝒫))
    end

    V(s) = begin
        try return isterminal(Π.𝒫, s) ? similar(r₀) : Π.vars.V[s]
        catch e return Π.vars.V[s] end
    end

    # NOTE: If there happen to be multiple agents and/or multiple factors,
    # then this VI code below employs a Bellman operator for which its
    # "max_a" operator requires a strict maximum over all agents and/or
    # factors. Ties are broken by randomly (implicitly in code).

    for i in 1:Π.hparams.max_iterations
        for s in 𝒮(Π.𝒫)
            Vs_best, a_best = similar(r₀; value=-Inf), rand(Π.rng, 𝒜(Π.𝒫))

            for a in 𝒜(Π.𝒫)
                Vs = similar(r₀)
                Td = T(Π.𝒫, s, a)
                for s′ in support(Td)
                    Vs += R(Π.𝒫, s, a, s′; r=nothing)
                    Vs += discountfactor(Π.𝒫, Π.𝒥) * T(Π.𝒫, s, a; s′=s′) * V(s′)
                end

                if Vs_best < Vs
                    Vs_best, a_best = Vs, a
                end
            end

            Π.vars.V[s], Π.vars.π[s] = Vs_best, a_best
        end
    end
end


# =====

@with_kw mutable struct VIHyperparameters <: DMAlgorithmHyperparameters
    max_iterations::Int = 100
end

mutable struct VIVariables <: DMAlgorithmVariables
    V::Dict{DMState, DMReward}
    π::Dict{DMState, DMAction}

    VIVariables(𝒫::DMProblem) = new(
        Dict(s => similar(first(ℛ(𝒫))) for s in 𝒮(𝒫)),
        Dict(s => first(𝒜(𝒫)) for s in 𝒮(𝒫)),
    )
end

struct VI <: DMAlgorithm
    hparams::VIHyperparameters
    vars::VIVariables

    𝒫::DMProblem
    𝒥::DMObjective
    rng::AbstractRNG

    VI(𝒫::DMProblem;
        𝒥::DMObjective=DMInfiniteHorizonObjective(),
        rng::AbstractRNG=Xoshiro(),
        max_iterations::Int=1,
    ) = new(VIHyperparameters(max_iterations), VIVariables(𝒫), 𝒫, 𝒥, rng)
end

DecisionMaking.ℋ(Π::VI) = DMIterator{VIHyperparameters}(0:100:1000)

function DecisionMaking.initialvars!(Π::VI)
    r₀ = similar(first(ℛ(Π.𝒫)))
    for s in 𝒮(Π.𝒫)
        Π.vars.V[s] = similar(r₀)
        Π.vars.π[s] = rand(Π.rng, 𝒜(Π.𝒫))
    end

    V(s) = begin
        try return isterminal(Π.𝒫, s) ? similar(r₀) : Π.vars.V[s]
        catch e return Π.vars.V[s] end
    end

    # NOTE: If there happen to be multiple agents and/or multiple factors,
    # then this VI code below employs a Bellman operator for which its
    # "max_a" operator requires a strict maximum over all agents and/or
    # factors. Ties are broken by randomly (implicitly in code).

    for i in 1:Π.hparams.max_iterations
        for s in 𝒮(Π.𝒫)
            Vs_best, a_best = similar(r₀; value=-Inf), rand(Π.rng, 𝒜(Π.𝒫))

            for a in 𝒜(Π.𝒫)
                Vs = similar(r₀)
                Td = T(Π.𝒫, s, a)
                for s′ in support(Td)
                    Vs += R(Π.𝒫, s, a, s′; r=nothing)
                    Vs += discountfactor(Π.𝒫, Π.𝒥) * T(Π.𝒫, s, a; s′=s′) * V(s′)
                end

                if Vs_best < Vs
                    Vs_best, a_best = Vs, a
                end
            end

            Π.vars.V[s], Π.vars.π[s] = Vs_best, a_best
        end
    end
end

function DecisionMaking.ψ(Π::VI, s::DMState;
        a::DMActionOrMissing=missing,
        agent::DMIndexOrMissing=missing, factor::DMIndexOrMissing=missing,
    )
    return ismissing(a) ? DMDeterministicDistribution(Π.vars.π[s]) : 1.0 * (Π.vars.π[s] == a)
end

DecisionMaking.iscountablyinfinite(Π::VI, t::Type{<:DMAction})::Bool = false
DecisionMaking.iscontinuous(Π::VI, t::Type{<:DMAction})::Bool = false
DecisionMaking.isdeterministic(Π::VI, t::Type{<:DMAction})::Bool = true

#DecisionMaking.order(Π::VI, T::Type{<:DMAction}) # Use Default. It works well automatically.
