
struct ConditionalDist{I} 
    f
    has_pdf
end

function ConditionalDist(f::Function; check_consistent_input=true)
    kws = Base.kwarg_decl(methods(f)[1])
    if check_consistent_input
        for method in methods(f)[2:end]
            if Base.kwarg_decl(method) != kws
                throw(ArgumentError("Ambiguous function $(f) for distribution: \
                multiple possible keyword sets"))
            end 
        end
    end
    kws = Tuple(kws)

    ConditionalDist{kws}(f, hasmethod(f, (Any,), kws))
end

function (c::ConditionalDist{I})(; kwargs...) where I
    c.f(; kwargs...)
end

function (c::ConditionalDist{I})(x; kwargs...) where I
    if c.has_pdf 
        c.f(x; kwargs...)
    else
        throw(ArgumentError("This distribution has no defined density function"))
    end
end

inputs(c::ConditionalDist{I}) where I = I 