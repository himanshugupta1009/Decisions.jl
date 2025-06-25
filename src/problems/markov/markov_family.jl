
"""
    MarkovProblem

Abstract base class for all problems in the "Markov family" (or "Wray class").

The Markov family is a set of dynamic decision networks.
It includes Markov chains at its simplest
(which involve no decisions at all), to arbitrary compositions of components like 
"[lexicographic] [partially observable] [semi-]Markov [games]" at its most complex. In 
between are beloved models like POMDPs and
Markov games.
"""
struct MarkovProblem{
    N <: Multiagency,
    Z <: Observability,
    C <: Centralization,
    M <: MemoryPresence,
    R <: RewardConditioning,
    # T <: TimestepStyle,
    # G <: ConstraintStyle
} <: DecisionProblem 
    impl::NamedTuple
end

# function MarkovProblem{N,Z,C,M,R}(args...) where {N,Z,C,M,R}
#     dn = structure(Type{MarkovProblem{N,Z,C,M,R}})
#     nodes = keys(dn.graph)
#     order = 
# end

# TODO: Write generic functions but not macros) for case where M / R are unknown

macro def_markov(name, traits...)
    mem_presence_defined = (traits[4] == :Any)
    reward_cond_defined  = (traits[5] == :Any)

    multiagency         = traits[1]
    observability       = traits[2]
    centralization      = traits[3]
    memory_presence     = (mem_presence_defined ? :M : traits[4])
    reward_conditioning = (reward_cond_defined  ? :R : traits[5])

    type_attrs = [
        ((traits[4] == :Any) ? :M : [])
        ((traits[5] == :Any) ? :R : [])
    ]

    # hack; brittle to changes in trait names
    required_nodes = Symbol[
        :sp
        (observability == :FullyObservable) ? [] : :o
        (reward_conditioning == :NoReward) ? [] : :r
    ]

    nodename_map = (; 
        sp = :transition,
        o = :observation,
        r = :reward
    )
    required_names = values(nodename_map[required_nodes])
    required_nodes_doublequote = Tuple(required_nodes) # what have we done
    required_names_expr = Expr(:tuple, required_names...)

    type_attrs_assumed = if (:M in type_attrs) && (:R in type_attrs)
        (:(_default_mem()), :(_default_rc(reward)))
    elseif (:M in type_attrs) && ! (:R in type_attrs)
        (:(_default_mem()),)
    elseif ! (:M in type_attrs) && (:R in type_attrs)
        (:(_default_rc(reward)),)
    else
        ()
    end

    quote
        $(esc(name)){$(type_attrs...)} = MarkovProblem{
            $multiagency,
            $observability,
            $centralization,
            $memory_presence,
            $reward_conditioning
        }
            # function $(esc(name)){$(type_attrs...)}($(required_names...)) where {$(type_attrs...)}
            #     impl = NamedTuple{$required_nodes_doublequote}($required_names_expr)
            #     $(esc(name)){$(type_attrs...)}(impl)
            # end

        function $(esc(name))($(required_names...))
            impl = NamedTuple{$required_nodes_doublequote}($required_names_expr)
            $(esc(name)){$(type_attrs_assumed...)}(impl)
        end
    end
end

# Wow! That's a lot of information we're storing in the type. Is that a good idea?
# https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-value-type
# The manual gives the following reasonable situation to do this (for Car{Make, Model}):
#   "You require CPU-intensive processing on each Car, and it becomes vastly more 
#   efficient if you know the Make and Model at compile time and the total number of 
#   different Make or Model that will be used is not too large."
# I think this is true here. If we know all of these traits at compile time, we can very
#   effectively compile methods like `sample` and `structure` in a way that almost
#   completely removes the overarching DN and operations on it from runtime.  


# There are a lot of hints / traits we can define about problems. The ones I've written
#   down so far happen to be good for defining the Markov family, so we use them as type
#   parameters. But they're really intended to be Holy traits.
#   I like to use the constructor for the superclass as my trait function
#   for this design pattern, but that's not strictly necessary.
Multiagency(::MarkovProblem{N,Z,C,M,R}) where {N,Z,C,M,R} = N()
Observability(::MarkovProblem{N,Z,C,M,R}) where {N,Z,C,M,R} = Z()
Centralization(::MarkovProblem{N,Z,C,M,R}) where {N,Z,C,M,R} = C()
MemoryPresence(::MarkovProblem{N,Z,C,M,R}) where {N,Z,C,M,R} = M()
RewardConditioning(::MarkovProblem{N,Z,C,M,R}) where {N,Z,C,M,R} = R()

# But not all problem traits are required to define a Markov family problem.
#   (Of course not; there are infinitely many possible ones.)
#   We can provide hints for the other traits in a more ordinary manner.
Sequentiality(::MarkovProblem) = Simultaneous()

function structure(::Type{<: MarkovProblem{N,Z,C,M,R}}) where {N,Z,C,M,R}

    # TODO: All of these add either one or zero nodes; push! is the wrong way to go
    nodes = Pair[]
    push!(nodes, mkv_stt(N())...)
    push!(nodes, mkv_act(N(), Z(), C(), M())...)
    push!(nodes, mkv_rwd(N(), R())...)
    push!(nodes, mkv_obs(Z(), C())...)
    push!(nodes, mkv_mem(M(), Z(), C())...)
    graph = NamedTuple(nodes)

    DecisionNetwork(forward_mapping(M()); graph...)
end

forward_mapping(::MemoryPresent) = (; m = :mp, s = :sp)
forward_mapping(::MemoryAbsent) = (; s = :sp)


function behavior(p::MarkovProblem) 
    # TODO: Doesn't work with plates, obv
    # TODO: This is technically inefficient; O(n) for n nodes. There's probably a NamedTuple
    #   way of dealing with this.
    (;
        sp = p.transition,
        o  = p.observation,
        r = p.reward
    )
end

function nodes_for(p::Type{MarkovProblem{N,Z,C,M,R}}) where {N,Z,C,M,R}

end


# The idea here is to dispatch on traits to build up the DN. That way, any named problem
#   can just be defined in terms of its traits. 
# TODO: I wonder if there's a principled ordering to traits in these builder functions.

# There are a total of thirteen ways reward nodes can look. Gross!
#   There are five possible conditionings: S, SA, SAS, M, MA. The latter two allow us
#   to have, e.g., rho-POMDPs. Thanks to Jackson and Qi Heng for pointing that out to me.
# We can have a single reward node (cooperative) or "many" (competitive) for another factor
#   of two. We assume that everyone's action and memory can be part of the reward in the
#   former case, and that everyone's action but _only_ my memory can be part of the reward
#   in the second case.
#   (TODO - that is an assumption. There is potential for much weirder sorta-rho models.)
# If there's no agent at all, there's a semi-degenerate case: conditioning on actions is
#   impossible, but state and memory is OK. (So we can have a rho-MRP???)
# Finally, there's a degenerate case where there are no rewards at all, like in a MC.
"""
    function mkv_rwd(::Multiagency, ::RewardConditioning) end
"""
const SingleOrCoop = Union{SingleAgent, Cooperative} # convenience; union is long to write
mkv_rwd(_, ::NoReward) = []
mkv_rwd(::NoAgent, ::SConditioned)   = [:r => (:s,)]
mkv_rwd(::NoAgent, ::MConditioned)   = [:r => (:m,)]

mkv_rwd(::SingleOrCoop, ::SConditioned)   = [:r => (:s,)]
mkv_rwd(::SingleOrCoop, ::SAConditioned)  = [:r => (:s, :a)]
mkv_rwd(::SingleOrCoop, ::SASConditioned) = [:r => (:s, :a, :sp)]
mkv_rwd(::SingleOrCoop, ::MConditioned)   = [:r => (:mp)]
mkv_rwd(::SingleOrCoop, ::MAConditioned)  = [:r => (:mp, :a)]

mkv_rwd(::Competitive, ::SConditioned)    = [:(r[i]) => (:s,)]
mkv_rwd(::Competitive, ::SAConditioned)   = [:(r[i]) => (:s, :a)]
mkv_rwd(::Competitive, ::SASConditioned)  = [:(r[i]) => (:s, :a, :sp)]
mkv_rwd(::Competitive, ::MConditioned)    = [:(r[i]) => (:(mp[i]))]
mkv_rwd(::Competitive, ::MAConditioned)   = [:(r[i]) => (:(mp[i]), :(a[i]))]



# There are seven possible sets of conditioning variables for the action nodes
#   in the multiagent case for the Markov family
#   You'd think there would be 2^3: two options each for the relevant traits of
#   observability, centralization, and memory presence. But since the state isn't
#   factored by player, a decentralized and centralized fully observable MDP turn
#   out to be the same, if there's no memory (which _can_ be factored by player.)
# There are another three for single agent, with similar rationale, and 
#   one more for the degenerate case where there are no agents at all.

"""
    function mkv_act(::Multiagency, ::Observability, ::Centralization, ::MemoryPresence) end
"""
mkv_act(::NoAgent,_, _, _) = []
mkv_act(::SingleAgent,::FullyObservable,    _,  ::MemoryAbsent)  = [:a      => (:s,)]
mkv_act(::SingleAgent,_,                    _,  ::MemoryPresent) = [:a      => (:mp,)]
mkv_act(::SingleAgent,::PartiallyObservable,_,  ::MemoryAbsent)  = [:a      => (:o,)]

mkv_act(::MultiAgent,::FullyObservable,    _,              ::MemoryAbsent)  = [:(a[i]) => (:s,)]
mkv_act(::MultiAgent,::FullyObservable,    ::Centralized,  ::MemoryPresent) = [:(a[i]) => (:mp,)]
mkv_act(::MultiAgent,::FullyObservable,    ::Decentralized,::MemoryPresent) = [:(a[i]) => (:(mp[i]),)]
mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryAbsent)  = [:(a[i]) => (:o,)]
mkv_act(::MultiAgent,::PartiallyObservable,::Centralized,  ::MemoryPresent) = [:(a[i]) => (:mp,)]
mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryAbsent)  = [:(a[i]) => (:(o[i]),)]
mkv_act(::MultiAgent,::PartiallyObservable,::Decentralized,::MemoryPresent) = [:(a[i]) => (:(mp[i]),)]


# Only three options for observation, depending on centralization (and whether there
#   are observations at all).
"""
    function mkv_obs(::Observability, ::Centralization) end
"""
mkv_obs(::FullyObservable, _) = []
mkv_obs(::PartiallyObservable, _)               = [:o       => (:s,)]
mkv_obs(::PartiallyObservable, ::Decentralized) = [:(o[i])  => (:s,)]


# There are five possible memory configurations:
#   Either fully or partially observable (determines whether state or obs is added),
#   and either centralized or decentralized (determines how many memories there are),
#   and one degenerate case where memory is absent entirely.
"""
    function mkv_mem(::MemoryPresence, ::Observability, ::Centralization) end
"""
mkv_mem(::MemoryAbsent, _, _) = []
mkv_mem(::MemoryPresent,::PartiallyObservable,::Centralized)   = [:mp => (:m, :o, :a)]
mkv_mem(::MemoryPresent,::FullyObservable,    ::Centralized)   = [:mp => (:m, :s, :a)]
mkv_mem(::MemoryPresent,::PartiallyObservable,::Decentralized) = [:(mp[i]) => (:(m[i]), :o, :(a[i]))]
mkv_mem(::MemoryPresent,::FullyObservable,    ::Decentralized) = [:(mp[i]) => (:(m[i]), :s, :(a[i]))]


# Finally, the state node is always present. It only cares about the number of actions.
function mkv_stt(::Multiagency) end
mkv_stt(::NoAgent)     = [:sp => (:s,)]
mkv_stt(::SingleAgent) = [:sp => (:s, :a)]
mkv_stt(::MultiAgent)  = [:sp => (:s, :(a[i]))]


# TODO: Constraints / lexico / slack and sojourn not yet implemented. Should be pretty
#   straightforward along the lines of the other nodes.

"""
    _default_rc(fn; consider_mem=false)

Gives the default reward conditioning for a Markov family problem based on the reward
function.

If the reward function is has a method for one, two, or three parameters, we assume it
is conditioned on (s,), (s, a), or (s, a, s′) respectively, assuming the reward function is
not intended to be conditioned on memory. If the reward function _is_ intended to be
conditioned on memory (denoted with `consider_mem=true`), we assume it is conditioned on
(m,) or (m, a) if it has one or two arguments respectively.
"""
function _default_rc(fn; consider_mem=false)
    if ! consider_mem
        if hasmethod(fn, (Any, Any, Any))
            SASConditioned
        elseif hasmethod(fn, (Any, Any))
            SAConditioned
        else
            SConditioned
        end
    else
        if hasmethod(fn, (Any, Any))
            MAConditioned
        else
            MConditioned
        end
    end
end
"""
    _default_rc()

Gives the default memory presence for a Markov family problem.

We assume the memory node is present when allowed, so the agent to persist information 
between steps. If a truly memoryless approach is desired, the `MemoryAbsent` trait can
be used as a type parameter. 
"""
function _default_mem()
    MemoryPresent
end