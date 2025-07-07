

"""
    NO_PDF

Placeholder used for generative-only distributions; that is, distributions where the PDF is
not known.
"""
const NO_PDF = (x; kwargs...) ->
    throw(ArgumentError("This distribution is generative only (no PDF defined)."))


"""
    ConditionalDist{F<:Function, P<:Function, S<:Space}

A conditional distribution: a random mapping from a set of conditioning variables to the
value of a random variable.

Conditional distributions have generative function `gen(; <conditioning variables...>)` and
(optional) probability density function PDF `pdf(<value of RV>; <conditioning
variables...>)` mimicking statistical notation with the semicolon replacing the
conditioning bar. They also include their own `support` - that is, the `Space` of possible
outputs.
"""


struct ConditionalDist{T, F<:Function, P<:Function, S<:Space{T}}
    gen::F
    pdf::P
    support::S
    is_deterministic::Boolean
end

function ConditionalDist(gen, pdf, ::Type{T}, is_deterministic) where {T}
    ConditionalDist(gen, pdf, TypeSpace{T}, is_deterministic)
end

"""
    ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, pdf, support::Space)
    ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, support::Space)

Construct a conditional distribution from a generative function without keyword arguments.

The provided names in `kws` are associated with the (non-keyword) arguments of `fn`, in
order. This allows for `do` block syntax to define conditional distributions. If a PDF is
provided, its arguments for `pdf` are assumed to be shifted right by one with respect `kws`:
the leftmost argument is assumed to be the value of the random variable.

The special `meta` keyword may be included or omitted.
"""
# TODO: Benchmark this wrapper; possibly it can be moved to type space
function ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, pdf, support::Space{T}; 
    is_deterministic=false) where T
    kw_gen = function(; kwargs...)
        fn(kwargs[kws]...)
    end
    kw_pdf = function(x ; kwargs...)
        pdf(x, kwargs[kws]...)
    end
    ConditionalDist{T}(kw_gen, kw_pdf, support; is_deterministic)
end

function ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, support::Space{T}; 
    is_deterministic=false) where T
    kw_gen = function(; kwargs...)
        fn(kwargs[kws]...)
    end
    ConditionalDist{T}(kw_gen, NO_PDF, support; is_deterministic)
end

"""
    ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, pdf, support::Space)
    ConditionalDist(fn, kws::Tuple{Vararg{Symbol}}, support::Space)

Construct a conditional distribution without a PDF (defaulting to `NO_PDF`).
"""
function ConditionalDist(fn, support::Space; is_deterministic=false)
    ConditionalDist(fn, NO_PDF, support; is_deterministic)
end

"""
    (cd::ConditionalDist{F, P, S})(; meta=default_meta(), kwargs...) where {F, P, S}

Sample a value from the conditional distribution `cd`, given values of the conditioning
variables given in `kwargs`.

The special argument `meta` carries meta-information used for sampling.
"""
function (cd::ConditionalDist{T, F, P, S})(; meta=default_meta(), kwargs...)::Union{T, Terminal} where {T, F, P, S}
    cd.gen(; kwargs..., meta)
end
"""
    (cd::ConditionalDist{F, P, S})(; meta=default_meta(), kwargs...) where {F, P, S}

Calculate the probability density of the conditional distribution `cd`, given values of the
conditioning variables given in `kwargs`. 

The special argument `meta` carries meta-information used for sampling.
"""
function (cd::ConditionalDist)(x; meta=default_meta(), kwargs...)::Float64
    cd.pdf(x; kwargs..., meta)
end    

"""
    Base.rand(rng=default_rng(), cd::ConditionalDist; kwargs...)

Sample from a conditional distribution, conditioned on `kwargs`.

Equivalent to `(cd::ConditionalDist)(; kwargs...)`.
"""
function Base.rand(rng, cd::ConditionalDist; kwargs...)
    meta = (; rng)
    cd(; kwargs..., meta)
end

function Base.rand(cd::ConditionalDist; kwargs...)
    cd(; kwargs..., meta)
end
"""
    default_meta()

Generate default meta-information for a conditional distribution.
"""
default_meta() = (; rng=Random.default_rng())


"""
    fix(cd::ConditionalDist{F, P, S}, support::S; fixed_args...)
    fix(cd::ConditionalDist; fixed_args...)

Fix any number of variables conditioning a distribution to particular values, returning a
new conditional distribution conditioned on the variables that remain.

If `support` is provided, update the support of the new distribution accordingly.
"""
function fix(cd::ConditionalDist{F, P, S}, support::S; fixed_args...) where {F, P, S}
    reconditioned_gen = (; kwargs...) -> cd.f(; kwargs..., fixed_args...)
    reconditioned_pdf = (x; kwargs...) -> cd.f(x; kwargs..., fixed_args...)
    ConditionalDist{F, P, S}(reconditioned_gen, reconditioned_pdf, support)
end

function fix(cd::ConditionalDist; fixed_args...)
    fix(cd, cd.support; fixed_args...)
end

function UniformDist(support::FiniteSpace{T}) where {T}
    f = (; kwargs...) -> rand(meta.rng, support.elements)
    d = (x ; kwargs...) -> 1 / length(support)

    ConditionalDist(f,d, support)
end


function EmptyDist(support)
    f = (; meta) -> Terminal()
    ConditionalDist(f, NO_PDF, support)
end

function DeterministicDist(args...)
    ConditionalDist(args...; is_deterministic=true)
end