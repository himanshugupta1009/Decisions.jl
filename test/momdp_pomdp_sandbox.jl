using Decisions

testrs = RockSampleDecisionsPOMDP()

#Test Sampling/Rand
testrs[:sp](;s=rand(support(testrs[:sp])),a=rand(support(testrs[:a])))
otest = testrs[:o](;s=rand(support(testrs[:sp])),a=rand(support(testrs[:a])),sp=rand(support(testrs[:sp])))
testrs[:r](;s=rand(support(testrs[:sp])),a=rand(support(testrs[:a])),sp=rand(support(testrs[:sp])))
testrs[:r](;s=rand(support(testrs[:sp])),a=rand(support(testrs[:a])),sp=rand(support(testrs[:sp])))
btest = testrs.initial.rand()
testrs[:mp](;a=2,m=btest,o=3) #Check belief update correct

#support/pdf Test 
sp = support(testrs[:sp];s=DecisionDomains.RockSample.RSState{3}([1, 1], Bool[0, 0, 0]),a=2)[1]
pdf(testrs[:sp],sp;s=DecisionDomains.RockSample.RSState{3}([1, 1], Bool[0, 0, 0]),a=2)

## MOMDP Transformation Work
const MOMDP_DN = DecisionGraph(
  [ # Six regular nodes (:xp, :yp, :r, :o, :mp, :a)
    (Dense(:x), Dense(:y), Dense(:a)) => Joint(:xp),
    (Dense(:x), Dense(:y), Dense(:a), Dense(:xp)) => Joint(:yp),
    (Dense(:x), Dense(:y), Dense(:a)) => Joint(:r),
    (Dense(:x), Dense(:y), Dense(:a), Dense(:xp), Dense(:yp)) => Joint(:o),
    (Dense(:x), Dense(:o), Dense(:a), Dense(:m)) => Joint(:mp),
    (Dense(:m),) => Joint(:a),
  ],
  (; # Three dynamic nodes (:x, :y, :m)
    :x => :xp,
    :y => :yp,
    :m => :mp
  ),
  (;) # No ranges
)


struct ToMixedObservability{X,Y} <: DNTransformation
    fully_observable_state_components::X
    partially_observable_state_components::Y
    ToMixedObservability(x, y) = isa(x,Tuple) && isa(y,Tuple) ? new{typeof(x),typeof(y)}(x,y) : error("Use Tuples")
end

function marginalize(model::POMDP_DN,s,a,idx)
    sps = model[:s].support(;s=s,a=a)
    for sp in model[:s].support(;s=s,a=a)

    end
end

function get_components(s,idx)
    x_type = typeof(idx)
    if Symbol in idx
        xp = Tuple(getfield(s,i) for i in idx)
    elseif Int==x_type
        xp = Tuple(s[i] for i in idx)
    end
    return xp
end

function Decisions.transform(components::ToMixedObservability, model::POMDP_DN)
    sup = model[:s].support()
    sup_size = length(sup)
    x_type = typeof(get_components(sup[1],components.fully_observable_state_components))
    y_type = typeof(get_components(sup[1],components.partially_observable_state_components))
    xs = Array{x_type}[] #(undef, sup_size)
    ys = Array{y_type}[] #(undef, sup_size)
    for s in sup
        push!(xs,get_components(s,components.fully_observable_state_components))
        push!(ys,get_components(s,components.partially_observable_state_components))
    end
    return xs,ys
    # mo_model = transform(Insert(((Dense(:x), Dense(:y), Dense(:a)) => Joint(:xp)),
    #         (Dense(:x), Dense(:y), Dense(:a), Dense(:xp)) => Joint(:yp)),model) |> Unimplement(:o,:r,:mp) |> Recondition(;r =((Dense(:x), Dense(:y), Dense(:a),)),o = (Dense(:x), Dense(:y), Dense(:a), Dense(:xp), Dense(:yp)),mp=(Dense(:x), Dense(:o), Dense(:a), Dense(:m))) |> MergeForward(:sp)
    
    # return mo_model
    
    # return MOMDP_DN(;xp = (x,y,a) -> x+1,
    # yp = (x,y,a) -> y+1,
    # r = (x,y,a,xp,yp) -> x,
    # o = (a,x,y,xp,yp) -> xp+yp,
    # mp = (a,m,o) -> update(up,m,a,o))
end