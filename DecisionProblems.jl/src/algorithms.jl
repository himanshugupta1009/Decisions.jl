

abstract type DecisionAlgorithm end

"""
    solve!(da::DecisionAlgorithm, model::DecisionProblem)
"""
function solve! end

# TODO: Should this be a generated function like `sample`?
function simulate(da::DecisionAlgorithm, dp::DecisionProblem, external_metrics::DecisionMetric...)
    reset!.(external_metrics)
    reset!(dp.metric)

    decisions = solve!(da, dp)
    initialization = isnothing(dp.initial) ? (;) : dp.initial()
    sample(dp.network, decisions, initialization) do rvs
        aggregate!(dp.metric, rvs)
        for other_metric in external_metrics
            aggregate!(other_metric, rvs)
        end
        return false # TODO - no ability to cause termination
    end

    if isempty(external_metrics)
        output(dp.metric)
    else 
        (output(dp.metric), map(output, external_metrics)...)
    end
end
