
abstract type DecisionAgent end

"""
    DecisionAgent

Abstract base type for decision agents: mappings from interactions with an environment to
conditional distributions defining a behavior in that environment.

Only "true constants" are permissible fields of subtypes. Information that can change during
the optimization process (including parameters and hyperparameters) cannot be stored here.
"""
function DecisionAgent end

"""
    behavior(da::DecisionAgent, params=nothing)
    behavior(das::Tuple{Vararg{<:DecisionAgent}}, params=nothing; idx_var=:i)

Give a NamedTuple mapping decision nodes in `dn` to conditional distributions, possibly
based on some parameters `params`. 

If a `Tuple` of agents is provided, merges behavior for each node across agents that give
behavior for that node (producing a `CompoundDist` over `idx_var`).

`params` are maintained by `update_parameters(...)`.
"""
function behavior end

function behavior(das::Tuple{Vararg{<:DecisionAgent}}, params=nothing; idx_var=:i)
    # TODO: This feels really inefficient and unparallelized. We only do it once per
    #   policy iteration, but still. It's bad.
    if length(das) == 1
        return behavior(das[1], isnothing(params) ? nothing : params[1])
    end
    bhvs = if isnothing(params)
        [behavior(da) for da in das]
    else
        [behavior(das[i], params[i]) for i in eachindex(das)]
    end
    all_rvs = union(keys.(bhvs)...)

    pairs = map(all_rvs) do k
        relevant_bhvs = [bhv for bhv in bhvs if k in keys(bhv)]
        k => CompoundDist([bhv[k] for bhv in relevant_bhvs]...; idx=idx_var)
    end
    NamedTuple(pairs)
end

"""
    init_parameters(da::DecisionAgent, hparams=nothing)

Initialize agent parameters, possibly based on hyperparameters `hparams`, returning them.

By default there are no parameters, and this returns `nothing`.
"""
init_parameters(da::DecisionAgent, hparams=nothing) = nothing

"""
    update_parameters(da::DecisionAgent, params, data, hparams=nothing)

Update agent parameters `params` based on `data` gathered from environment interactions and
optional hyperparameters `hparams`, returning them.

By default there are no parameters, and this returns `nothing`.
"""
update_parameters(da::DecisionAgent, params, data, hparams=nothing) = nothing

"""
    update_parameters!(da::DecisionAgent, params, data, hparams=nothing)

Update agent parameters `params` in place if possible, based on `data` gathered from
environment interactions and optional hyperparameters `hparams`, and return them.

By default assumes in-place update is impossible and defers to `update_parameters` (without
the bang).
"""
function update_parameters!(da::DecisionAgent, params, data, hparams=nothing)
    update_parameters(da, params, data, hparams)
end

"""
    init_hyperparameters(da::DecisionAgent)

Initialize agent hyperparameters, returning them.

By default there are no hyperparameters, and this returns `nothing`.
"""
init_hyperparameters(da::DecisionAgent) = nothing

"""
    update_hyperparameters(da::DecisionAgent, hparams, data)

Update agent hyperparameters `hparams` based on `data` gathered from environment
interactions, returning them.

By default there are no hyperparameters, and this returns `nothing`.
"""
update_hyperparameters(da::DecisionAgent, hparams, data) = nothing

"""
    update_hyperparameters!(da::DecisionAgent, hparams, data)

Update agent hyperparameters `hparams` in place if possible based on `data` gathered from
environment interactions, returning them.

By default assumes in-place update is impossible and defers to `update_hyperparameters`
(without the bang).
"""
function update_hyperparameters!(da::DecisionAgent, hparams, data)
    update_hyperparameters(da, hparams, data)
end


"""
    ProtoDecisionAgent

Abstract base class for prototype decision agents - a convenience to avoid the fully formal
`DecisionAgent` definition at the cost of some guarantees.

ProtoDecisionAgents need only implement `solve!` (and presumably a constructor). The output
of solve! is memoized for the entire lifespan of the agent, never to be updated based on
environment data (unless an accurate environment is a field of the agent used in `solve!`).
"""
abstract type ProtoDecisionAgent <: DecisionAgent end

# This is intentionally contract-breaking: @memoize is stateful. 
@memoize function behavior(da::DecisionAgent)
    solve!(da)
end

"""
    solve!(da::ProtoDecisionAgent)

Provide decision node behavior based only on data in `da`.

Often `da` contains an environment or environment model, which may or may not be the
actual one in which it is to be evaluated. No restrictions are placed on `solve!` with
respect to environment; if an accurate environment is available, `da` can interact with it
in any way, and if it is not, `dn` cannot gain environment data from the true environment. 
"""
function solve! end


struct RandomAgent <: DecisionAgent
    support
end

function behavior(a::RandomAgent, params=nothing)
    (; a=UniformDist(a.support))
end