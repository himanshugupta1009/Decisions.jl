# Markov family problems

The Markov family (or "Wray class") is a set of commonly used dynamic decision networks.
Formally, it is the set of decision problems represented with DDNs using a [fixed set of
specific nodes](@ref Markov family variables). It includes Markov chains at its simplest
(which involve no decisions at all), to arbitrary extensions of such problems`` at its most
complex (e.g., "\[lexicographic\] \[partially observable\] \[semi-\]Markov \[games\]"). In
between are widely used models like MDPs, POMDPs, and Markov games. Markov problems can be
[sampled](@ref `sample`), [transformed](@ref `transform`), and in general treated like
generic decision problems.

Note that it is rarely necessary to explicitly construct and interact with general
`MarkovProblem`s. [Commonly used Markov family problems](@ref), like MDPs and POMDPs, are
defined by name and should be used when available.

```@docs
MarkovProblem
```

## Defining Markov problems
The dynamic decision network for a type of Markov problem can be inferred by a set of seven
[`ProblemTrait`](@ref)s, given as type parameters. These traits are:

- **[Multiagency](@ref)**: How many agents are there? (Differentiates e.g. MCs from MDPs
  from MGs.)
- **[Observability](@ref)**: Is the environment fully or partially observed? (Differentiates
  e.g. MDPs from POMDPs.)
- **[Centralization](@ref)**: Are observations shared across agents? (Differentiates e.g.
  multi-POMDPs from Dec-POMDPs.)
- **[Reward conditioning](@ref `RewardConditioning`)**: What variables is the reward based
  on? (Not typically explicit. Differentiates e.g. MDP with R|S, MDP with R|S,A, MDP with
  R|S,A,S'. By default, matches the given reward function, if one is provided.)
- **[Memory presence](@ref `MemoryPresence`)**:  (Not typically explicit. Controls whether
  the [memory node](@ref Memory in Markov problems) is present. Present by default.)
- **[Semi-Markovianness](@ref 'StepStyle`)**: Is the problem semi-Markovian? (Differentiates
  e.g. MDPs from semi-MDPs.)
- **[Constraint style](@ref `ConstraintStyle`)**: What kind of constraints are included?
  (Differentiates e.g. MDPs from CMDPs from lexicographic MDPs.)


## Markov family variables
The nodes in a Markov family problem are named as follows:
* `sp` (**state prime**). New state, based on current state. Dynamically mapped to `s`
  (**state**).
* `a` (**action**).
* `o` (**observation**).
* `r` (**reward**).
* `mp` (**memory prime**). New memory, based on current memory. Dynamically mapped to `m`
  (**memory**).
* `τ` (**sojourn time**). Used for defining semi-Markovian problems.
* `c` (**slack**). Used for defining multi-objective, constrained, and lexicographic
  problems.

All nodes except `a` and (when present) `mp` have conditional distributions defined with
[`behavior`](@ref). `a` and `mp` are, instead, decision nodes.


## Commonly used Markov problems
Named problems like Markov decision processes and Markov games are explicitly defined.

```@docs
MDP
```