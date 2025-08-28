

struct DecisionProblem{M <: DecisionMetric, DG <: DecisionNetwork, I <: Union{ConditionalDist{()}, Nothing}}
    network::DG
    objective::M
    initial::I
end

function (d::Type{<:DecisionProblem})(objective, initial=nothing, ranges=(;); dists...)
    network = graph(d)(ranges; dists...)
    DecisionProblem(network, objective, initial)
end

objective(dp::DecisionProblem) = dp.objective
network(dp::DecisionProblem) = dp.network
DecisionNetworks.graph(::DecisionProblem{M, DN}) where {M, DN} = DN

# This gets a little silly with the type params...
DecisionNetworks.graph(::Type{<:DecisionProblem{<:M, <:DecisionNetwork{A}}}) where {M, A} = DecisionNetwork{A}
DecisionNetworks.graph(::Type{<:DecisionProblem{<:M, <:DecisionNetwork{A, B}}}) where {M, A, B} = DecisionNetwork{A, B}
DecisionNetworks.graph(::Type{<:DecisionProblem{<:M, <:DecisionNetwork{A, B, C}}}) where {M, A, B, C} = DecisionNetwork{A, B, C}

initial(dp::DecisionProblem, s::Symbol) = dp.initial()[s]
initial(dp::DecisionProblem) = isnothing(dp.initial) ? (;) : dp.initial()


Base.getindex(dp::DecisionProblem, rv::Symbol) = dp.network[rv]

"""
    transform(t::DNTransformation, d::DecisionProblem)
    transform(t::DNTransformation, d::Type{<:DecisionProblem})

When applied to a `DecisionProblem` or a type of `DecisionProblem`, applies the
transformation on the underlying `DecisionNetwork` or `DecisionGraph`, respectively.
"""
function DecisionNetworks.transform(t::DNTransformation, d::DecisionProblem)
    DecisionProblem(
        transform(t, d.network),
        d.objective,
        d.initial
    )
end
function DecisionNetworks.transform(t::DNTransformation, ::Type{<:DecisionProblem{DG, M}}) where {DG, M}
    DecisionProblem{transform(t, DG), M}
end