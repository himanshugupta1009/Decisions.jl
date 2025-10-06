using Random
include("DecisionDomains.jl/src/gridworld.jl")

prob = Iceworld()

policy = @ConditionalDist Cardinal begin
    rand(rng; s) = rand(rng, support(prob[:a]))   # uniform random
end

struct RandomSolver <: DecisionAlgorithm
end

function Decisions.solve(alg::RandomSolver, prob::DecisionProblem)
    action_type = eltype(prob[:a])
    pol = @ConditionalDist action_type begin
        function rand(rng; s)
            rand([support(prob[:a])...])
        end
    end
    (; a = pol)
end

function run_episode(;max_steps=10)
    steps = 0
    simulate!(RandomSolver(), prob) do vals
        println(vals)
        steps +=1
        steps >= max_steps
    end
end

run_episode()

