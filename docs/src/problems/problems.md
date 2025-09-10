# Decision problems

Decision problems join an _objective_ (that is, a `DecisionMetric`) with a _model_ (that is,
a `DecisionNetwork`). They also specify initial distributions for random variables in the
problem.

Note the distinction between a decision problem (`MDP(...)`) and the decision network
underlying that problem (`MDP_DN(...)`). 

```@docs
DecisionProblem
objective
model
initial
```

## Named decision problems
Like `DecisionNetworks`, Decisions.jl provides explicit names for some common decision
problems:

```@docs
MDP
POMDP
MG
```

## Transforming decision problems
By default, calling a transformation on a `DecisionProblem` will transform the underlying
`DecisionNetwork` (while leaving the objective unchanged).