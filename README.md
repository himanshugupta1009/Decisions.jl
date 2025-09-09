# Decisions.jl
## Definitive decision problems in Julia

> [!WARNING] 
> Decisions.jl is under active development. It is currently in **silent beta**:
> publically accessible but not promoted or registered. Expect bugs and breaking changes. 

Decisions.jl is an ecosystem for canonical representations of decision problems, from the
most basic Markov decision processes, to rich and expressive multi-agent, semi-Markov,
multi-objective extensions, unifying decision-, control-, and game-theoretic models.

Decisions.jl is currently in **silent beta**. The package is publically available, but has
yet to be announced.

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
