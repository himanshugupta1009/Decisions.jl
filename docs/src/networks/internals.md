# Advanced: Internals

## More structural `ConditionalDist`s
There are some structural `ConditionalDist`s that are primarily used in transformations.
These distributions act as wrappers around others, which can cause a significant performance
drop as transformations are aggregated. As such, they are considered unstable and are likely
to be subject to significant additional refactoring.

```@docs
Decisions.RenamedDist
Decisions.MergedDist
```
