
abstract type DecisionsTrait end



# multiagency         ::Tuple{Vararg{Multiagency}}
# observability       ::Tuple{Vararg{Observability}}
# centralization      ::Tuple{Vararg{Centralization}}
# memory_presence     ::Tuple{Vararg{MemoryPresence}}
# reward_style        ::Tuple{Vararg{RewardStyle}}
# cooperation         ::Tuple{Vararg{Cooperation}}
# agent_correlation   ::Tuple{Vararg{AgentCorrelation}}
# timestep_style      ::Tuple{Vararg{FixedTimestep}}


# For convenience
Base.Tuple(t::DecisionsTrait) = (t,)

"""
    abstract type Multiagency <: DecisionsTrait
    
Abstract trait type denoting the number of agents, if any, in a problem. 
"""
abstract type Multiagency <: DecisionsTrait end

"""
    struct NoAgents <: Multiagency
    
Trait denoting a network supports no agents (implying no decision nodes).
"""
struct NoAgent <: Multiagency end

"""
    struct SingleAgent <: Multiagency
    
Trait denoting a network supports exactly one agent. 
"""
struct SingleAgent <: Multiagency end

"""
    abstract type MultiAgent <: Multiagency

Abstract trait type denoting a network supports multiple agents.

The exact number of agents may (with `DefiniteAgents`) or may not (with `IndefiniteAgents`)
be specified.
"""
abstract type MultiAgent <: Multiagency end

"""
    abstract type MultiAgent <: Multiagency

Abstract trait type denoting a network supports multiple agents.
"""
struct DefiniteAgents{N} <: MultiAgent end
struct IndefiniteAgents <: MultiAgent end

abstract type Sequentiality <: DecisionsTrait end
struct Sequential <: Sequentiality end
struct Simultaneous <: Sequentiality end

abstract type Observability <: DecisionsTrait end
struct FullyObservable <: Observability end
struct PartiallyObservable <: Observability end

num_agents(::DefiniteAgents{N}) where {N} = N 
num_agents(::SingleAgent) = 1
num_agents(::NoAgent) = 0 


abstract type Cooperation <: DecisionsTrait end
struct Cooperative <: Cooperation end
struct Competitive <: Cooperation end
struct Individual  <: Cooperation end

abstract type MemoryPresence <: DecisionsTrait end
struct MemoryPresent <: MemoryPresence end
struct MemoryAbsent <: MemoryPresence end
# """
#     RewardConditioning(::Type{MarkovProblem})

# Gives the reward conditioning for the given problem type (as a tuple of symbols; e.g., 
# `(:s, :a, :sp)`).

# In the Markov family problems that have rewards, they may be conditioned on various
# parts of the problem (state, action, next state, etc). Since this determines the edges in
# the underlying DN, each of these variants is technically a different type of decision
# problem. 
# """
abstract type RewardStyle{ids} <: DecisionsTrait end
struct NoReward <: RewardStyle{()} end
struct SingleReward{ids} <: RewardStyle{ids} 
    SingleReward(ids...) = new{_sorted_tuple(ids)}()
end

abstract type MultipleRewards{ids} <: RewardStyle{ids} end
struct DefiniteRewards{N, ids} <: MultipleRewards{ids}
    DefiniteRewards(n, ids...) = new{n, _sorted_tuple(ids)}()
end
struct IndefiniteRewards{ids} <: MultipleRewards{ids}
    IndefiniteRewards(ids...) = new{_sorted_tuple(ids)}()
end

num_rewards(::MultipleRewards{n}) where {n} = n
num_rewards(::SingleReward) = 1
num_rewards(::NoReward) = 0

reward_conditions(::RewardStyle{ids}) where {ids} = ids

# abstract type ConstraintStyle <: MarkovTrait end
# struct Unconstrained <: Constrainedness end
# struct Constrained <: Constrainedness end
# struct Lexicographic <: Constrainedness end

abstract type Centralization <: DecisionsTrait end
struct Centralized <: Centralization end
struct Decentralized <: Centralization end

# abstract type Timestep <: MarkovTrait end
# struct FixedTime <: Timestep end
# struct DynamicTime <: Timestep end


abstract type Terminality <: DecisionsTrait end
struct Terminable <: Terminality end
struct NotTerminable <: Terminality end
struct MaybeTerminable <: Terminality end

abstract type Statefulness <: DecisionsTrait end
struct Stateful <: Statefulness end
struct Stateless <: Statefulness end
struct AgentFactored <: Statefulness end

abstract type TimestepStyle <: DecisionsTrait end
struct SemiMarkov <: TimestepStyle end
struct FixedTimestep <: TimestepStyle end

abstract type AgentCorrelation <: DecisionsTrait end
struct Correlated <: AgentCorrelation end
struct Uncorrelated <: AgentCorrelation end