


"""
    abstract type AddNode{node, in, out} <: DNTransformation

This simple network transformation adds a new chance node `node` with input `in` and adds it
as a conditioning variable for all nodes in `out`.
"""
abstract type AddNode{node, in, out} <: DNTransformation end

"""
    struct InterposeNode{node, in, out} <: DNTransformation

This simple network transformation adds a new chance node `node` with input `in` and adds it
as a conditioning variable for all nodes in `out`. In addition, any nodes which were
previously conditioned on `in` will be conditioned on `node` instead.
"""
abstract type InterposeNode{node, in, out} <: DNTransformation end


"""
    struct Recondition{node, in}
"""



