struct MarkovTraits
    N::Tuple{Vararg{Multiagency}}
    Z::Tuple{Vararg{Observability}}
    C::Tuple{Vararg{Centralization}}
    M::Tuple{Vararg{MemoryPresence}}
    R::Tuple{Vararg{RewardConditioning}}
    H::Tuple{Vararg{Cooperation}}
    
    function MarkovTraits(N, Z, C, M, R, H)
        new(Tuple(N), Tuple(Z), Tuple(C), Tuple(M), Tuple(R), Tuple(H))
    end
end

struct MarkovConcreteTraits
    N::Multiagency
    Z::Observability
    C::Centralization
    M::MemoryPresence
    R::RewardConditioning
    H::Cooperation
end

function markov_structure(traits::MarkovConcreteTraits)
    nodes = Pair[]
    push!(nodes, _mkv_stt(traits.N)...)
    push!(nodes, _mkv_act(traits.N, traits.Z, traits.C, traits.M)...)
    push!(nodes, _mkv_rwd(traits.H, traits.R)...)
    push!(nodes, _mkv_obs(traits.Z, traits.C)...)
    push!(nodes, _mkv_mem(traits.M, traits.Z, traits.C)...)
    NamedTuple(nodes)
end

function markov_dynamism(traits::MarkovConcreteTraits)
    (traits.M isa MemoryPresent) ? (; s=:sp, m=:mp) : (; s=:sp)
end

function markov_constituents(node_names)
    full_list = (;
        m_i  = (:m,  :i),
        mp_i = (:mp, :i),
        s_i  = (:s,  :i),
        sp_i = (:sp, :i),
        a_i  = (:a,  :i),
        o_i  = (:o,  :i),
        r_i  = (:r,  :i),
    )
    partial_keys = intersect(node_names, keys(full_list))
    NamedTuple{partial_keys}(full_list)
end

function markov_ranges(t::MarkovConcreteTraits, node_names)
    needs_i = [m_i; mp_i; s_i; sp_i; a_i; o_i; r_i]
    if ! isempty(intersect(node_names, needs_i))
        (; i = num_agents(t.N))
    else (;) end
end

function markov_type(t::MarkovConcreteTraits)
    structure = markov_structure(t)
    dynamism = markov_dynamism(t)
    constituents = markov_constituents(keys(structure))
    ranges = markov_ranges(t, keys(structure))
    DecisionNetwork{_get_dg_type(structure, dynamism, constituents, ranges)}
end

function markov_type(t::MarkovTraits)
    possible_types = map(Iterators.product(t.N, t.Z, t.C, t.M, t.R, t.H)) do (N, Z, C, M, R, H)
        tc = MarkovConcreteTraits(N, Z, C, M, R, H)
        structure = markov_structure(tc)
        dynamism = markov_dynamism(tc)
        graphtype = _get_dg_type(structure, dynamism)
        DecisionNetwork{graphtype} # never concrete; plates / constituents missing
    end
    Union{possible_types...}
end

function markov_concretize_traits(traits::MarkovTraits, behavior, ranges)
    M = (:mp ∈ keys(behavior)) ? MemoryPresent() : MemoryAbsent()
    R = (:r  ∈ keys(behavior)) ? ConditionedOn(conditions(behavior[:r])...) : NoReward()
    Z = (:o  ∈ keys(behavior)) ? PartiallyObservable() : FullyObservable()

    N = if :a_i ∈ keys(behavior)
        DefiniteAgents{ranges[:i]}()
    elseif :a ∈ keys(behavior)
        SingleAgent()
    else 
        NoAgent()
    end

    length(traits.C)==1 || throw(ArgumentError("Cannot infer centralization of problem"))
    C = traits.C[1]


    length(traits.H)==1 || throw(ArgumentError("Cannot infer cooperation of problem"))
    H = traits.H[1]

    MarkovConcreteTraits(N, Z, C, M, R, H)
end

function markov_check_type(ta::MarkovTraits, td::MarkovConcreteTraits)
    for field in fieldnames(MarkovTraits)
        if field == :N && IndefiniteAgents() ∈ ta.N && td.N isa MultiAgent
            continue # Special case; IndefiniteAgents is "concrete" but permits any N
        elseif getproperty(td, field) ∉ getproperty(ta, field)
            throw(ArgumentError(
                "Implied network trait $(getproperty(td, field)) is not among the possible \
                options $(getproperty(ta, field))."))
        end
    end
end

macro markov_alias(name, abstract_traits)
    quote
        const $name = Decisions.markov_type($abstract_traits)

        function $name(plates; kwargs...)
            behavior = NamedTuple(kwargs)
            concrete_traits = Decisions.markov_concretize_traits($abstract_traits, behavior, plates)
            Decisions.markov_check_type($abstract_traits, concrete_traits)
            Decisions.markov_type(concrete_traits)(behavior)
        end
    end |> esc
end


"""
    mkv_rwd(::Cooperation, ::RewardConditioning)
"""
_mkv_rwd(_, ::NoReward) = []
_mkv_rwd(::Cooperative, ::ConditionedOn{nodes}) where nodes = [:r => nodes]
_mkv_rwd(::Competitive, ::ConditionedOn{nodes}) where nodes = [:(r[i]) => nodes]


"""
    mkv_act(::Multiagency, ::Observability, ::Centralization, ::MemoryPresence)
"""
_mkv_act(::NoAgent,_, _, _) = []
_mkv_act(::SingleAgent,::FullyObservable,    _,::MemoryAbsent)  = [:a => (:s,)]
_mkv_act(::SingleAgent,::FullyObservable,    _,::MemoryPresent) = [:a => (:s, :m,)]
_mkv_act(::SingleAgent,::PartiallyObservable,_,::MemoryAbsent)  = [:a => (:o,)]
_mkv_act(::SingleAgent,::PartiallyObservable,_,::MemoryPresent) = [:a => (:o, :m)]

_mkv_act(::MultiAgent,::FullyObservable,    _,              ::MemoryAbsent)  = [:a_i => (:i, :s,)]
_mkv_act(::MultiAgent,::FullyObservable,    ::Centralized,  ::MemoryPresent) = [:a_i => (:i, :s, :m,)]
_mkv_act(::MultiAgent,::FullyObservable,    ::Decentralized,::MemoryPresent) = [:a_i => (:i, :s, :m_i,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryAbsent)  = [:a_i => (:i, :o,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryPresent) = [:a_i => (:i, :o, :m,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryAbsent)  = [:a_i => (:i, :o_i,)]
_mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryPresent) = [:a_i => (:i, :o_i, :m_i,)]


# Only three options for observation, depending on centralization (and whether there
#   are observations at all).
"""
    mkv_obs(::Observability, ::Centralization)
"""
_mkv_obs(::FullyObservable, _) = []
_mkv_obs(::PartiallyObservable, _)               = [:o       => (:s,)]
_mkv_obs(::PartiallyObservable, ::Decentralized) = [:o_i     => (:s,)]


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
_mkv_mem(::MemoryPresent,::PartiallyObservable,::Decentralized) = [:mp_i => (:i, :m_i, :o_i, :a_i)]
_mkv_mem(::MemoryPresent,::FullyObservable,    ::Decentralized) = [:mp_i => (:i, :m_i, :s, :a_i)]


# Finally, the state node is always present. It only cares about the number of actions.
"""
    mkv_stt(::Multiagency)
"""
function _mkv_stt(::Multiagency) end
_mkv_stt(::NoAgent)     = [:sp => (:s,)]
_mkv_stt(::SingleAgent) = [:sp => (:s, :a)]
_mkv_stt(::MultiAgent)  = [:sp => (:s, :a_i)]