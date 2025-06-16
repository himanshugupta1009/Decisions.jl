

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