# Advanced: Internals

## More structural `ConditionalDist`s
There are some structural `ConditionalDist`s that are primarily used in transformations.
These distributions act as wrappers around others, which can cause a significant performance
drop as transformations are aggregated. As such, they are considered unstable and are likely
to be subject to significant additional refactoring.

```@docs
DecisionNetworks.RenamedDist
DecisionNetworks.MergedDist
```


## Tools for traversing DecisionNetworks
These are the tools used at compile time to generate fast sampling code and nonambiguous
networks.

```@docs
DecisionNetworks._standardize_dn_type
DecisionNetworks._crawl_dn
DecisionNetworks._node_order
DecisionNetworks._make_node_assignment
DecisionNetworks._make_node_initialization
```

## Utilities

```@docs
DecisionNetworks._sortkeys
DecisionNetworks._sorted_tuple

```