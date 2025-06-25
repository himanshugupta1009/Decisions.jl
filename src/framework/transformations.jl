

abstract type DNTransformation end

struct ToTrait{H <: ProblemHint} <: DNTransformation
    ToTrait(T) = new{T}()
end

# abstract type DNNodeTransformation{node} <: DNTransformation end

# abstract type DNNetworkTransformation <: DNTransformation end

# """
#     transform_network(t::DNTransformation, dn::DecisionNetwork)

# Applies transformation `t` to (dynamic) decision network `dn`, returning a new (dynamic)
# decision network.

# It is not generally possible to state the decision problem either network corresponds to.
# In particular, the new (dynamic) decision network could correspond to any type of decision
# problem, including one that has no common name or special representation in this package.
# """
# function transform_network(t::DNTransformation, dn::DecisionNetwork)
# end

# """
#     transform_problem(
#         t::DNTransformation, 
#         p1::DecisionProblem, 
#         p2_type::Type{<:DecisionProblem}
#     )

# Applies transformation `t` to decision problem `p1`, changing it to a decision problem of
# type `p2_type`. 

# When `transform(transformation, structure(problem1)) = structure(problem2)`, this is
# implemented 
# """
# function transform_problem(::DNTransformation, ::DecisionProblem, ::Type{<:DecisionProblem})
# end

# function transform_problem(::DecisionProblem, ::Type{<:DecisionProblem})
# end