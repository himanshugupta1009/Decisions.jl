
abstract type DecisionNetworkTrait end

# For convenience
Base.Tuple(t::DecisionNetworkTrait) = (t,)

abstract type Sequentiality <: DecisionNetworkTrait end
struct Sequential <: Sequentiality end
struct Simultaneous <: Sequentiality end

abstract type Observability <: DecisionNetworkTrait end
struct FullyObservable <: Observability end
struct PartiallyObservable <: Observability end


# TODO: Technically this is weird because Multiagency{1 or 0} are possible
abstract type Multiagency <: DecisionNetworkTrait end
struct NoAgent <: Multiagency end
struct SingleAgent <: Multiagency end
abstract type MultiAgent <: Multiagency end
struct DefiniteAgents{N} <: MultiAgent end
struct IndefiniteAgents <: MultiAgent end

num_agents(::DefiniteAgents{N}) where {N} = N 
num_agents(::SingleAgent) = 1
num_agents(::NoAgent) = 0 


abstract type Cooperation <: DecisionNetworkTrait end
struct Cooperative <: Cooperation end
struct Competitive <: Cooperation end

abstract type MemoryPresence <: DecisionNetworkTrait end
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
abstract type RewardConditioning <: DecisionNetworkTrait end
struct NoReward <: RewardConditioning end
struct ConditionedOn{ids} <: RewardConditioning 
    ConditionedOn(ids...) = new{Tuple(sort([ids...]))}()
end

# abstract type ConstraintStyle <: MarkovTrait end
# struct Unconstrained <: Constrainedness end
# struct Constrained <: Constrainedness end
# struct Lexicographic <: Constrainedness end

abstract type Centralization <: DecisionNetworkTrait end
struct Centralized <: Centralization end
struct Decentralized <: Centralization end

# abstract type Timestep <: MarkovTrait end
# struct FixedTime <: Timestep end
# struct DynamicTime <: Timestep end


abstract type Terminality <: DecisionNetworkTrait end
struct NeverTerminal <: Terminality end
struct MaybeTerminal <: Terminality end
struct AlwaysTerminal <: Terminality end