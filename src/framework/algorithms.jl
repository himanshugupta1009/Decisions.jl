
# # Node names for meta DNs
# # :params


# struct DecisionProblem{N <: DecisionNetwork, M <: DecisionMetric}
#     network::N
#     metric::M
# end


# abstract type DecisionParameterUpdate{K, T}             <: ConditionalDist{K, T} end
# abstract type DecisionAlgorithm{K, T<:NamedTuple}       <: ConditionalDist{K, T} end
# abstract type DecisionObjective{K, T}                   <: ConditionalDist{K, T} end
# abstract type DecisionModelShift{K, T<:DecisionNetwork} <: ConditionalDist{K, T} end


# rand(rng, p::DecisionParameterUpdate; kwargs...) = update_params(p; kwargs...)
# rand!(rng, p::DecisionParameterUpdate{K, T}, dest::T; kwargs...) = update_params!(p, dest; rng, kwargs...)
# update_params!(p::DecisionParameterUpdate{K, T}, dest::T; kwargs...) = update_params(p; kwargs...)


# rand(rng, a::DecisionAlgorithm; kwargs...) = solve(a; kwargs...)
# rand!(rng, a::DecisionAlgorithm{K, T}, dest::T; kwargs...) = calculate_policy!(a, dest; rng, kwargs...)
# calculate_policy!(a::DecisionAlgorithm{K, T}, dest::T; kwargs...) = calculate_policy(a; kwargs...)


# rand(rng, a::DecisionObjective; kwargs...) = evaluate(a; kwargs...)
# rand!(rng, a::DecisionObjective{K, T}, dest::T; kwargs...) = evaluate!(a, dest; rng, kwargs...)
# evaluate!(a::DecisionObjective{K, T}, dest::T; kwargs...) = evaluate(a; kwargs...)


# rand(rng, a::DecisionModelShift; kwargs...) = model_shift(a; kwargs...)
# rand!(rng, a::DecisionModelShift{K, T}, dest::T; kwargs...) = model_shift!(a, dest; rng, kwargs...)
# model_shift!(a::DecisionModelShift{K, T}, dest::T; kwargs...) = model_shift(a; kwargs...)