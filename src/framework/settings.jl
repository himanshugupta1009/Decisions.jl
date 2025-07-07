



macro SingleDecisionSetting()
    quote
        DecisionProblem{structure, (;)}(;
            problem,
            policy,
            objective
        )
    end
end

const SingleDecisionSetting = @SingleDecisionSetting

function (@SingleDecisionSetting)(problem, objective)
    DecisionNetwork(;
        problem = DeterministicDist(() -> Problem, DecisionNetwork)
        policy = 
        objective
    )
end


