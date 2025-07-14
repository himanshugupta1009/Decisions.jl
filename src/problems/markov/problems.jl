

const _0A = NoAgent()
const _1A = SingleAgent()
const _CA = Cooperative()
const _XA = Competitive()

const _FO = FullyObservable()
const _PO = PartiallyObservable()

const _CC = Centralized()
const _DC = Decentralized()
const __C = Centralized() # default

const _AM = MemoryAbsent()
const _PM = MemoryPresent()
const __M = (MemoryAbsent(), MemoryPresent()) # default

const _NR = NoReward()
const _SR = (ConditionedOn(:s), ConditionedOn(:s, :sp))
const _AR = (ConditionedOn(:s), ConditionedOn(:s, :a), ConditionedOn(:s, :a, :sp)) 
const _MR = (ConditionedOn(:m), ConditionedOn(:m, :a), ConditionedOn(:m, :a, :mp)) 

@markov_alias MC    MarkovTraits(_0A, _FO, __C, __M, _NR)
@markov_alias MRP   MarkovTraits(_0A, _FO, __C, __M, _SR)
@markov_alias HMM   MarkovTraits(_0A, _PO, __C, __M, _SR)
@markov_alias MDP   MarkovTraits(_1A, _FO, __C, __M, _AR)
@markov_alias POMDP MarkovTraits(_1A, _PO, __C, __M, _AR)
