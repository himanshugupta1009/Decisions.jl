# Defining decision networks

DecisionNetworks.jl provides names for some of the most commonly used decision networks,
like those that represent MDPs and POMDPs. However, if you're using this package chances are
you'd like to define a much wider set of problems and networks based on concepts like
multiagency, semi-Markovness, decentralization, and correlation. While there are obviously
too many such extensions to name, Decisions.jl provides first-class support for any network
once its decision graph has been defined.

## 

## Arbitrary networks

A new type of decision network can be defined with the `DecisionGraph` constructor:

* `nodes` is a list of pairs, each one mapping node inputs (as `ConditioningGroup`s) to an
  output (as a `Plate`). 
* `dynamic_pairs` is a NamedTuple mapping current-iterate to future-iterate node names.
* `ranges` is a NamedTuple mapping indexing variable names to lengths.

!!! warning

    Use the `DecisionGraph` constructor to get a `Type{<:DecisionNetwork}` rather than using
    `DecisionNetwork{...}` directly. This ensures that `nodes` and other parameters of the
    decision graph can have enforced structures (for instance, order invariance on inputs) to
    prevent ambuguity.






## Standard Markov family networks

Members of certain families of decision networks can be specified from a limited set of
traits. In particular, the family containing most Markov-style networks - and therefore the
vast majority of decision problems used today - can be defined using only six nodes and two
inputs:

* `s`: Current state
* `m`: Current [memory](@ref)
* `sp`: Successor state; that is, **s**tate-**p**rime. The distribution that implements it is often called the
  _transition_. Dynamically paired with `s`.
* `mp`: Successor [memory](@ref); that is, **m**emory-**p**rime (a decision node).  
* `a`: Action (a decision node).
* `r`: Reward
* `o`: Observation
* `τ`: Sojourn time (for semi-Markov models)

This the _standard Markov family_. Due to their ubiquity, Decisions.jl provides a shorthand
for defining these types of networks based on the [relevant traits](@ref "Traits on decision networks").

```@docs
    DecisionNetworks.@markov_alias
    DecisionNetworks.MarkovAmbiguousTraits
```

