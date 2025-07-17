
"""
    ConditionalDist

A conditional distribution: a stochastic mapping from a set of conditioning variables `K` to
a random variable of type `T`.
"""
abstract type ConditionalDist{K, T} end


Base.eltype(::ConditionalDist{K, T}) where {K, T} = T

"""
    support(cd::ConditionalDist{K, T}; kwargs...)

Give the support `Space` of the distribution when the conditioning variables `K` take on the
values in `kwargs` (if it is present), or a superspace containing it.

If no conditioning variables are provided, give the joint support `Space` over all
conditionings. Optionally, if some, but not all, conditioning variables are provided, the
joint support `Space` over the remaining conditioning variables should be returned.

By default, returns a `TypeSpace{T}`.
"""
function support(cd::ConditionalDist{K, T}; kwargs...) where {K, T}
    TypeSpace{T}()
end

"""
    conditions(cd::ConditionalDist)

Report the names of the conditioning variables of cd as a tuple of Symbols.
"""
conditions(::ConditionalDist{K, T}) where {K, T} = K


"""
    rand!(rng=default_rng(), cd::ConditionalDist{K, T}, dest::T; kwargs...) where {K, T}

Sample from a conditional distribution (in place using `dest` if possible), with the
conditioning variables taking on the values in `kwargs`.

Returns `dest` if in-place modification is successful; otherwise, returns a new instance.
By default, never modifies in place and defers to `rand`.
"""
function rand!(rng::AbstractRNG, cd::ConditionalDist{K, T}, dest::T; kwargs...) where {K, T}
    rand(rng, cd; kwargs...)
end
function rand!(cd::ConditionalDist{K, T}, dest::T; kwargs...) where {K, T}
    rand(Random.default_rng(), cd; kwargs...)
end


"""
    rand(rng=default_rng(), cd::ConditionalDist; kwargs...)

Sample from a conditional distribution, given values of conditioning variables in `kwargs`.

Equivalent to cd(; kwargs...).
"""
Base.rand


"""
    fix(cd::ConditionalDist; fixed_args...)

Fix any number of variables conditioning a distribution to particular values, returning a
new conditional distribution conditioned on the variables that remain.
"""
function fix end


"""
    pdf(cd::ConditionalDist, x; kwargs...)
    pdf(rng, cd::ConditionalDist, x; kwargs...)

Gives the probability or probability density of a random variable distributed according to
`cd` with the value `x`, given values of conditioning variables in `kwargs`.

Equivalent to cd(x; kwargs...)
"""
function pdf end


"""
    logpdf(cd::ConditionalDist, x; kwargs...)
    logpdf(rng, cd::ConditionalDist, x; kwargs...)

Gives the natural logarithm of the probability or probability density of a random variable
distributed according to `cd` with the value `x`, given values of conditioning variables in
`kwargs`.
"""
function logpdf end


"""
    (cd::ConditionalDist)(; rng=default_rng(), kwargs...)

Sample a value from the conditional distribution `cd`, given values of the conditioning
variables given in `kwargs`.

Equivalent to rand(cd::ConditionalDist; kwargs...). This version mimics statistical
notation; i.e., with distribution `Q`, `Q(; a=1, b=2)` is analogous to ``x \\sim Q(\\cdot
\\mid a=1, b=2)``.
"""
function (cd::ConditionalDist{K, T})(
    ; rng=Random.default_rng(), kwargs...
)::Union{T, Terminal} where {K, T}
    rand(rng, cd; kwargs...,)
end

"""
    (cd::ConditionalDist{F, P, S})(; meta=default_meta(), kwargs...) where {F, P, S}

Calculate the probability density of the conditional distribution `cd`, given values of the
conditioning variables given in `kwargs`. 

Equivalent to pdf(cd::ConditionalDist, x; kwargs...). This version mimics statistical
notation; i.e., with distribution `Q`, `Q(x; a=1, b=2)` is analogous to ``Q(x \\mid a=1,
b=2)``.
"""
function (cd::ConditionalDist)(x; kwargs...)::Float64
    pdf(cd, x; kwargs...)
end    

macro ConditionalDist(sample_type, block)

    fns = filter(block.args) do q
        Meta.isexpr(q, :function) || Meta.isexpr(q, :(=))
    end
    fn_defs = map(splitdef, fns)

    conditionals_defd_set = Set{Symbol}()
    for fn_def in fn_defs
        if haskey(fn_def, :kwargs) 
            for kw in fn_def[:kwargs]
                if kw isa Symbol
                    push!(conditionals_defd_set, kw)
                else
                    throw(ParseError("Keyword arguments (conditioning variables) must be \
                    explicit in @ConditionalDist. kwargs... and defaults not allowed."))
                end
            end
        end
    end

    conditionals_defd = Tuple(sort!([conditionals_defd_set...]))
    kwargs = [Expr(:kw, k, :missing) for k in conditionals_defd]

    fns_defd = Symbol[]
    fn_block = quote end
    for fn_def in fn_defs
        fn_def[:body] = fn_def[:body] |> esc
        if haskey(fn_def, :args)
            fn_def[:args] = fn_def[:args] .|> esc
        end
        if haskey(fn_def, :kwargs)
            fn_def[:kwargs] = kwargs .|> esc
        end
        fn = combinedef(fn_def)
        name = fn_def[:name]
        push!(fns_defd, name)
        push!(fn_block.args, fn)
    end

    quote
        let
            $fn_block
            AnonymousDist($conditionals_defd, $sample_type; $(fns_defd...))
        end
    end
end


struct AnonymousDist{K, T, 
        SupportFn <: Union{Function, Missing}, 
        RandFn <: Union{Function, Missing},
        RandBangFn <: Union{Function, Missing},
        FixFn <: Union{Function, Missing},
        PdfFn <: Union{Function, Missing},
        LogPdfFn <: Union{Function, Missing}} <: ConditionalDist{K, T} 
    support::SupportFn
    rand::RandFn
    rand!::RandBangFn
    fix::FixFn
    pdf::PdfFn
    logpdf::LogPdfFn
    function AnonymousDist(
        K::Tuple{Vararg{Symbol}},
        ::Type{T}; 
        support::A = missing,
        rand::B = missing,
        rand!::C = missing,
        fix::D = missing,
        pdf::E = missing,
        logpdf::F = missing,
    ) where {T, A, B, C, D, E, F}
        new{K, T, A, B, C, D, E, F}(support, rand, rand!, fix, pdf, logpdf)
    end
end

function Base.rand(rng::AbstractRNG, cd::AnonymousDist{K, T}; kwargs...
)::Union{T, Terminal} where {K, T}
    cd.rand(rng; kwargs...)
end

function Base.rand(cd::AnonymousDist{K, T}; kwargs...
)::Union{T, Terminal} where {K, T}
    cd.rand(Random.default_rng(); kwargs...)
end

function fix(cd::AnonymousDist; kwargs...) 
    cd.fix(; kwargs...)
end

function logpdf(cd::AnonymousDist, x; kwargs...)
    cd.logpdf(x; kwargs...)
end

function rand!(cd::AnonymousDist{K, T}, dest::T; kwargs...) where {K, T}
    rand!(Random.default_rng(), cd, dest; kwargs...)
end

function rand!(rng::AbstractRNG, cd::AnonymousDist{K, T}, dest::T; kwargs...
)::Union{T, Terminal} where {K, T}
    if ismissing(cd.rand!)
        rand(rng, cd; kwargs...)
    else
        cd.rand!(rng, dest; kwargs...)
    end
end

function pdf(cd::AnonymousDist, x; kwargs...)::Float64
    if ismissing(cd.pdf)
        exp(logpdf(cd, x; kwargs...))
    else
        cd.pdf(x; kwargs...)
    end
end

function support(cd::AnonymousDist{K, T}; kwargs...
) where {K, T}
    if ismissing(cd.support)
        TypeSpace{T}()
    else
        cd.support(; kwargs...)
    end
end


struct UndefinedDist{K, T, F<:Function} <: ConditionalDist{K, T}
    support::F
end

support(cd::UndefinedDist; kwargs...) = cd.support(; kwargs...)


function Base.convert(::Type{ConditionalDist{K, T}}, f::Function) where {K, T}
    AnonymousDist(K, T; rand = f)
end

function Base.convert(::Type{ConditionalDist{K, T}}, s::Space{<:T}) where {K, T}
    f = () -> s
    UndefinedDist{K, T, typeof(f)}(f)
end

function Base.convert(::Type{ConditionalDist{K}}, s::Space{T}) where {K, T}
    f = () -> s
    UndefinedDist{K, T, typeof(f)}(f)
end

@generated function rand_ordered(
    cd::Type{ConditionalDist{cond_vars, T}}, args...;
    rng=default_rng()
) where {cond_vars, T}

    args_labeled = map(1:length(args)) do i
        :($(cond_vars[i])=$(args[i]))
    end
    quote
        rand(rng, cd; $(args_labeled...))
    end
end