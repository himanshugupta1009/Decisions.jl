# Advanced: Performance

## Performance tips for `ConditionalDist`s

!!! todo
    
    Need to write some tests to confirm this behavior.

Sampling a distribution often occurs in a very tight loop, making performance within the
distribution very important. Aside from the general [performance tips for Julia
code](https://docs.julialang.org/en/v1/manual/performance-tips), here are a few specific
ways to optimize code using `ConditionalDist`s:

### Prefer `rand!` over `rand`

When it's possible to sample a distribution in place, doing so can reduce unnecessary
allocations and therefore speed up your code.

### Prefer `logpdf` over `pdf`

For the usual numerical reasons, it's generally preferable to use `logpdf` where possible;
`pdf` simply defaults to `exp(logpdf(...))`. When it really is more efficient to calculate
the PDF, `pdf` (and `logpdf`) can be specialized to change this behavior.

### Provide a concrete sample type

If the `eltype` of a `ConditionalDist` is concrete, it is possible to generate very
performant, potentially stack-allocated sampling code. Using `Any` or other abstract types
_will_ work and can be useful for prototyping, but comes at a performance cost. 

### Use @ConditionalDist wisely

When using @ConditionalDist, be aware that there may be subtle performance impacts,
[particularly with regards to
closures](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-captured). 
If in doubt in a performance-critical setting, use an explicitly defined distribution.

