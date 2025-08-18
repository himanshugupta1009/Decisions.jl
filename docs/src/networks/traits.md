# Traits

Decisions.jl provides a variety of named traits on `DecisionNetwork`s, `ConditionalDist`s,
and other objects in the package. They serve as hints to algorithms as well as the package
itself.

This page provides the technical docs for each trait.

```@docs
DecisionsTrait
```

## Traits on decision networks

### Sequentiality
```@docs
Sequentiality
Sequential
Simultaneous
```

### Partial observability / information perfection
```@docs
Observability
FullyObservable
PartiallyObservable
```

### Number of agents
```@docs
Multiagency
NoAgent
SingleAgent
MultiAgent
DefiniteAgents
IndefiniteAgents
```

### Agent cooperation
```@docs
Cooperation
Cooperative
Competitive
Individual
```

### Agent memory
```@docs
MemoryPresence
MemoryPresent
MemoryAbsent
```

### Reward presence and style
```@docs
RewardStyle
NoReward
SingleReward
DefiniteRewards
IndefiniteRewards
```

### Agent centralization
```@docs
Centralization
Centralized
Decentralized
```

### Statefulness and state structure
```@docs
Statefulness
Stateful
Stateless
AgentFactored
```

### Semi-Markovianness and step style
```@docs
TimestepStyle
SemiMarkov
FixedTimestep
```

### Agent correlation
```@docs
AgentCorrelation
Correlated
Uncorrelated
```

## Traits on random variables

`RVGroup`s can accept traits, which are primarily used as hints to `sample` and other such
functions for optimal performance.

Due to their internal role they are not exported by default.

### Terminality

```@docs
DecisionNetworks.Terminality
DecisionNetworks.Terminable
DecisionNetworks.NotTerminable
DecisionNetworks.MaybeTerminable
```

## Traits on conditional distributions

!!! todo

    None exist yet. `Determinism` is the most relevant left to be implemented.


## Traits on spaces

!!! todo

    None exist yet. I think things like `Finitude` and `Countability` are reasonable, 
    but they're a low priority.