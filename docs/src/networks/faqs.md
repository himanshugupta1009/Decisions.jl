# FAQs



## How do I represent terminal states?
Rather than using dedicated functions that check for terminality (like in POMDPs.jl),
Decisions.jl assumes conditional distributions return [`terminal`](@ref). when terminal conditions
are reached. See also [`Terminal`](@ref), [`isterminal`](@ref).

There are two main benefits of this approach: 
* Any node can be terminal (allowing, for instance, terminal actions)
* Unecessary terminality checks can be avoided during simualtion: e.g., if a particular
  check in a conditional distribution already ensures a nonterminal output.


## How do I have a variable number of agents in a decision network / graph?
The [`ranges`](@ref) type parameter represents the number of agents (and other plate
indices). If you'd like to represent the _class_ of decision networks of a particular type,
but without any specific number of agents or implemented conditional distributions, this can
be represented out of the box with a `DecisionGraph` (which, under the hood, will represent
`DecisionNetwork{your_nodes, your_dynamic_pairs, ranges} where {ranges}`)


## Why are random variables keyword arguments?
In short: Unlike arguments of functions in general, conditions of conditional distributions
are often left unordered in common notation. We expect `p(⋅ | x, y)` to be the same as `p(⋅
|y, x)`.

To be more specific, when an argument order is imposed on conditional distributions, the
consequences can be very confusing: for instance, we know the random variables in a MDP's
reward distribution are traditionally ordered `[s, a, sp]`, but this disagrees with the
lexical order imposed by `DecisionGraph` to ensure order invariance. When more conditions
are added and removed by transformations, the "right" ordering becomes entirely unclear.

Using keyword arguments instead bypasses these problems, [with some free syntactic
sugar on top](@ref "Statistical syntax").


## What exactly are the `m`/`mp` nodes?
These are the "memory" / "successor memory" nodes used in partially observable standard
Markov family networks. In single-agent theory, these are traditionally referred to
as _beliefs_, and the implementation of `mp` is the _belief updater_. 

Agent behavior (including `a` and `mp`), like all nodes, is represented with stateless
conditional distributions, meaning that agent internal state must be passed along in the
network itself. This is the use of the memory nodes. We consider it crucial to explicitly
model agent internal state in the network, rather than just allowing action distributions to
be stateful, for several reasons:

* Conditional distributions are, fundamentally, not stateful. Therefore, neither are
  policies. (Or, in broader terms: this approach better connects Decisions.jl to the
  underlying mathematics, one of the major package objectives.)
* We want to definitively compare agents based on the type, quantity, and quality of
  information collected during execution within an environment. More importantly, we want to
  distinguish this information from data gathered over _multiple_ executions of a simulated
  environment (which may or may not be related to in-execution memory).
* Determining uniqueness of agent history / belief / etc. is useful for efficiency
  reasons.
* Finite state controllers (FSCs) are the most general policy (even provably beyond DNNs,
  belief tracking, state compression, and so on) and they have have this form.
* In multiagent problems, the relationship _between_ memory nodes causes complex and
  unexpected interactions (for instance, infinite regress in the [hierarchy of
  beliefs](https://en.wikipedia.org/wiki/Hierarchy_of_beliefs).) 

