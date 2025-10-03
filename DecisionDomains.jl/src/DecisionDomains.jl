module DecisionDomains

    import RockSample
    import POMDPs
    import POMDPTools
    import Distributions
    using DecisionNetworks
    using DecisionProblems

    include("gridworld.jl")
    include("rocksample.jl")

    export Iceworld,
    GridPointSpace,
    RockSampleDecisionsPOMDP

end # module DecisionDomains
