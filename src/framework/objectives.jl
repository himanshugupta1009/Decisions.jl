

abstract type DecisionObjective end

"""
    evaluate(
        behavior::NamedTuple,
        problem::DecisionNetwork,
        objective::DecisionObjective
    )

Evaluate `behavior` in `problem` according to `objective`.

The objective controls the way in which this evaluation is carried out.
"""
function evaluate(
    behavior::NamedTuple,
    problem::DecisionNetwork,
    objective::DecisionObjective) end


# TODO: Not set up for semi-MDPs; maybe needs its own struct? Not sure how the 
#   underlying integration works. Need to ask Kyle.
struct InfiniteDiscountedReward <: DecisionObjective
    terminal::Function
    reward_node::Symbol
    discount::Float64
    initial_configuration

    # function InfiniteDiscountedReward(discount; reward_node=:r)
    # end
end

function evaluate(
    behavior::NamedTuple, 
    prob::DecisionNetwork, 
    obj::InfiniteDiscountedReward
)
    rvs = obj.initial_configuration
    agg_discount = 1
    sum = 0
    while ! obj.terminal(rvs)
        rvs = sample(prob, behavior, rvs)
        sum += agg_discount * rvs[obj.reward_node]
        agg_discount *= obj.discount
    end
    sum
end

