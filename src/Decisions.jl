module Decisions

include("framework/networks.jl")
export MarkovProblem
export structure
export sample

include("framework/conditional_dists.jl")
export ConditionalDist
export inputs

include("framework/hints.jl")
export ProblemHint
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
export SConditioned
export SAConditioned
export SASConditioned
export MConditioned
export MAConditioned
export NoReward

export Centralization
export Centralized
export Decentralized

include("framework/transformations.jl")
export ToTrait
export transform

include("problems/markov/Markov.jl")
export MarkovProblem
export POMDP
export @def_markov


const NewVal{T} = Val{T}
export NewVal

end # module Decisions
