

abstract type DecisionObjective end

"""
    evaluate(
        objective::DecisionObjective,
        behavior::NamedTuple,
        problem::DecisionNetwork
    )

Evaluate agent `behavior` in `problem` according to `objective`.

The objective controls the metric to calculate and the way in which this evaluation is
carried out.
"""
function evaluate end


"""
    SingleDiscountedReward <: DecisionObjective

Objective which samples a single discounted reward from the decision problem. 
"""
struct SingleDiscountedReward <: DecisionObjective
    discount::Float64
    initial_configuration
end

function evaluate(
    obj::SingleDiscountedReward,
    dn::DecisionNetwork,
    policy::NamedTuple,
)
    rvs = obj.initial_configuration
    agg_discount = 1
    sum = 0
    while ! isterminal(rvs)
        rvs = sample(dn, policy, rvs)
        sum += agg_discount * rvs[obj.reward_node]
        agg_discount *= obj.discount
    end
    sum
end

struct Trace <: DecisionObjective
    function evaluate(
        obj::SingleDiscountedReward,
        dn::DecisionNetwork,
        policy::NamedTuple,
    )
        rvs = obj.initial_configuration
        agg_discount = 1
        sum = 0
        while ! isterminal(rvs)
            rvs = sample(dn, policy, rvs)
            sum += agg_discount * rvs[obj.reward_node]
            agg_discount *= obj.discount
        end
        sum
    end
end