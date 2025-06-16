
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
abstract type MarkovProblem{
    N <: Multiagency,
    Z <: Observability,
    C <: Centralization,
    M <: MemoryPresence,
    R <: RewardConditioning,
    # T <: TimestepStyle,
    # G <: ConstraintStyle
} <: DecisionProblem end

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


function structure(::Type{MarkovProblem{N,Z,C,M,R}}) where {N,Z,C,M,R}

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
mkv_rwd(::SingleOrCoop, ::SASConditioned) = [:r => (:s, :a, :s)]
mkv_rwd(::SingleOrCoop, ::MConditioned)   = [:r => (:mp)]
mkv_rwd(::SingleOrCoop, ::MAConditioned)  = [:r => (:mp, :a)]

mkv_rwd(::Competitive, ::SConditioned)    = [:(r[i]) => (:s,)]
mkv_rwd(::Competitive, ::SAConditioned)   = [:(r[i]) => (:s, :a)]
mkv_rwd(::Competitive, ::SASConditioned)  = [:(r[i]) => (:s, :a, :s)]
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



function behavior(p::MarkovProblem, idx) 
    # TODO: Doesn't work with plates, obv
    # TODO: This is technically inefficient; O(n) for n nodes. There's probably a NamedTuple
    #   way of dealing with this.
    if idx == :sp
        return p.transition
    elseif idx == :o
        return p.observation
    elseif idx == :r
        return p.reward
    end
end

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

function _default_mem()
    MemoryPresent
end
