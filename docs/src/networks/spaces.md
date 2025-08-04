# Spaces

Spaces represent abstract sets of values represented by a shared Type. They are used to
define supports for `ConditionalDist`s and are in general handy to query for many
decision-making algorithms. 

```@docs
Space
```

## The space interface

Spaces are subtypes of `Space{T}`. The space interface is related to the iteration
interface, but not all spaces can be iterated (some are continuous). 

### Mandatory functions 
- `Base.in(el, s::Space)`: Give whether item `el` is in space `s`.
- `Base.eltype(::Space{T})`: Gives the backing type of the space. Defaults to `T`.

### Optional functions
- `Base.zero(::Space)`: Provide the additive identity element, assuming `+` is defined
  over the space.
- `Base.one(::Space)`: Provide the multiplicative identity element, assuming `*` is defined
  over the space.
- `Base.length(::Space)`: Give the cardinality of a space, if it is finite. Otherwise (and
  by default), return `Inf`. 
- `Base.iterate(::Space [, state])`: For a discrete state, provide iteration support (see
  (Iteration)[https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration])

## Predefined spaces

Some handy `Space` types are named by `Decisions.jl`: 

```@docs
FiniteSpace
RangeSpace
TypeSpace
SingletonSpace
```