

"""
    DecisionNetwork

The unified representation of all decision problems. A decision network is a directed
acyclic graph of `DNNode`s, each of which is a mapping from a set of conditioning variables 
to a single output variable. 

There is support for:
    `iterate` (gives all pairs of (output var, distribution))
    `index(::DecisionNetwork, in::Symbol)` (gives conditional distribution of `in`)
    `in(idx::Symbol, ::DecisionNetwork)` (gives whether there is a node labeled `idx`,
    including one implied by dynamic structure)

Dynamic decision networks are characterized as finite decision networks with nodes
that have a step-correspondence; that is, some outputs of the decision network are inputs
to an identical decision network at the next step. The convenience functions 

    `next(::DecisionNetwork, node_name)`
    `prev(::DecisionNetwork, node_name)`
    
map current nodes to their future-step name and vice versa; e.g., next(ddn, :s) = :s_prime
and next(ddn, :s_prime) = :s.
"""
struct DecisionNetwork
    forward_mappings::NamedTuple
    reverse_mappings::NamedTuple
    graph::NamedTuple

    function DecisionNetwork(forward_mappings; nodes...) 
        fw = forward_mappings
        new(fw, NamedTuple{values(fw)}(keys(fw)), NamedTuple(nodes))
    end

    DecisionNetwork(; nodes...) = new((;), NamedTuple(nodes))
end

Base.getindex(dn::DecisionNetwork, idx::Symbol) = dn.graph[idx]
Base.iterate(n::DecisionNetwork) = iterate(pairs(n.graph))
Base.iterate(n::DecisionNetwork, state) = iterate(pairs(n.graph), state)
function Base.in(idx::Symbol, dn::DecisionNetwork)
    (idx in keys(dn.reverse_mappings) || idx in keys(dn.forward_mappings) || idx in keys(dn.graph))
end

next(dn::DecisionNetwork, idx::Symbol) = dn.forward_mappings[idx]
prev(dn::DecisionNetwork, idx::Symbol) = dn.reverse_mappings[idx]


"""
    DecisionProblem

Abstract base class for all decision problems. 
    
Note the distinction between `DecisionProblem` and `DecisionNetwork`. Decision problems can
be defined in any way (i.e., the classic tuple definition of MDPs). However, abstractly,
decision problems correspond to a class of decision networks: for instance, MDPs correspond
to the dynamic decision networks that have a state, action, and reward node in a Markovian
setup.
"""
abstract type DecisionProblem end

"""
    structure(::Type{DecisionProblem})
    structure(p::DecisionProblem)

All types of decision problems (MDPs, POMDPs, POMGs, etc.) are associated with an
underlying decision network. `structure` gives this decision network. 

As a convenience, calling `structure` on an instance of a decision problem returns the 
structure for its decision problem type.

Note that some definitions of decision problems contain ambiguities (for instance,
the reward in an MDP might be defined on the state, the state and action, or the state,
action, and next state). A particular type of decision problem can only admit one structure,
so in these cases a type parameter is used to disambiguate.
"""
function structure(::Type{DecisionProblem}) end

@generated function structure(p::DecisionProblem)
    # pseudoconstant for any particular type; not an expression.
    structure(p)
end
# TODO: `structure` is not extensible when defined in this way due to how 
#   generated functions work (can only see functions defined earlier, with an
#   exception for functions defined in its module.)
# It's substantially faster than using a `typeof`, though.


"""
    structure(::Type{DecisionProblem})
    structure(p::DecisionProblem)

All types of decision problems (MDPs, POMDPs, POMGs, etc.) are associated with an
underlying decision network. `structure` gives this decision network. 

As a convenience, calling `structure` on an instance of a decision problem returns the 
structure for its decision problem type.

Note that some definitions of decision problems contain ambiguities (for instance,
the reward in an MDP might be defined on the state, the state and action, or the state,
action, and next state). 
"""

"""
    behavior(p::DecisionProblem, idx)

Gives the conditional distribution corresponding to the node named `idx` for `p`.

Specific _instances_ of decision problems can carry implementations of conditional
distributions for nodes in the network. `behavior` gives these known distributions, if
they exist, as a named tuple from node names (as symbols, matching those given by 
`structure`) to `ConditionalDist`s.

Not all nodes need to have a behavior provided through through `behavior`.
Those that do not are assumed to be decision nodes.
"""
function behavior(::DecisionProblem, idx) end

struct DNOut{ids} end
DNOut(name::Symbol) = DNOut{name}()
DNOut(names...) = DNOut{names}()
DNOut(names::Tuple) = DNOut{names}()

@generated function sample(
    problem::DecisionProblem,
    decisions,
    in::NamedTuple{ids_in},
    _::DNOut{ids_out}) where {ids_out, ids_in}

    dn = structure(problem)

    # TODO: Variables automatically named for their DN nodes can conflict with other names

    expr = quote 
        node_defs = merge(behavior(problem), decisions) 
    end

    for id in ids_in
        sym = Expr(:quote, id)
        block = quote
            $id = in[$sym]
        end
        append!(expr.args, block.args)
    end

    nodes_in_order = _crawl_graph(dn, ids_in, ids_out)
    println([(q, _order(dn, q)) for q in nodes_in_order])

    for id in nodes_in_order
        sym = Expr(:quote, id)
        cond_vars = dn[id]
        block = quote
            $id = node_defs[$sym]($(cond_vars...))
        end
        append!(expr.args, block.args)
    end

    return_block = quote
        return NamedTuple{$ids_out}($(ids_out...))
    end
    append!(expr.args, return_block.args)

    println(expr)
    return expr
end

function sample(prob::DecisionProblem, decisions::NamedTuple, in::NamedTuple, out::Tuple)
    sample(prob, decisions, in, DNOut{out}())
end

function sample(prob::DecisionProblem, decisions::NamedTuple, in::NamedTuple, out::Symbol)
    sample(prob, decisions, in, DNOut{(out,)}())
end

function _crawl_graph(dn, in, out)
    # We don't want to evaluate any nodes we don't have to: only the ones between the inputs
    # and the outputs. Also, want to do them in order.
    # TODO: This is terribly inefficient; O(n^2). Surely there's a better way.
    # This is a rigorous graph theory problem but it's not one I know the name of,
    #   and it's not worth any more time figuring it out
    
    nodes = Symbol[]
    inter_nodes = Symbol[out...]
    while ! isempty(inter_nodes)
        node = popfirst!(inter_nodes)
        if ! ((node ∈ in) || (node ∈ nodes))
            push!(nodes, node)
            try
                append!(inter_nodes, dn[node])
            catch
                throw(ArgumentError("Initial value required for node :$(node)"))
            end
        end
    end

    sort!(nodes; by=(n) -> _order(dn, n))
end

function _order(dn, node)
    # welcome to cs 101 lol    
    if ((! (node ∈ keys(dn.graph))) || isempty(dn[node]))
        return 0
    end
    1 + maximum([_order(dn, c) for c in dn[node]])
end