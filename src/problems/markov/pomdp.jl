struct POMDP{M, R} <: MarkovProblem{SingleAgent, PartiallyObservable, Centralized, M, R}
    transition
    observation
    reward
end

function POMDP(transition, observation, reward)
    POMDP{_default_mem(), _default_rc(reward)}(transition, observation, reward)
end