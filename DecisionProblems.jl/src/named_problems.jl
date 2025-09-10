
"""
    const MDP = DecisionProblem{<: DiscountedReward, <: MDP_DN}

A Markov decision process.
"""
const MDP = DecisionProblem{<: DiscountedReward, <: MDP_DN}

"""
    const POMDP = DecisionProblem{<: DiscountedReward, <: POMDP_DN}

A partially observable Markov decision process.
"""
const POMDP = DecisionProblem{<: DiscountedReward, <: POMDP_DN}

"""
    const MG = DecisionProblem{<: DiscountedReward, <: MG_DN}

A Markov game.
"""
const MG = DecisionProblem{<: DiscountedReward, <: MG_DN}