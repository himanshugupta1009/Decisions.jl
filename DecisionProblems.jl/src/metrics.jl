

"""
    DecisionMetric

A decision metric: an aggregator of outputs of a DecisionSetting, DecisionEnvironment, or
similar object. 

When called with one argument, performs `aggregate!`.

Unlike most Decisions.jl components they are allowed (and expected) to be mutable and
stateful. 
"""
abstract type DecisionMetric end

"""
    aggregate!(::DecisionMetric, values)

Aggregate values in the NamedTuple `values` into the metric.
"""
function aggregate! end

(dm::DecisionMetric)(values) = aggregate!(dm, values)

"""
    output(::DecisionMetric)

Give the current value of the aggregated metric calculated by the DecisionMetric.
"""
function output end

"""
    reset!(::DecisionMetric)

Resets the DecisionMetric to a state before aggregating.
"""
function reset! end


"""
    Discounted{id} <: DecisionMetric

Metric which aggregates a value labelled `id` as a discounted summation: every subsequent
`aggregate!` increases the discount and decreases the impact of future calls.

Discounting is forward-directed; that is, it is assumed that the first call to 
`aggregate!` is the least discounted.
"""
mutable struct Discounted{id} <: DecisionMetric
    #TODO: Doesn't make sense for semi-Markov; discount rate vs factor
    discount::Float64
    cuml_discount::Float64
    agg::Float64
    Discounted(id::Symbol, discount)    = new{id}(discount, 1.0, 0.0)
    Discounted{id}(discount) where {id} = new{id}(discount, 1.0, 0.0)
end

function aggregate!(dm::Discounted{id}, values) where {id}
    dm.agg += dm.cuml_discount * values[id]
    dm.cuml_discount *= dm.discount
end

function reset!(dm::Discounted)
    dm.agg = 0.0
    dm.cuml_discount = 1.0
end

output(dm::Discounted) = dm.agg

"""
    const DiscountedReward

Alias for `Discounted{:r}`.
"""
const DiscountedReward = Discounted{:r}



"""
    Trace{ids} <: DecisionMetric

Metric which simply aggregates all values labelled in the Tuple `ids` into Vectors.

If `ids` is the empty tuple, aggregates all values passed to it.
"""
mutable struct Trace{ids} <: DecisionMetric
    trace::Dict{Symbol, Vector} # Can't further specialize Vector; could be Any
    Trace(ids)   = new{ids}(Dict{Symbol, Vector}())
    Trace{ids}() where {ids} = new{ids}(Dict{Symbol, Vector}())
    Trace()      = new{( )}(Dict{Symbol, Vector}())
end

function aggregate!(t::Trace{ids}, values) where {ids}
    for id in ids
        if ! (id ∈ keys(t.trace)) 
            t.trace[id] = []
        end
        push!(t.trace[id], values[id])
    end
end

function aggregate!(t::Trace{()}, values) 
    for id in keys(values) # bad choice of naming `values`. Too abstract
        if ! (id ∈ keys(t.trace))
            t.trace[id] = []
        end
        push!(t.trace[id], values[id])
    end
end

function reset!(t::Trace)
    t.trace = Dict{Symbol, Vector}()
end

function output(t::Trace)
    t.trace
end


"""
    MaxIters <: DecisionMetric 
    MaxIters(max_t)

A metric that outputs `true` until it has been called `max_iters` times, after which it
outputs `false`.
"""
mutable struct MaxIters <: DecisionMetric 
    t::Int
    max_t::Int
    MaxIters(max_t) = new(0, max_t)
end

aggregate!(dm::MaxIters, values) = (dm.t += 1)
reset!(dm::MaxIters) = (dm.t = 0)
output(dm::MaxIters) = (dm.t >= dm.max_t)