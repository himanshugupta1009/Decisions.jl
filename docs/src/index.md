
# Decisions.jl
## What is Decisions.jl?
`Decisions.jl` provides representations of decision problems - like Markov decision processes, Markov games, and many others - as decision networks.

`Decisions.jl` aspires to be:
* **Definitive**. Every decision problem and decision-making setting has a clear definition.
  It's easy to check exactly what problems are supported by a particular solver or compare
  algorithms on even footing.
* **Modular**. Decision networks can be transformed, composed, stacked, and meta-referenced,
  allowing users to create highly expressive problems from a few familiar primitives. 
* **Fast**. Almost all of the overhead computation `Decisions.jl` uses to handle general
  decision problems is compile-time. Once compiled, any type of decision network can be
  efficiently used and sampled.

`Decisions.jl` is a work in progress. Please report issues and feature requests [on Github](https://github.com/JuliaDecisionMaking/Decisions.jl/issues).

## Contents
```@contents
Pages = [
    <!-- "install.md",
    "quickstart.md",
    "defining_problems.md",
    "defining_algorithms.md",
    "defining_objectives.md",
    "valid.md",
    "simulators.md", -->
]
Depth = 2
```