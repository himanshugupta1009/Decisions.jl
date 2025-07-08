



macro OfflineSetting()
    quote
        DecisionNetwork{DecisionGraph{
            (; problem=(), policy=(:problem,), output=(:problem, :policy)),
            (;)
        }}
    end
end

const OfflineSetting = @OfflineSetting

function (::@OfflineSetting)(
    problem::DecisionNetwork, 
    alg::DecisionAlgorithm, 
    objective::DecisionObjective
)
    DecisionNetwork(;
        problem = SingletonDist(problem),
        policy = ConditionalDist((:problem, :meta)) do (problem, meta)
            solve(alg, problem; meta)
        end,
        output = ConditionalDist((:problem, :policy, :meta)) do (problem, policy, meta)
            evaluate(objective, problem, policy; meta)
        end
    )
end