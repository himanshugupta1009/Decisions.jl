
"""
    DecisionGraph{structure, dynamism, constituents, ranges}

Representation of a directed, acyclic, possibly repeated graph that underlies a (dynamic)
decision network.

`structure` is a NamedTuple mapping nodes to their inputs (tuples of symbols). Each node
represents either a single random variable, or a plate of random variables. `dynamism` is a
named tuple mapping nodes to their next-iteration counterparts to allow for infinitely
repeated DAGs (which underlie _dynamic_ decision networks). `constituents` defines names for
particular slices of plates, and is a named tuple mapping names to (plate_id, idx_id...)
tuples. `ranges` is a named tuple that maps symbols representing indices into single-integer
lengths of the corresponding axes.

"""
struct DecisionGraph{structure, dynamism, constituents, ranges}
    function DecisionGraph(structure, dynamism, constituents, ranges)
        _get_dg_type(structure, dynamism, constituents, ranges)()
    end
end

function _get_dg_type(structure, dynamism, constituents, ranges)
    # Decision networks should be order invariant wrt their nodes
    #   We need a wrapper with an inner constructor to enforce that
    #   (I'd use Set but ! isbitstype(Set))
    # TODO: Ideally we would also optionally check for cycles here

    sorted_structure = _sortkeys(map(structure) do vars
        # TODO: We want an immutable type here but we also want to be able to sort
        #   Probably there is a more efficient way to do this
        Tuple(sort([vars...]))
    end)

    DecisionGraph{
        sorted_structure,        # values are sorted tuples
        _sortkeys(dynamism),     # values are single symbols
        _sortkeys(constituents), # values are tuples, but order matters
        _sortkeys(ranges)        # values are single integers
    }
end

function _get_dg_type(structure, dynamism)
    sorted_structure = _sortkeys(map(structure) do vars
        Tuple(sort([vars...]))
    end)

    DecisionGraph{
        sorted_structure,    # values are sorted tuples
        _sortkeys(dynamism), # values are single symbols 
        C, R                 # plate related parameters left unknown
    } where {C, R}
end

@generated _sortkeys(nt::NamedTuple{KS}) where {KS} =
    :( NamedTuple{$(Tuple(sort(collect(KS))))}(nt) )


"""
    DecisionNetwork{dn::DecisionGraph{structure, dynamism, constituents, ranges}} 
    where {structure, dynamism, constituents, ranges}

Representation of a decision network based on an underlying directed acyclic graph.

Every type of decision problem is described by a concrete decision network (DN) or dynamic
decision network (DDN). A decision network is a directed acyclic graph where each node is a
conditional distribution. `structure` gives this graph as a named tuple mapping symbols
(nodes) to tuples of symbols (conditioning variables). Not all conditioning variables need
be defined as nodes in the structure; those that are not are interpreted as inputs.

If `dynamism` is a non-empty named tuple, a _dynamic_ decision network is specified.
`dynamism` maps node names to their next-step counterparts and vice versa (for instance,
`:s` <=> `:sp` in an MDP.) In this case, `structure` gives the DN for a single step.

`constituents` and `ranges` are used to specify plates. See [DecisionGraph](@ref).

A concrete decision problem provides the conditional distributions for any of the nodes (or
none of them) in the named tuple `behavior`. Nodes not in `behavior` have distributions
specified by the agent; that is, they are action nodes.

For convenience, functions querying a problem's structure (not the underlying distributions)
accept both `DecisionNetwork{...}` and `Type{DecisionNetwork{...}}`

# Supported Base functions
 - `keys`: Give all node names defined in the problem.
 - `iterate`: Iterate through node names defined in the problem.
 - `getindex(::DecisionNetwork, in::Symbol)`: Give conditional distribution of `in`, if one
   is specified.
 - `in(idx::Symbol, dn::DecisionNetwork)`: Give whether there is a variable labeled `idx` in
    `dn`.
"""
struct DecisionNetwork{graph<:DecisionGraph, B<:NamedTuple}
    behavior::B

    function DecisionNetwork{graph}(bhv) where {graph<:DecisionGraph{structure, dynamism}} where {structure, dynamism}
        bhv_as_dists = map(keys(bhv)) do node_id
            convert(ConditionalDist{structure[node_id]}, bhv[node_id])
        end
        new_bhv = NamedTuple{keys(bhv)}(bhv_as_dists)
        new{graph, typeof(new_bhv)}(new_bhv)
    end
end

function DecisionNetwork{graph}(; nodes...) where graph
    DecisionNetwork{graph}(NamedTuple(nodes))
end

"""
    structure(::Type{DecisionNetwork})
    structure(::DecisionNetwork)
    
Give the graph structure of a decision network.
"""
structure(::DecisionNetwork{<:DecisionGraph{S}}) where {S} = S
structure(::Type{<:DecisionNetwork{<:DecisionGraph{S}}}) where {S} = S


"""
    dynamism(::Type{DecisionNetwork})
    dynamism(::DecisionNetwork)
    
Give the dynamic pairs for a decision network (which maps current to next iterate node
names).
"""
dynamism(::DecisionNetwork{<:DecisionGraph{S, D}}) where {S, D} = D
dynamism(::Type{<:DecisionNetwork{<:DecisionGraph{S, D}}}) where {S, D} = D


"""
    constituents(::Type{DecisionNetwork})
    constituents(::DecisionNetwork)
    
Give a NamedTuple defining the plate constituents of a decision network: the keys are
constituent names, and the values are (platename, indices...) tuples indicating the plate
each constituent belongs to and the indices into that plate that produce the constituent.
"""
constituents(::DecisionNetwork{<:DecisionGraph{S, D, C}}) where {S, D, C} = C
constituents(::Type{<:DecisionNetwork{<:DecisionGraph{S, D, C}}}) where {S, D, C} = C


"""
    ranges(::Type{DecisionNetwork})
    ranges(::DecisionNetwork)
    
Give a NamedTuple defining the ranges over which plates in a decision network are defined:
the keys are names of indexing variables for the plates, and the values is the size of the
plate along that variable.
"""
ranges(::DecisionNetwork{<:DecisionGraph{S, D, C, R}}) where {S, D, C, R} = R
ranges(::Type{<:DecisionNetwork{<:DecisionGraph{S, D, C, R}}}) where {S, D, C, R} = R


"""
    behavior(::DecisionNetwork)
    
Give the conditional distributions implementing the nodes of a decision network.
"""
behavior(dn::DecisionNetwork) = dn.behavior

"""
    graph(::DecisionNetwork)

Get the underlying graph for a decision network.
"""
graph(::DecisionNetwork{G}) where {G} = G
graph(::Type{<: DecisionNetwork{G}}) where {G} = G


Base.getindex(dp::DecisionNetwork, idx::Symbol) = behavior(dp)[idx]

Base.keys(dp::DecisionNetwork) = keys(structure(dp))
Base.keys(dp::Type{<:DecisionNetwork}) = keys(structure(dp))

Base.iterate(dp::DecisionNetwork) = iterate(pairs(structure(dp)))
Base.iterate(dp::Type{<:DecisionNetwork}) = iterate(pairs(structure(dp)))

Base.iterate(dp::DecisionNetwork, state) = iterate(pairs(structure(dp)), state)
Base.iterate(dp::Type{<:DecisionNetwork}, state) = iterate(pairs(structure(dp)), state)

# We have to check if `idx` is a conditioning variable for any node because it might
# not itself be a node. This happens for DDNs: e.g., in an MDP, :s doesn't have its own
# node, so without this check we unintuitively have !(:s ∈ MDP)
function Base.in(idx::Symbol, dp::DecisionNetwork)
    S = structure(dp)
    (idx in keys(S) || any(map((cvs) -> idx ∈ cvs, S)))
end

function Base.in(idx::Symbol, dp::Type{<:DecisionNetwork})
    S = structure(dp)
    (idx in keys(S) || any(map((cvs) -> idx ∈ cvs, S)))
end


"""
    `next(dn::DecisionNetwork, node)`
    `next(dn::Type{DecisionNetwork{_, dynamism}}, node)``

Give the next-step counterpart of `node` in a [type of] decision network `dn`.

`dn` must be a dynamic decision network.

# Examples
```jldoctest
julia> next(MDP, :s)
:sp
```
"""
next(dn::DecisionNetwork, idx::Symbol) = dynamism(dn)[idx]
next(dn::Type{<:DecisionNetwork}, idx::Symbol) = dynamism(dn)[idx]


"""
    `prev(dn::DecisionNetwork, node)`
    `prev(dn::Type{DecisionNetwork{_, dynamism}}, node)``

Give the previous-step counterpart of `node` in a [type of] decision network `dn`.

`dn` must be a dynamic decision network.

# Examples
```jldoctest
julia> prev(MDP, :sp)
:s
```
"""
prev(dn::DecisionNetwork, idx::Symbol) = findfirst((i) -> i==idx, dynamism(dn))
prev(dn::Type{<:DecisionNetwork}, idx::Symbol) = findfirst((i) -> i==idx, dynamism(dn))


# TODO: Examples for `structure` and `dynamism` - need to make sure they are consistent
# # Examples
# ```jldoctest
# julia> dynamism(MDP)
# (; s=:sp, sp=:s, m=:mp, mp=:m)



# Convenience wrapper type for tuple of symbols
struct DNOut{ids} end
DNOut(name::Symbol) = DNOut{(name,)}()
DNOut(names...) = DNOut{names}()
DNOut(names::Tuple) = DNOut{names}()

"""
    sample(dn::DecisionNetwork [, decisions::NamedTuple, input::NamedTuple, output::Tuple])

Sample nodes or plates `out` in dynamic decision network `dn` based on input values `in` and
node implementations provided by `decisions` and `dn.behavior`. Return `Terminal()` if a
terminal condition is reached.

Only ancestors of `out`, up to (but not including) the nodes in `in`, are sampled. If any of
the sampled nodes are not implemented by either `dn.behavior` or `decisions`, an error is
thrown. If _both_ `dn.behavior` and `decisions` specify the same node, the implementation in
`decisions` is preferred.
"""
function sample(
    dn::DecisionNetwork, 
    decisions::NamedTuple=(;), 
    input::NamedTuple=(;), 
    output::Union{Tuple{Vararg{Symbol}}, Symbol}=())
    simulate(dn, decisions, input, DNOut{output}()) do _
        true # always terminate at the first iteration
    end
end

"""
    simulate(fn, dn::DecisionNetwork [, decisions::NamedTuple, input::NamedTuple, output::Tuple])

Step through iterates of dynamic decision network `dn` based on input values `in` and
distributions provided by `decisions` and `dn.behavior`, executing `fn` each iterate on the
values of `output` nodes/plates, until Terminal() is sampled from any node, `fn` returns
`false`, or (in a non-dynamic network) there are no more nodes to sample.
"""
function simulate(
    fn,
    problem::DecisionNetwork, 
    decisions::NamedTuple=(;), 
    input::NamedTuple=(;), 
    output::Union{Tuple{Vararg{Symbol}}, Symbol, Nothing}=nothing)

    dnout = if isnothing(output)
        DNOut{_get_plates(problem)}()
    else
        DNOut{output}()
    end

    simulate(fn, problem, decisions, input, dnout)
end

@generated function simulate(
    fn,
    dn::DecisionNetwork, 
    decisions::NamedTuple, 
    input::NamedTuple{ids_in}, 
    _::DNOut{ids_out}) where {ids_out, ids_in}

    dn_structure    = structure(dn)
    dn_dynamism     = dynamism(dn)
    dn_constituents = constituents(dn)
    dn_ranges       = ranges(dn)

    nodes_in_order = _crawl_graph(
        dn_structure, dn_constituents,
        [ids_in...; keys(dn_ranges)...], 
        ids_out
    )

    # Zeroeth pass: Inputs
    zeroeth_pass_block = quote 
        node_defs = merge(dn.behavior, decisions) 
    end
    for id in ids_in
        sym = Meta.quot(id)
        push!(zeroeth_pass_block.args, :($id = input[$sym]))
    end
    append!(zeroeth_pass_block.args,_get_plate_defs(dn))

    # First pass: intitial defs; can't use rand!
    first_pass_block = quote end
    for id in nodes_in_order
        push!(first_pass_block.args, _make_update_step(id, dn))
    end
    for (node, node_prime) in pairs(dn_dynamism)
        push!(first_pass_block.args, :($node = $node_prime))
    end
    push!(first_pass_block.args, quote
        output = NamedTuple{$ids_out}(($(ids_out...),))
        fn(output) && return output
    end)

    # Special case: If the network is not dynamic, we just stop here and never loop
    if isempty(dn_dynamism)
        return quote
            $zeroeth_pass_block
            $first_pass_block
        end
    end
    
    # Second and further pass: rand! available
    second_pass_block = quote end
    for id in nodes_in_order
        push!(second_pass_block.args, _make_update_step(id, dn; in_place=true))
    end
    for (node, node_prime) in pairs(dn_dynamism)
        push!(second_pass_block.args, :($node = $node_prime))
    end
    push!(second_pass_block.args, quote
        output = NamedTuple{$ids_out}(($(ids_out...),))
        fn(output) && return output
    end)

    q = quote
        $zeroeth_pass_block
        $first_pass_block
        while true
            $second_pass_block
        end
    end
    println(q)
    q
end

"""
    struct Terminal end
    
Unique value representing the output of a decision node as being terminal or otherwise
exceptional. 
"""
struct Terminal end

isterminal(::Terminal) = true
isterminal(::Any) = false