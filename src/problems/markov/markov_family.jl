
"""
    ```
    _markov_structure(
        N::Type{<:Multiagency},
        Z::Type{<:Observability},
        C::Type{<:Centralization},
        M::Type{<:MemoryPresence},
        R::Type{<:RewardConditioning})
    ```

Build the decision network for a Markov problem with the given traits.

This is only used to define the Markov family. Prefer `structure(ProblemName)`.
""" 

struct MarkovTraits
    N::Tuple{Vararg{Multiagency}}
    Z::Tuple{Vararg{Observability}}
    C::Tuple{Vararg{Centralization}}
    M::Tuple{Vararg{MemoryPresence}}
    R::Tuple{Vararg{RewardConditioning}}
    
    function MarkovTraits(N, Z, C, M, R)
        new(Tuple(N), Tuple(Z), Tuple(C), Tuple(M), Tuple(R))
    end
end

struct MarkovConcreteTraits
    N::Multiagency
    Z::Observability
    C::Centralization
    M::MemoryPresence
    R::RewardConditioning
end

function markov_structure(traits::MarkovConcreteTraits)
    nodes = Pair[]
    push!(nodes, _mkv_stt(traits.N)...)
    push!(nodes, _mkv_act(traits.N, traits.Z, traits.C, traits.M)...)
    push!(nodes, _mkv_rwd(traits.N, traits.R)...)
    push!(nodes, _mkv_obs(traits.Z, traits.C)...)
    push!(nodes, _mkv_mem(traits.M, traits.Z, traits.C)...)
    NamedTuple(nodes)
end

function markov_dynamism(traits::MarkovConcreteTraits)
    (traits.M isa MemoryPresent) ? (; s=:sp, m=:mp) : (; s=:sp)
end

function markov_type(t::MarkovConcreteTraits)
    structure = markov_structure(t)
    dynamism = markov_dynamism(t)
    DecisionNetwork{DecisionGraph{structure, dynamism}}
end

function markov_type(t::MarkovTraits)
    possible_types = map(Iterators.product(t.N, t.Z, t.C, t.M, t.R)) do (N, Z, C, M, R)
        markov_type(MarkovConcreteTraits(N, Z, C, M, R))
    end
    Union{possible_types...}
end

function markov_concretize_traits(traits::MarkovTraits, behavior)
    M = (:mp ∈ behavior) ? MemoryPresent() : MemoryAbsent()
    R = (:r  ∈ behavior) ? RewardConditioning{conditions(behavior[:r])}() : NoReward()
    Z = (:o  ∈ behavior) ? PartiallyObservable() : FullyObservable()

    N = if :a ∈ behavior
        length(traits.N)==1 || throw(ArgumentError("Cannot infer multiagency of problem"))
        traits.N[1]
    else NoAgent()
    end

    length(traits.C)==1 || throw(ArgumentError("Cannot infer centralization of problem"))
    C = traits.C[1]

    MarkovConcreteTraits(N, Z, C, M, R)
end

function markov_check_type(ta::MarkovTraits, td::MarkovConcreteTraits)
    for field in fieldnames(MarkovTraits)
        if getproperty(td, field) ∉ getproperty(ta, field)
            throw(ArgumentError(
                "Implied network trait $(getproperty(td, field)) is not among the possible \
                options $(getproperty(ta, field))."))
        end
    end
end

macro markov_alias(name, abstract_traits)
    quote
        const $name = Decisions.markov_type($abstract_traits)

        function $name(; kwargs...)
            behavior = NamedTuple(kwargs)
            concrete_traits = Decisions.markov_concretize_traits($abstract_traits, behavior)
            Decisions.markov_check_type($abstract_traits, concrete_traits)
            Decisions.markov_type(concrete_traits)(behavior)
        end
    end |> esc
end


"""
    mkv_rwd(::Multiagency, ::RewardConditioning)
"""
const NotCompetitive = Union{NoAgent, SingleAgent, Cooperative} 
_mkv_rwd(_, ::NoReward) = []
_mkv_rwd(::NotCompetitive, ::ConditionedOn{nodes}) where nodes = [:r => nodes]
_mkv_rwd(::Competitive, ::ConditionedOn{nodes}) where nodes = [:(r[i]) => nodes]


"""
    mkv_act(::Multiagency, ::Observability, ::Centralization, ::MemoryPresence)
"""
_mkv_act(::NoAgent,_, _, _) = []
_mkv_act(::SingleAgent,::FullyObservable,    _,::MemoryAbsent)  = [:a => (:s,)]
_mkv_act(::SingleAgent,::FullyObservable,    _,::MemoryPresent) = [:a => (:s, :m,)]
_mkv_act(::SingleAgent,::PartiallyObservable,_,::MemoryAbsent)  = [:a => (:o,)]
_mkv_act(::SingleAgent,::PartiallyObservable,_,::MemoryPresent) = [:a => (:o, :m)]

_mkv_act(::MultiAgent,::FullyObservable,    _,              ::MemoryAbsent)  = [:(a[i]) => (:s,)]
_mkv_act(::MultiAgent,::FullyObservable,    ::Centralized,  ::MemoryPresent) = [:(a[i]) => (:s, :m,)]
_mkv_act(::MultiAgent,::FullyObservable,    ::Decentralized,::MemoryPresent) = [:(a[i]) => (:s, :(m[i]),)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryAbsent)  = [:(a[i]) => (:o,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryPresent) = [:(a[i]) => (:o, :m,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryAbsent)  = [:(a[i]) => (:(o[i]),)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryPresent) = [:(a[i]) => (:(o[i]), :(m[i]),)]


# Only three options for observation, depending on centralization (and whether there
#   are observations at all).
"""
    mkv_obs(::Observability, ::Centralization)
"""
_mkv_obs(::FullyObservable, _) = []
_mkv_obs(::PartiallyObservable, _)               = [:o       => (:s,)]
_mkv_obs(::PartiallyObservable, ::Decentralized) = [:(o[i])  => (:s,)]


# There are five possible memory configurations:
#   Either fully or partially observable (determines whether state or obs is added),
#   and either centralized or decentralized (determines how many memories there are),
#   and one degenerate case where memory is absent entirely.
"""
    mkv_mem(::MemoryPresence, ::Observability, ::Centralization)
"""
_mkv_mem(::MemoryAbsent, _, _) = []
_mkv_mem(::MemoryPresent,::PartiallyObservable,::Centralized)   = [:mp => (:m, :o, :a)]
_mkv_mem(::MemoryPresent,::FullyObservable,    ::Centralized)   = [:mp => (:m, :s, :a)]
_mkv_mem(::MemoryPresent,::PartiallyObservable,::Decentralized) = [:(mp[i]) => (:(m[i]), :(o[i]), :(a[i]))]
_mkv_mem(::MemoryPresent,::FullyObservable,    ::Decentralized) = [:(mp[i]) => (:(m[i]), :s, :(a[i]))]


# Finally, the state node is always present. It only cares about the number of actions.
"""
    mkv_stt(::Multiagency)
"""
function _mkv_stt(::Multiagency) end
_mkv_stt(::NoAgent)     = [:sp => (:s,)]
_mkv_stt(::SingleAgent) = [:sp => (:s, :a)]
_mkv_stt(::MultiAgent)  = [:sp => (:s, :(a[i]))]