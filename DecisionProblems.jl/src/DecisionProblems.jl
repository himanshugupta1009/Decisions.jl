module DecisionProblems

using DecisionNetworks
using StaticArrays

include("metrics.jl")
export DecisionMetric

export aggregate!
export output
export reset!

export Discounted
export DiscountedReward
export Trace
export MaxIters

include("problems.jl")
export DecisionProblem
export network
export graph
export initial

include("algorithms.jl")

include("named_problems.jl")
export MDP

include("vi.jl")

end