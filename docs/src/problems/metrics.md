# Metrics

Decision networks alone have no concepts of solution or objective - they are just
environment models. At most, they have action nodes that are not yet implemented, to be
determined "somewhere else" then used as input to [`sample`](@ref) and the like. 

DecisionProblems.jl provides the missing link. A **decision problem** joins a decision
network and a **metric**, which indicates an optimization objective over the random
variables in the network. **Decision algorithms** implement the missing
distributions in the decision network in order to optimize that metric. 



## Using decision metrics

`DecisionMetric` and its descendants define objectives over decision networks. Decision
metrics vary from simple benchmarks ("how many steps did this DDN run?") to ubiquitous
objective concepts ("what is the discounted sum of rewards from this state?").

```@docs
DecisionMetric
```

`DecisionMetric`s act as aggregators for the values of random variables, and among other
things, they can be provided as the first argument of [`sample`](@ref). At each iterate (or
once after execution, for a non-dynamic decision network), the metric's `aggregate!` is
called with a NamedTuple of random variable values from the network.

```@docs
aggregate!
```

Unlike most components of Decisions.jl, **decision metrics are stateful**. (This helps
prevent excessive memory usage from computing episode traces). Use `output` to
retrieve the result after aggregation, or `reset!` to reset the metric object to its initial
configuration:

```@docs
    output
    reset!
```


## Provided decision metrics
`DecisionMetric`s are primarily used for consistency and fair comparison: while using a
stateful `do` block for `sample` is permissible, using a `DecisionMetric` instead ensures
all algorithms which use the same metric follow precisely the same objective definition
(even, to some extent, with different decision networks). As such DecisionProblems.jl
provides a number of definitive metrics.

!!! todo

    A significant number of metrics remain to be written. 

```@docs
    Discounted
    DiscountedReward
    Trace
    MaxIters
```