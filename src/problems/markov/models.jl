

# Remaining to be done:
# MMDP
# MG
# MPOMDP
# POMG




@def_markov MC    NoAgent     FullyObservable     Centralized Any NoReward
@def_markov MRP   NoAgent     FullyObservable     Centralized Any Any
@def_markov MDP   SingleAgent FullyObservable     Centralized Any Any
@def_markov HMM   NoAgent     PartiallyObservable Centralized Any NoReward
@def_markov POMDP SingleAgent PartiallyObservable Centralized Any Any

# @def_markov DecPOMDP  Cooperative PartiallyObservable Decentralized Any Any


function transform(::ToTrait{SingleAgent}, p1::MarkovProblem{NoAgent,Z,C,M,R}) where {Z,C,M,R}
    MarkovProblem{SingleAgent,Z,C,M,R}(p1.impl)
end

function transform(::ToTrait{MultiAgent{N}}, p1::MarkovProblem{SingleAgent,Z,C,M,R}) where {N,Z,C,M,R}
    MarkovProblem{MultiAgent{N},Z,C,M,R}(p1.impl)
end

function transform(::ToTrait{Decentralized}, p1::MarkovProblem{N,Z,Centralized,M,R}) where {N,Z,C,M,R}
    MarkovProblem{N,Z,Centralized,M,R}(p1.impl)
end

function transform(::ToTrait{Centralized}, p1::MarkovProblem{N,Z,Decentralized,M,R}) where {N,Z,C,M,R}
    MarkovProblem{N,Z,Decentralized,M,R}(p1.impl)
end

function transform(t::ToTrait{PartiallyObservable}, p1::MarkovProblem{N,FullyObservable,C,M,R}) where {N,Z,C,M,R}
    MarkovProblem{N,FullyObservable,C,M,R}(merge(p1.impl, (o = t.obs_fn)))
end