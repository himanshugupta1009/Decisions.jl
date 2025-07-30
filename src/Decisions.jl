module Decisions

using Parameters
using Distributions
using Random
using ExprTools
using StaticArrays

include("framework/hints.jl")
export DecisionsTrait
export Sequentiality
export Sequential
export Simultaneous

export Observability
export FullyObservable
export PartiallyObservable

export Multiagency
export NoAgent
export SingleAgent
export MultiAgent
export DefiniteAgents
export IndefiniteAgents

export Cooperation
export Cooperative
export Competitive
export Individual

export MemoryPresence
export MemoryPresent
export MemoryAbsent

export RewardStyle
export SingleReward
export DefiniteRewards
export IndefiniteRewards
export NoReward

export Centralization
export Centralized
export Decentralized

export Statefulness
export Stateful
export Stateless
export AgentFactored

export TimestepStyle
export SemiMarkov
export FixedTimestep

export AgentCorrelation
export Correlated
export Uncorrelated

include("framework/groups.jl")
export Indep
export JointAndIndep
export Joint
export Parallel
export Dense

export name
export indices

include("framework/spaces.jl")
export Space
export FiniteSpace

include("framework/conditional_dists.jl")
export ConditionalDist
export AnonymousDist
# export UniformDist
export EmptyDist
# export CategoricalDist
# export DeterministicDist
export @ConditionalDist

export support
export rand!
export pdf
export logpdf
export fix
export conditions

include("framework/network_utils.jl")
include("framework/validity.jl")
include("framework/networks.jl")
export DecisionGraph
export DecisionNetwork
export nodes
export dynamic_pairs
export sample
export next
export prev
export graph
export Terminal

include("framework/algorithms.jl")
export DecisionAgent


include("framework/objectives.jl")
export DecisionObjective

include("framework/settings.jl")
export OfflineSetting

include("framework/transformations.jl")
export Collapse
export Recondition
export Insert
export Memoryless

export transform

include("problems/markov/Markov.jl")

end # module Decisions
