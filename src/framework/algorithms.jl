
abstract type DecisionAlgorithm end


"""
    init_parameters(dm::DecisionProblem, alg::DecisionAlgorithm)
    
"""



"""
    decisions(dn::DecisionNetwork, alg::DecisionAlgorithm)    


"""
function decisions end


"""
    evaluate(dn::DecisionNetwork, alg::DecisionAlgorithm, obj::DecisionObjective)    

Evaluates decisions made by `alg` in decision network `dn` according to objective `obj`.

"""

function decisions end

function decisions(
    alg::AbstractArray{DecisionAlgorithm}, 
    obj::DecisionObjective, prob::DecisionNetwork)
    # TODO: Merge behavior from all algorithms
end