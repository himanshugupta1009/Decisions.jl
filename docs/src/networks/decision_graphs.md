# Defining decision networks

DecisionNetworks.jl provides names for some of the most commonly used decision networks,
like those that represent MDPs and POMDPs. However, if you're using this package chances are
you'd like to define a much wider set of problems and networks based on concepts like
multiagency, semi-Markovness, decentralization, and correlation. While there are obviously
too many such extensions to name, Decisions.jl provides first-class support for any network
once its decision graph has been defined.


## Standard Markov family networks

Members of particular families of decision networks can be specified from a limited set of
traits. In particular, the family containing most Markov-style networks - and therefore the
vast majority of decision problems used today - can be defined using only six nodes.

This the _standard Markov family_. Decisions.jl provides a shorthand for defining these
types of networks due to their ubiquity.

```
```

## Arbitrary networks

## Networks from transformations


