


abstract type ProblemTrait end

abstract type Sequentiality <: ProblemTrait end
struct Sequential <: Sequentiality end
struct Simultaneous <: Sequentiality end

abstract type Observability <: ProblemTrait end
struct FullyObservable <: Observability end
struct PartiallyObservable <: Observability end


# TODO: Technically this is weird because Multiagency{1 or 0} are possible
#   Can fix this by reorganizing the type tree but not high concern
abstract type Multiagency <: ProblemTrait end
struct NoAgent <: Multiagency end
struct SingleAgent <: Multiagency end
abstract type MultiAgent{N} <: Multiagency end
struct Cooperative{N} <: MultiAgent{N} end
struct Competitive{N} <: MultiAgent{N} end

abstract type MemoryPresence <: ProblemTrait end
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
abstract type RewardConditioning <: ProblemTrait end
struct ConditionedOn{ids} <: RewardConditioning end
struct NoReward <: RewardConditioning end

# abstract type ConstraintStyle <: MarkovTrait end
# struct Unconstrained <: Constrainedness end
# struct Constrained <: Constrainedness end
# struct Lexicographic <: Constrainedness end

abstract type Centralization <: ProblemTrait end
struct Centralized <: Centralization end
struct Decentralized <: Centralization end

# abstract type Timestep <: MarkovTrait end
# struct FixedTime <: Timestep end
# struct DynamicTime <: Timestep end

