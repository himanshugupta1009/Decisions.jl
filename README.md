# Decisions.jl
## Definitive decision problems in Julia
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://USER_NAME.github.io/PACKAGE_NAME.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://USER_NAME.github.io/PACKAGE_NAME.jl/dev)

Decisions.jl is an ecosystem for canonical representations of decision problems, from the
most basic Markov decision processes, to rich and expressive multi-agent, semi-Markov,
multi-objective extensions, unifying decision-, control-, and game-theoretic models.

> [!WARNING] 
> Decisions.jl is under active development. It is currently in **silent beta**:
> publically accessible but not promoted or registered. Expect bugs and breaking changes. 

## Package structure
Decisions.jl is factored into three framework packages:

* **DecisionNetworks.jl** (closed beta) provides fundamental tools for the
  ecosystem: decision networks, conditional distributions, support
  spaces, and visualizations.
* **DecisionProblems.jl** (closed alpha) introduces objectives over decision
  networks and formal definitions of decision problems.
* **DecisionSettings.jl** (closed alpha) introduces real-world decision making
  scenarios, surgically defining concepts of agents, training loops, and environment
  interactions to permit truly exact comparisons between algorithms.

... and two implementation packages:

* **DecisionDomains.jl** provides implementations of common baseline decision
  making domains for benchmarking.
* **DecisionAlgorithms.jl** provides off-the-shelf implementations of classic
  decision-making algorithm.

If you're contributing to Decisions.jl, or you don't mind some unnecessary
dependencies, the package `Decisions` itself reexports all names from the packages listed
above, so you can just write `using Decisions`.

## Installation
Decisions.jl is not (yet) a registered Julia package. To use it, clone the repo and do:
```
julia --project
] dev path_to_repo
```
(in your desired Julia environment) to add it in development mode. Of course, if you're working
on Decisions.jl itself, no need to do this.

If you'd like a local copy of the Decisions.jl docs for development purposes, do:
```
cd ./docs
julia --project
include("make.jl")
```
