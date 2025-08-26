# Interoperability

## Graphs.jl

`DecisionNetworks` and `DecisionGraphs` can be converted into the Graphs.jl ecosystem. They
are interpreted as `SimpleDiGraph`s, with the nodes in the same order as given by
[`node_names`](@ref).

Beware that this strips several important pieces of information, leaving only the underlying
graph:
* Implementations (conditional distributions) for all nodes
* Node names
* Independence relationships between plates and their conditions


```@docs
as_graphs_jl
```