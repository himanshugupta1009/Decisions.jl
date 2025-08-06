# What needs to be checked about a DG/DN when it is constructed?
# * No cycles
# * Type parameters must be NamedTuples with specific types of values. 
# * DG type parameters are ordered
# * No repeated names
# * Conditions on dists and on DG must match
# * Conditioning groups all come from actual plates

# TODO: Check named indices in nodes are actually included in `ranges`

function _check_dn_typespace(dn)
    _check_tparam(nodes(dn), Pair{<:Tuple{Vararg{ConditioningGroup}}, <:Plate}, "nodes")
    _check_tparam(dynamic_pairs(dn), Symbol, "dynamic_pairs")
    _check_tparam(ranges(dn), Int, "ranges")

    _check_repeated_names(dn)
    _check_acyclic(dn)
    
end

function _check_acyclic(dn)
    orders = [_node_order(dn, n) for n in node_names(dn)]
    if Inf ∈ orders
        throw(ArgumentError("This DN is not acyclic."))
    end
end

function _check_tparam(t, correct_type, name)
    if ! (t isa NamedTuple) 
        throw(ArgumentError("Expected NamedTuple for type parameter $name"))
    elseif ! (isempty(t))
        for v in values(t)
            if ! (typeof(v) <: correct_type)
                throw(ArgumentError("Expected eltype `$correct_type` in `$name`, \
                but got eltype $(eltype(t))"))
            end
        end
    end
end

function _check_repeated_names(dn)
    names = [keys(nodes(dn))...]
    for key in keys(dynamic_pairs(dn))
        if key in names
            throw(ArgumentError("Random variable `$key` in dynamic_pairs already defined as node in DN"))
        else
            push!(names, key)
        end
    end

    for key in keys(ranges(dn))
        if key in names
            throw(ArgumentError("Indexing variable `$key` already defined as random variable in DN"))
        end
    end
end