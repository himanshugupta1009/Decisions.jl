```@setup dns
using Decisions
```

# Decision networks

The fundamental unit of problem description in Decisions.jl is the (dynamic) _decision
network_ or (D)DN (variously related to or synonymous with "influence diagram," "generalized
Bayesian network," and "decision diagram"). A _decision network_ is a directed acyclic graph
where each node is the distribution of a random variable conditioned on some other nodes in
the network. 

In Decisions.jl, DNs consist of two components:

* A **decision graph**, which gives the abstract definition of the relationships between
  random variables in the network, and 
* An **implementation**, which provides some of the conditional distributions in the network.
  Nodes with no implemented distribution are considered _decision nodes_. 

The decision graph is given by the `Type{<:DecisionNetwork}`, meaning that computation
regarding the structure of a DN can be done at compile time. `DecisionNetwork` instances
carry `implementation` as well.

```@docs
DecisionNetwork
implementation
```

## Instantiating DNs

Every node in DecisionNetworks.jl is a random variable, named with a Symbol. Values and
distributions associated with them are passed around as keyword arguments (a pattern seen in
many places in Decisions.jl). So, to make a new DN, we pass these distributions into the
constructor for a `Type{<:DecisionNetwork}`. (The `Type{<:DecisionNetwork}` itself gives the
decision graph - which tells us how these random variables condition each other.)

There are several ways to get a `Type{<:DecisionNetwork}` that can be instantiated. For
instance, we might use the premade `MDP_DN` network type: it is the the decision graph
underlying all Markov decision processes:


```@example dns
my_dn = MDP_DN(; 
    sp = (rng; s, a) -> rand(rng), 
    r = (rng; s, a, sp) -> s + a
)
```

!!! tip

    `Function`s and `Space`s that are passed to the constructor as implementations for 
    distributions are [automatically `convert`ed to `ConditionalDist`s](@ref).

The pretty-printed output tells us something about the DN: it has nodes named `a`, `r`, `s`,
and `sp`, it has the given conditionings for those nodes, and it's a DDN where `sp` becomes
`s` at each iterate. Indeed, all Markov decision problems have decision network nodes `s`
(state), `sp` (successor state), `r` (reward), and `a` (action). The distributions for `sp`,
`r`, and `a` are the state transition, reward function, and policy respectively. In the
parentheses, we see that we've provided implementations for `r` and `sp`, but `a` has no
implementation; that is, it is a decision node.

The prenamed decision network types defined by DecisionNetworks.jl cover the most commonly
used networks, but later sections in this documentation deal with [types for arbitrary
networks](@ref), which is where DecisionNetworks shines.


## Sampling DNs
As mentioned above, every node in a DN is a random variable with a `Symbol` name.
Conditional distributions for nodes can be obtained with index notation:

```@example dns
my_dn[:sp]
```

This gives the conditional distribution for `sp` in this DDN (that is, the state
transition). All sorts of useful functions for algorithm writers are defined on conditional
distributions, documented on [their own manual page](@ref).

An entire DN or DDN can be sampled given inputs with `sample`:

```@docs
sample
```

## Using DN structure

The structures underlying decision networks - that is, decision graphs - are represented
with (1) an input => output definition for each node, (2) mappings from current-iterate to
next-iterate nodes (for a dynamic decision network), and (3) sizes for each [plate](@ref).
They can all be queried of both `DecisionNetwork`s and `Type{<:DecisionNetwork}`s.

```@docs
    nodes
    dynamic_pairs
    ranges
    node_names
    next
    prev
```

## Traits on decision networks

Decisions.jl defines a number of traits on various objects, especially decision networks.
They are implemented using [the Holy trait
pattern](https://discourse.julialang.org/t/holy-traits-vs-boolean-traits/111954). The full
documentation for each trait is available [here](@ref).

Traits on decision networks are used to give an exact idea of how particular semantic
concepts, like "partial observability" and "sequentiality", correspond to actual decision
networks. Some of these traits can be used for [defining new decision networks](@ref)
conveniently and easily.


!!! todo

    Traits are not automatically applied to `@markov_alias`'d networks.


| Trait              | Possibilities supplied by Decisions.jl                             | Description
| :----------------- | :----------------------------------------------------------------- | :------------------------------------------------------ |
| `Multiagency`      | `NoAgent`, `SingleAgent`, `DefiniteAgent`, `IndefiniteAgent`       | Number of agents in a problem (and whether that number is known)
| `Observability`    | `FullyObservable`, `PartiallyObservable`                           | Whether input into decision nodes is a sufficient statistic for other nodes in the DN
| `Centralization`   | `Centralized`, `Decentralized`                                     | Whether input into decision nodes is the same across agents
| `MemoryPresence`   | `MemoryPresent`, `MemoryAbsent`                                    | Whether there is an agent-defined information aggregator across DDN iterates
| `RewardStyle`      | `NoReward`, `SingleReward`, `DefiniteRewards`, `IndefiniteRewards` | Whether a "reward" node is present, how many rewards it represents, and what it is conditioned on
| `Statefulness`     | `Stateful`, `Stateless`, `AgentFactored`                           | Presence and structure of a "state" node
| `Sequentiality`    | `Simultaneous`, `Sequential`                                       | Whether decision nodes are calculable in parallel
| `Cooperation`      | `Cooperative`, `Competitive`, `Individual`                         | Whether agents are implied to share or interfere with each others' objectives
| `AgentCorrelation` | `Correlated`, `Uncorrelated`                                       | Whether agents jointly or independently sample their decisions
| `TimestepStyle`    | `FixedTime`, `SemiMarkov`                                          | Whether the network is implied to represent a semi-Markov problem
