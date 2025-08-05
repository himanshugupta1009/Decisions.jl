abstract type DNTransformation end


function _default_transform(trans::DNTransformation, dn::DecisionNetwork)
    transform(trans, graph(dn))(; implementation(dn)...)
end

struct Insert <: DNTransformation 
    nodes
    Insert(nodes...) = new(node_def.(nodes) |> Tuple)
end

function transform(trans::Insert, g::DecisionGraph)
    new_nodes = merge(nodes(g), NamedTuple([name(node[2]) => n for n in trans.nodes]))
    DecisionGraph(new_nodes, dynamic_pairs(g), ranges(g))
end

transform(trans::Insert, dn::DecisionNetwork) = _default_transform(trans, dn)

struct Implement{B <: NamedTuple} <: DNTransformation
    implementation::B
    function Implement(; impls...) 
        impl = impls |> NamedTuple
        new{typeof(impl)}(impl)
    end
end

function transform(trans::Implement, dn::DecisionNetwork)
    new_bhv = merge(implementation(dn), trans.implementation)
    graph(dn)(; new_bhv...)
end



struct Unimplement <: DNTransformation
    nodes::Tuple{Vararg{Symbol}}
    Unimplement(node) = new((node,))
    Unimplement(node, nodes...) = new((node, nodes...))
end

function transform(trans::Unimplement, dn::DecisionNetwork)
    keep_nodes = filter(k -> k ∉ trans.nodes, keys(implementation(dn)))
    graph(dn)(; implementation(dn)[keep_nodes]...)
end



struct IndexExplode <: DNTransformation
    idx::Symbol
    sep::Char
    IndexExplode(idx; sep='_') = new(idx, sep)
end

function _get_split_output(n::Indep, idx::Symbol, new_name)
    idx ∈ indices(n) || throw(ArgumentError("Can't split node $(n) along nonexistent index $idx"))
    Indep(new_name, filter(i -> i != idx, indices(n))...; hints(n)...)
end

function _get_split_output(n::JointAndIndep, idx::Symbol, new_name)
    # TODO
end

function _get_split_output(n::Joint, idx::Symbol, new_name)
    throw(ArgumentError("Can't split node $(name(n)); it is jointly sampled"))
end

# corr_output is the output of the node matching name(n)
function _get_split_input(n::Dense, corr_output, i)
    if isnothing(corr_output)
        [n]
    elseif length(corr_output) == 1
        [n]
    else
        [Dense(name(n_i)) for n_i in corr_output]
    end
end

function _get_split_input(n::Parallel, corr_output, i)
    if isnothing(corr_output)
        [n]
    elseif length(corr_output) == 1
        [n]
    else
        new_indices = filter(i -> i != idx, indices(n))
        if isempty(new_indices)
            [Dense(name(corr_output[i]))]
        else
            [Parallel(name(corr_output[i]), new_indices...)]
        end
    end
end

function transform(trans::IndexExplode, dn::DecisionGraph)
    range = 1:ranges(dn)[trans.idx]

    # Degenerate case
    if ranges(dn)[trans.idx] <= 1
        return dn
    end

    output_map = map(nodes(dn)) do node
        if trans.idx ∈ indices(node[2])
            map(range) do i
                new_name = Symbol(name(node[2]), trans.sep, i)
                _get_split_output(node[2], trans.idx, new_name)
            end
        else
            [node[2]]
        end
    end
    new_nodes = []
    for (rv, new_groups_out) in pairs(output_map)
        old_node = nodes(dn)[rv]
        for (i, new_group_out) in enumerate(new_groups_out)
            new_groups_in = []
            for old_group_in in old_node[1]
                rv = name(old_group_in)
                corr_output = (rv ∈ keys(output_map)) ? output_map[rv] : nothing
                append!(new_groups_in, _get_split_input(old_group_in, corr_output, i))
            end
            push!(new_nodes, (new_groups_in |> Tuple) => new_group_out)
        end
    end
    new_ranges = filter(p -> p[1] != trans.idx, pairs(ranges(dn))) |> NamedTuple
    DecisionGraph(new_nodes, dynamic_pairs(dn), new_ranges)
end



# TODO Refactor this; lil low on sleep
# function transform(::Collapse{nodes}, prob::Type{<:DecisionNetwork}) where {nodes}
    # old_structure = structure(prob)
    # old_dynamism = dynamism(prob)
    # new_structure = old_structure
    # new_dynamism = old_structure
    # for node in nodes
    #     new_structure = map(old_structure) do inputs
    #         if node ∈ inputs
    #             new_inputs = (node ∈ keys(old_structure)) ? old_structure[node] : ()
    #             new_inputs = Tuple(union(Set(inputs), Set(new_inputs)))
    #             new_inputs = filter(x -> x != node, new_inputs)
    #         else
    #             inputs
    #         end
    #     end
    #     new_structure = NamedTuple{filter(x -> x != node, keys(new_structure))}(new_structure)
    #     new_dynamism = NamedTuple([p for p in pairs(old_dynamism) if ! (node in p)])
    #     old_structure = new_structure
    #     old_dynamism = new_dynamism
    # end
    # dn = DecisionGraph(new_structure, new_dynamism)
    # return DecisionNetwork{typeof(dn)}
# end

# function transform(t::DNTransformation, u::Union)
#     newtypes = map(Base.uniontypes(u)) do probtype
#         transform(t, probtype)
#     end
#     Union{newtypes...}
# end

# function transform(::Require{nodes}, u::Union) where {nodes}
#     newtypes = filter(Base.uniontypes(u)) do probtype
#         nodes_present = keys(structure(probtype))
#         all([node in nodes_present for node in nodes])
#     end
#     Union{newtypes...}
# end

# # Nodes that already exist in the problem are not changed
# function transform(::Insert{nodes}, prob::Type{<:DecisionNetwork{network}}) where {network, nodes}
#     merged_structure = merge(nodes, structure(prob))
#     dn = DecisionGraph(merged_structure, dynamism(prob))
#     return DecisionNetwork{typeof(dn)}
# end

# # Nodes that aren't already in the problem are ignored
# function transform(::Recondition{nodes}, prob::Type{<:DecisionNetwork{network}}) where {network, nodes}
#     merged_structure = merge(structure(prob), nodes)
#     new_structure = NamedTuple{keys(structure(prob))}(merged_structure)
#     dn = DecisionGraph(new_structure, dynamism(prob))
#     return DecisionNetwork{typeof(dn)}
# end

(t::DNTransformation)(p) = transform(t, p)