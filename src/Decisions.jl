module Decisions

using Parameters
using Distributions
using Random

include("framework/spaces.jl")
export Space
export FiniteSpace

include("framework/conditional_dists.jl")
export ConditionalDist
export UniformDist
export EmptyDist

include("framework/networks.jl")
export DecisionGraph
export DecisionNetwork
export structure
export dynamism
export sample
export next
export prev


include("framework/hints.jl")
export ProblemTrait
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
export Cooperative
export Competitive

export MemoryPresence
export MemoryPresent
export MemoryAbsent

export RewardConditioning
export ConditionedOn

export Centralization
export Centralized
export Decentralized

include("framework/transformations.jl")
export Collapse
export Recondition
export Insert
export Memoryless

export transform

include("problems/markov/Markov.jl")
export MarkovProblem
export POMDP
export @def_markov
export @memoryless


const NewVal{T} = Val{T}
export NewVal

end # module Decisions
