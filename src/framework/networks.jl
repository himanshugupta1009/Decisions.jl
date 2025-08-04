
"""
    DecisionNetwork

Representation of a decision network based on an underlying directed acyclic graph.
"""
struct DecisionNetwork{nodes, dynamic_pairs, ranges, B<:NamedTuple}
    implementation::B

    function DecisionNetwork{N, D, R}(; impls...) where {N, D, R}
        _check_dn_typespace(DecisionNetwork{N, D, R})

        N_standard, D_standard, R_standard = _standardize_dn_type(N, D, R)

        bhv = NamedTuple(impls)
        bhv_as_dists = map(keys(bhv)) do node_id
            K = conditions(DecisionNetwork{N, D, R}, node_id)
            convert(ConditionalDist{K}, bhv[node_id])
        end
        new_bhv = NamedTuple{keys(bhv)}(bhv_as_dists)

        new{N_standard, D_standard, R_standard, typeof(new_bhv)}(new_bhv)
    end
end

function (::Type{Type{DecisionNetwork}})(nodes=nothing, dynamic_pairs=nothing, ranges=nothing)
    n, d, r = _standardize_dn_type(nodes, dynamic_pairs, ranges)
    DecisionNetwork{
        n, 
        isnothing(d) ? D : d, 
        isnothing(r) ? R : r, B
    } where {D, R, B}
end

function DecisionNetwork(nodes, dynamic_pairs=(;), ranges=(;); impls...)
    N_standard, D_standard, R_standard = _standardize_dn_type(nodes, dynamic_pairs, ranges)
    DecisionNetwork{N_standard, D_standard, R_standard}(impls...)
end

function Base.show(io::IO, z::DecisionNetwork)
    names = [node_names(z)...; keys(dynamic_pairs(z))...; keys(ranges(z))...]
    name_algn = maximum(length.(string.(names)))
    print(io, "DecisionNetwork:")
    for (a, b) in pairs(nodes(z))
        padding = repeat(" ", name_algn - length(string(a)))
        dist_type = if (a ∈ keys(implementation(z)))
            Base.typename(typeof(z[a])).wrapper
        else
            "no impl"
        end
        print(io, "\n ", expr(b[2]), padding, " | ", join(string.(expr.(b[1])), ", "), 
            "  (", dist_type, ")")
        
    end
    for (a, b) in pairs(dynamic_pairs(z))
        padding = repeat(" ", name_algn - length(string(b)))
        print(io, "\n ", b, padding, " => ", a)
    end
    for (a, b) in pairs(ranges(z))
        padding = repeat(" ", name_algn - length(string(a)))
        print(io, "\n  ", a, padding, " ∈ ", "1:", b)
    end
end


"""
    nodes(::Type{<:DecisionNetwork})
    nodes(::DecisionNetwork)
    
Give the node definitions of a decision network.
"""
nodes(::DecisionNetwork{N}) where {N} = N
nodes(::Type{<:DecisionNetwork{N}}) where {N} = N


"""
    dynamic_pairs(::Type{<:DecisionNetwork})
    dynamic_pairs(::DecisionNetwork)
    
Give the dynamic pairs for a decision network, mapping current to next iterate node
names.
"""
dynamic_pairs(::DecisionNetwork{N, D}) where {N, D} = D
dynamic_pairs(::Type{<:DecisionNetwork{N, D}}) where {N, D} = D


"""
    ranges(::Type{<:DecisionNetwork})
    ranges(::DecisionNetwork)
    
Give a NamedTuple defining the ranges over which plates in a decision network are defined:
each key is a name of an indexing variables, and each value is the plate size along that
index.
"""
ranges(::DecisionNetwork{N, D, R}) where {N, D, R} = R
ranges(::Type{<:DecisionNetwork{N, D, R}}) where {N, D, R} = R


"""
    implementation(dn::DecisionNetwork)
    
Give the conditional distributions implementing the nodes of a decision network as a
NamedTuple mapping node names to distributions.
"""
implementation(dn::DecisionNetwork) = dn.implementation


"""
    node_names(::Type{<:DecisionNetwork})
    node_names(::DecisionNetwork)

Give the names (as Symbols) of all nodes in a decision network.
"""
node_names(dn::Type{<:DecisionNetwork}) = keys(nodes(dn))
node_names(dn::DecisionNetwork) = keys(nodes(dn))


"""
    conditions(dn::Type{<:DecisionNetwork}, s::Symbol)
    conditions(dn::DecisionNetwork, s::Symbol)

Give the names of the conditioning variables of `s` in `dn` (including any indexing
variables).
"""
function conditions(dn::Type{<:DecisionNetwork}, s::Symbol) 
    c = [
        [name(n) for n in nodes(dn)[s][1]]...;
        indices(nodes(dn)[s][2])...
    ]
    _sorted_tuple(c)
end

function conditions(dn::DecisionNetwork, s::Symbol)
    conditions(dn[s])
end


Base.getindex(dp::DecisionNetwork, rv::Symbol) = implementation(dp)[rv]

Base.keys(dp::DecisionNetwork) = keys(nodes(dp))
Base.keys(dp::Type{<:DecisionNetwork}) = keys(nodes(dp))

Base.iterate(dp::DecisionNetwork) = iterate(keys(nodes(dp)))
Base.iterate(dp::Type{<:DecisionNetwork}) = iterate(keys(nodes(dp)))

Base.iterate(dp::DecisionNetwork, state) = iterate(keys(nodes(dp)), state)
Base.iterate(dp::Type{<:DecisionNetwork}, state) = iterate(keys(nodes(dp)), state)

Base.in(rv::Symbol, dp::DecisionNetwork) = rv ∈ keys(nodes(dp))
Base.in(rv::Symbol, dp::Type{<:DecisionNetwork}) = rv ∈ keys(nodes(dp))


"""
    next(dn::DecisionNetwork, node)
    next(dn::Type{<:DecisionNetwork}, node)

Give the next-step counterpart of `node` in a [type of] decision network `dn`.

`dn` must be a dynamic decision network.

# Examples
```jldoctest 
julia> next(MDP_DN, :s)
:sp
```
"""
next(dn::DecisionNetwork, rv::Symbol) = dynamic_pairs(dn)[rv]
next(dn::Type{<:DecisionNetwork}, rv::Symbol) = dynamic_pairs(dn)[rv]


"""
    prev(dn::DecisionNetwork, node)
    prev(dn::Type{<:DecisionNetwork}, node)

Give the previous-step counterpart of `node` in a [type of] decision network `dn`.

`dn` must be a dynamic decision network.

# Examples
```jldoctest
julia> prev(MDP_DN, :sp)
:s
```
"""
prev(dn::DecisionNetwork, rv::Symbol) = findfirst((i) -> i==rv, dynamic_pairs(dn))
prev(dn::Type{<:DecisionNetwork}, rv::Symbol) = findfirst((i) -> i==rv, dynamic_pairs(dn))


"""
    sample(fn = (_) -> false, dn::DecisionNetwork [, decisions::NamedTuple, input::NamedTuple, output::Tuple])

Sample nodes or plates `out` in decision network `dn` based on input values `in` and node
implementations provided by `decisions` and `dn.implementation`. `fn`, if present, executes upon
each iteration of a (dynamic) network on a NamedTuple mapping the names `out` to their
values, and stops when `fn` returns true.

Returns `Terminal()` if a terminal condition is reached. Otherwise, returns a NamedTuple
mapping the names `out` to their values after the last (or only) iteration. 

Only ancestors of `out`, up to (but not including) the nodes in `in`, are sampled. If any of
the sampled nodes are not implemented by either `dn.implementation` or `decisions`, an error is
thrown. If _both_ `dn.implementation` and `decisions` specify the same node, the implementation in
`decisions` is preferred.
"""
function sample(
    dn::DecisionNetwork, 
    decisions::NamedTuple=(;), 
    input::NamedTuple=(;), 
    output::Union{Tuple{Vararg{Symbol}}, Symbol}=())
    sample(dn, decisions, input, Val(output)) do _
        false # just wait for terminal if fn is not provided
    end
end

function sample(
    fn,
    dn::DecisionNetwork, 
    decisions::NamedTuple=(;), 
    input::NamedTuple=(;), 
    output::Union{Tuple{Vararg{Symbol}}, Symbol, Nothing}=nothing)

    dnout = isnothing(output) ? Val(node_names(dn)) : Val(output)
    sample(fn, dn, decisions, input, dnout)
end

@generated function sample(
    fn,
    dn::DecisionNetwork, 
    decisions::NamedTuple, 
    input::NamedTuple{rvs_in}, 
    _::Val{rvs_out}) where {rvs_out, rvs_in}

    nodes_in_order = _crawl_dn(dn, rvs_in, rvs_out)


    
    # Zeroeth pass: Inputs
    zeroeth_pass_block = quote 
        dists = merge(dn.implementation, decisions) 
    end
    for rv in rvs_in
        sym = Meta.quot(rv)
        push!(zeroeth_pass_block.args, :($rv = input[$sym]))
    end
    for rv in node_names(dn)
        init_stmt = _make_node_initialization(dn, rv)
        if ! isnothing(init_stmt)
            push!(zeroeth_pass_block.args, init_stmt)
        end
    end

    # First pass: intitial defs; can't use rand!
    first_pass_block = quote end
    for rv in nodes_in_order
        push!(first_pass_block.args, _make_node_assignment(dn, rv))
    end
    for (node, node_prime) in pairs(dynamic_pairs(dn))
        if node_prime in nodes_in_order
            push!(first_pass_block.args, :($node = $node_prime))
        end
    end
    push!(first_pass_block.args, quote
        output = NamedTuple{$rvs_out}(($(rvs_out...),))
        fn(output) && return output
    end)

    # Special case: If the network is not dynamic, we just stop here and never loop
    if isempty(dynamic_pairs(dn))
        return quote
            $zeroeth_pass_block
            $first_pass_block
        end
    end
    
    # Second and further pass: rand! available
    second_pass_block = quote end
    for rv in nodes_in_order
        push!(second_pass_block.args, _make_node_assignment(dn, rv; in_place=true))
    end
    for (node, node_prime) in pairs(dynamic_pairs(dn))
        if node_prime in nodes_in_order
            push!(second_pass_block.args, :($node = $node_prime))
        end
    end
    push!(second_pass_block.args, quote
        output = NamedTuple{$rvs_out}(($(rvs_out...),))
        fn(output) && return output
    end)

    quote
        $zeroeth_pass_block
        $first_pass_block
        while true
            $second_pass_block
        end
    end
end