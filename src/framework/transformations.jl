abstract type DNTransformation end

struct Collapse{nodes} <: DNTransformation end
struct Recondition{nodes_with_inputs} <: DNTransformation end
struct Insert{nodes_with_inputs} <: DNTransformation end
struct Require{nodes} <: DNTransformation end

# TODO: I feel like we're misusing value types here. Definitely beneficial for 
#   specialization, but something is off
Collapse(x) = Collapse{x}()
Recondition(x) = Recondition{x}()
Insert(x) = Insert{x}()
Require(x) = Require{x}()

const Memoryless = Collapse{(:m, :mp)}
const Memoryful = Require{(:mp)}

function transform(t::DNTransformation, p::DecisionNetwork)
    transform(t, typeof(p))(p.behavior)
end


# TODO Refactor this; lil low on sleep
function transform(::Collapse{nodes}, prob::Type{<:DecisionNetwork{network}}) where {network, nodes}
    old_structure = structure(prob)
    old_dynamism = dynamism(prob)
    new_structure = old_structure
    new_dynamism = old_structure
    for node in nodes
        new_structure = map(old_structure) do inputs
            if node ∈ inputs
                new_inputs = (node ∈ keys(old_structure)) ? old_structure[node] : ()
                new_inputs = Tuple(union(Set(inputs), Set(new_inputs)))
                new_inputs = filter(x -> x != node, new_inputs)
            else
                inputs
            end
        end
        new_structure = NamedTuple{filter(x -> x != node, keys(new_structure))}(new_structure)
        new_dynamism = NamedTuple([p for p in pairs(old_dynamism) if ! (node in p)])
        old_structure = new_structure
        old_dynamism = new_dynamism
    end
    dn = DecisionGraph(new_structure, new_dynamism)
    return DecisionNetwork{typeof(dn)}
end

function transform(t::DNTransformation, u::Union)
    newtypes = map(Base.uniontypes(u)) do probtype
        transform(t, probtype)
    end
    Union{newtypes...}
end

function transform(::Require{nodes}, u::Union) where {nodes}
    newtypes = filter(Base.uniontypes(u)) do probtype
        nodes_present = keys(structure(probtype))
        all([node in nodes_present for node in nodes])
    end
    Union{newtypes...}
end

# Nodes that already exist in the problem are not changed
function transform(::Insert{nodes}, prob::Type{<:DecisionNetwork{network}}) where {network, nodes}
    merged_structure = merge(nodes, structure(prob))
    dn = DecisionGraph(merged_structure, dynamism(prob))
    return DecisionNetwork{typeof(dn)}
end

# Nodes that aren't already in the problem are ignored
function transform(::Recondition{nodes}, prob::Type{<:DecisionNetwork{network}}) where {network, nodes}
    merged_structure = merge(structure(prob), nodes)
    new_structure = NamedTuple{keys(structure(prob))}(merged_structure)
    dn = DecisionGraph(new_structure, dynamism(prob))
    return DecisionNetwork{typeof(dn)}
end

(t::DNTransformation)(p::DecisionNetwork) = transform(t, p)
(t::DNTransformation)(p::Type{<:DecisionNetwork}) = transform(t, p)