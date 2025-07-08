
abstract type DecisionAlgorithm end

"""
    solve(alg::DecisionAlgorithm, prob::DecisionNetwork)

Calculate agent behavior for decision network `prob` using algorithm `alg` and return it as
a NamedTuple that maps node names to `ConditionalDist`s (policies).
"""
function solve end