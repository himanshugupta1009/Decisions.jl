```@setup trans
using DecisionNetworks
```

# Transformations

One of Decisions.jl's greatest strengths is its ability to flexibly and precisely modify
decision networks. Decision problems can be changed from multiple to single agents, full to
partial observability, and all sorts of other changes in one line by transforming the
underlying decision network.

Such transformations are subtypes of the `DNTransformation` base class. Transformations can
affect only implemented `DecisionNetwork`s, only their `DecisionGraph`s, or both. 

```@docs
DNTransformation
transform
```

## Provided transformations

```@docs
Insert
Implement
Unimplement
Recondition
IndexExplode
MergeForward
Rename
```

!!! todo

    Many useful transformations are still missing from DecisionNetworks.jl, and those that
    do exist have yet to be thoroughly tested.


## Examples

### Transforming a Markov game into an MDP
One might want to interpret a Markov game as an ordinary MDP by assuming some opponent
behavior. This is a matter of a few transformations.

We'll start with some Markov game implemented with arbitrary distributions (passed in as
`Function`s and automatically converted). Note that we specify the `ranges` for the plates
of the Markov game - that is, the number of agents - in the type parameter, so this is a two
player game. 

```@example trans
my_mg = MG_DN{(; i=2)}(;
    sp = (rng; a, s) -> "sp for actions $a",
    r = (rng; a, s, sp, i) -> "r$i" 
)
```

We can turn all the agent-indexed plates into individual nodes with `IndexExplode` (in this
case there are only two apiece for `a` and `r`).

```@example trans
my_dn = my_mg |> IndexExplode(:i) 
```

This automatically edits the distributions for `sp` and `r` to fit the new arrangement. Now,
we can provide an implementation for only the opponent policy:

```@example trans
my_dn = my_dn |> Implement(;
    a_2 = (rng; kwargs...) -> "a2"
)
```

In doing this, we're treating the opponent as part of the model. We can `MergeForward` the
opponent nodes into the state transition (and get rid of the irrelevant opponent reward):

```@example trans
my_dn = my_dn |> MergeForward(:r_2, :a_2)
```

You may notice that this is not technically a `MDP_DN`: it has nodes `a_1` and `r_1`, rather
than `a` and `r`. So, finally, we egoistically rename those nodes:

```@example trans
my_mdp = my_dn|> Rename(; a_1=:a, r_1=:r)
```

As you can see, this network is indeed the DN for an MDP now.

### Transforming a POMDP into an MDP

It is possible for transformations to be lossy: the output network or graph is not
necessarily equivalent to the input. This can cause some unexpected behavior. As an example,
let's strip the partial observability from a POMDP.

For variety, we'll operate on the `DecisionGraph` `POMDP_DN` rather than the `DecisionNetwork` `POMDP_DN(...)`. 

```@example trans
node_names(POMDP_DN)
```

Notice that we include the ["memory nodes"](@ref) `m` and `mp` by default here. One might
expect to be able to simply `MergeForward` the memory and observation nodes, removing all
the partial-observability machinery, to reach a model where `a` is directly conditioned on
`s`. However, in reality, we see something slightly different:

```@example trans
My_DN = POMDP_DN |> MergeForward(:m, :mp, :o)
conditions(My_DN, :a)
```

Instead of being conditioned on `s`, `a` is conditioned on nothing at all! This is because
`m` is an input to the network (except in iterates past the first, where it gets the output
of `mp`), and therefore unconditioned. When it is merged into `a`, `a` then has no
conditions either.

We can recover the MDP structure by explicitly conditioning the `a` node:

```@example trans
My_DN = POMDP_DN |> MergeForward(:m, :mp, :o) |> Recondition(; a=(Dense(:s),))
conditions(My_DN, :a)
```

Finally, let's make a `DecisionNetwork` with the new `DecisionGraph` and make sure it's
actually an MDP:
```@example trans
My_DN()
```

