

const _0A = NoAgent()
const _1A = SingleAgent()
const _NA = IndefiniteAgents()

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

const _YH = Cooperative() 
const _NH = Competitive()
const __H = Cooperative() # default



@markov_alias MC      MarkovTraits(_0A, _FO, __C, __M, _NR, __H)
@markov_alias MRP     MarkovTraits(_0A, _FO, __C, __M, _SR, __H)
@markov_alias HMM     MarkovTraits(_0A, _PO, __C, __M, _SR, __H)
@markov_alias MDP     MarkovTraits(_1A, _FO, __C, __M, _AR, __H)
@markov_alias POMDP   MarkovTraits(_1A, _PO, __C, __M, _AR, __H)
@markov_alias CoMDP   MarkovTraits(_NA, _FO, __C, __M, _AR, __H)
