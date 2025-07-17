# Sloppy internals of decision networks. These are mostly used for generating the code in
# `simulate` and therefore executed at compile-time, so eloquence is not the primary
# concern. But, TODO, some cleaning up here would be appropriate.

"""
    _crawl_graph(graph, constituents, input, output)

Give all nodes required to compute `output`, in order, given that nodes `input` are known. 
"""
function _crawl_graph(graph, constituents, input, output)
    # We don't want to evaluate any plates we don't have to: only the ones between the
    # inputs and the outputs. Also, want to do them in order.
    #
    # TODO: Is there a more efficient algorithm for this?

    plate_reps = Dict()
    for node in keys(graph)
        if node in keys(constituents)
            plate_reps[constituents[node][1]] = node
        end
    end

    get_plate_reps(id) = (id ∈ keys(plate_reps) ? plate_reps[id] : id)
    input = map(get_plate_reps, input)
    output = map(get_plate_reps, output)

    req_nodes = Symbol[]
    inter_nodes = Symbol[output...]

    while ! isempty(inter_nodes)
        node = popfirst!(inter_nodes)
        plate = (node ∈ keys(constituents)) ? constituents[node][1] : node
        if ! ((node ∈ input) || (node ∈ req_nodes) || (plate ∈ input))
            push!(req_nodes, node)
            for child in graph[node]
                prereq = if child in keys(constituents)
                    plate_reps[constituents[child][1]]
                elseif child in keys(plate_reps)
                    plate_reps[child]
                else
                    child
                end
                push!(inter_nodes, prereq)
            end
        end
    end

    sort!(req_nodes; by=(n) -> _order(graph, n))
end

"""
    _order(graph, node)

Calculate the maximum number of ancestors between `node` and any root node of DAG `graph`.
"""
function _order(graph, node)
    # welcome to cs 101 lol    
    if ((! (node ∈ keys(graph))) || isempty(graph[node]))
        return 0
    end
    1 + maximum([_order(graph, c) for c in graph[node]])
end


"""
    _referant(id, constituents)

Determine the a variable or array index `id` refers to. 
"""
function _referant(id, constituents) 
    if id ∈ keys(constituents)
        plate_id, idxs... = constituents[id]
        idxs_with_filler = map(idxs) do idx
            (idx == :_) ? :(:) : idx
        end
        :($plate_id[$(idxs_with_filler...)])
    else
        id
    end
end

"""
    _get_plates(dn)

Infer the names of all plates in `dn`.
"""
function _get_plates(dn)
    dn_c = constituents(dn)
    dn_s = structure(dn)
    plates = Symbol[]
    for node in keys(dn_s)
        if node in keys(dn_c)
            plate_id = dn_c[node][1]
            if plate_id ∈ plates
                continue 
            else
                push!(plates, plate_id)
            end
        else 
            push!(plates, node)
        end
    end 
    return Tuple(plates)
end

"""
    _get_plate_defs(dn)

Infer an initial array for all plates defined in `dn` of the correct size.
"""
function _get_plate_defs(dn)
    dn_c = constituents(dn)
    dn_s = structure(dn)
    plate_defs = Expr[]
    for node in keys(dn_s)
        if node in keys(dn_c)
            plate_id = dn_c[node][1]
            if plate_id ∈ keys(plate_defs)
                continue # already got this one
            end

            relevant_csts = filter(constituents(dn)) do cst_def
                cst_def[1] == plate_id
            end

            n_dims = maximum(length.(values(relevant_csts)))-1
            dim_indexers = fill(:_, n_dims)

            for (_, idxs...) in values(relevant_csts)
                for (i, idx_id) in enumerate(idxs)
                    if (dim_indexers[i] == :_) && (idx_id != :_)
                        dim_indexers[i] = idx_id
                    elseif (dim_indexers[i] != :_) && (idx_id != :_)
                        throw(ArgumentError("Conflicting indices for plate $plate_id: \
                        $(dim_indexers[i]) on same axis as $idx_id"))
                    end
                end
            end
            if any(dim_indexers .== :_)
                throw(ArgumentError("Cannot infer shape of plate $plate_id. Got indexers $dim_indexers"))
            end
            dims = Tuple(map(dim_indexers) do idx
                ranges(dn)[idx]
            end)
            push!(plate_defs, :($plate_id = MArray{
                Tuple{$(dims...)}, 
                eltype(node_defs[$(Meta.quot(node))]),
                length($dims),
                prod($dims)}(undef)
            ))
        else 
            continue
        end
    end 
    return plate_defs
end

"""
    _make_update_step(id, dn; in_place=false, checkterminal=true)

Generate an `Expr` that updates random variable `id` based on decision network `dn`.
"""
function _make_update_step(id, dn; in_place=false, checkterminal=true)
    dn_structure = structure(dn)
    dn_constituents = constituents(dn)
    dn_ranges = ranges(dn)
    kws = Expr(:parameters, map(dn_structure[id]) do cond_var
        Expr(:kw, cond_var, _referant(cond_var, dn_constituents))
    end...)
    call = if in_place
        Expr(:call, :rand!, kws, :(node_defs[$(Meta.quot(id))]), _referant(id, dn_constituents))
    else
        Expr(:call, :rand, kws, :(node_defs[$(Meta.quot(id))]))
    end
    assgn_block = if checkterminal
        tmp_id = gensym()
        quote
            $tmp_id = $call
            isterminal($tmp_id) && return
            $(_referant(id, dn_constituents)) = $tmp_id
        end
    else
        quote
            $(_referant(id, dn_constituents)) = $call
        end
    end

    if id in keys(dn_constituents)
        loop_idxs = [:($idx_var = 1:$(dn_ranges[idx_var])) for idx_var in dn_constituents[id][2:end]
                    if idx_var != :_]
        Expr(:for, Expr(:block, reverse(loop_idxs)...), assgn_block)
    else
        assgn_block
    end
end