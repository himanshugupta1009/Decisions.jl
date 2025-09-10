
# Decisions.jl

!!! warning 

    Decisions.jl is currently under active development in **silent beta**: it is
    publically accessible but not promoted or registered. Expect bugs and breaking changes. 

## What is Decisions.jl?
Decisions.jl is an ecosystem for canonical representations of decision problems. Using
decision networks as the fundamental underlying structure, Decisions.jl provides an explicit
interface for a rich set of decision problems: from the most basic Markov decision
processes, to rich and expressive multi-agent, semi-Markov, multi-objective extensions, to
complex problems unifying decision-, control-, and game-theoretic models.

Decisions.jl is factored into three framework packages:

* **DecisionNetworks.jl** (beta) provides fundamental tools for the ecosystem:
  representations for decision networks, conditional distributions, support spaces, and
  visualizations.
* **DecisionProblems.jl** (beta) introduces objectives over decision networks and formal
  definitions of decision problems.
* **DecisionSettings.jl** (alpha) introduces real-world decision making scenarios,
  surgically defining concepts of agents, training loops, and environment interactions to
  permit truly exact comparisons between algorithms.

... and two implementation packages:

* **DecisionDomains.jl** provides implementations of common baseline decision making domains
  for benchmarking.
* **DecisionAlgorithms.jl** provides off-the-shelf implementations of classic
  decision-making algorithm.

If you're contributing to Decisions.jl, or you don't mind some unnecessary
dependencies, the package `Decisions` itself reexports all names from the packages listed
above, so you can just write `using Decisions`.

Finally, Decisions.jl is a work in progress. Please report issues and feature requests [on Github](https://github.com/JuliaDecisionMaking/Decisions.jl/issues).

## Objectives

Decisions.jl is designed to be, in this order:
* **Definitive**. Decision problems have precise mathematical definitions which are
  respected by Decisions.jl. It's easy to understand the exact specification of a given
  problem and compare algorithms on even footing.
* **Modular**. Decision networks can be transformed, composed, stacked, and modified to
  create rich, expressive models. Algorithms designed for specific decision problems can be
  easily applied to extensions or simplifications of those problems. 
* **Fast**. Almost all of the overhead computation Decisions.jl uses to handle general
  decision networks is compile-time. Once compiled, all decision problems are first class,
  as efficiently used and sampled as any other.