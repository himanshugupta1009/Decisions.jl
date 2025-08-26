module DecisionProblems

include("metrics.jl")
export DecisionMetric

export aggregate!
export output
export reset!

export Discounted
export DiscountedReward
export Trace
export MaxIters

end