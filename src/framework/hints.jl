"""
    abstract type DecisionsTrait

Abstract base trait type for all traits used in Decisions.jl.
"""
abstract type DecisionsTrait end

# For convenience
Base.Tuple(t::DecisionsTrait) = (t,)

"""
    abstract type Multiagency <: DecisionsTrait
    Multiagency(::DecisionNetwork)
    
Abstract trait type denoting the number of agents, if any, in a problem. 
"""
abstract type Multiagency <: DecisionsTrait end

"""
    struct NoAgents <: Multiagency
    
Trait denoting a network supports no agents (implying no decision nodes).
"""
struct NoAgent <: Multiagency end

"""
    struct SingleAgent <: Multiagency
    
Trait denoting presence of exactly one agent. 
"""
struct SingleAgent <: Multiagency end

"""
    abstract type MultiAgent <: Multiagency

Abstract trait type denoting a network supports multiple agents.

The exact number of agents may (with `DefiniteAgents`) or may not (with `IndefiniteAgents`)
be specified.
"""
abstract type MultiAgent <: Multiagency end

"""
    abstract type DefiniteAgents{N} <: MultiAgent

Trait denoting support for exactly `N` agents.
"""
struct DefiniteAgents{N} <: MultiAgent end


"""
    abstract type DefiniteAgents{N} <: MultiAgent

Trait denoting support for some number of agents, which is not known ahead of time.
"""
struct IndefiniteAgents <: MultiAgent end

####################

"""
    abstract type Sequentiality <: DecisionsTrait
    Sequentiality(::DecisionNetwork)

Abstract trait type denoting whether agents act simultaneously or sequentially.
"""
abstract type Sequentiality <: DecisionsTrait end

"""
    Sequential <: Sequentiality

Trait indicating agents act sequentially (meaning each agent controls one or more
independent decision nodes).
"""
struct Sequential <: Sequentiality end

"""
    Simultaneous <: Sequentiality

Trait indicating agents act simultaneously (meaning agents implement different indices of
the same decision node(s)).
"""
struct Simultaneous <: Sequentiality end

###################

"""
    abstract type Observability <: DecisionsTrait
    Observability(::DecisionNetwork)

Abstract trait type indicating whether input to decision nodes passed to an agent or agents
is "full," in that it is at least as informative as knowing the values of its
predecessors.
"""
abstract type Observability <: DecisionsTrait end

"""
    FullyObservable <: Observability

Trait indicating decision nodes receive perfect / full information.
"""
struct FullyObservable <: Observability end

"""
    PartiallyObservable <: Observability

Trait indicating decision nodes do not receive perfect / full information.
"""
struct PartiallyObservable <: Observability end

num_agents(::DefiniteAgents{N}) where {N} = N 
num_agents(::SingleAgent) = 1
num_agents(::NoAgent) = 0 

###################

"""
    abstract type Cooperation <: DecisionsTrait
    Cooperation(::DecisionNetwork)

Abstract trait indiating the extent to which a decision network implies cooperative agents.
"""
abstract type Cooperation <: DecisionsTrait end

"""
    Cooperative <: Cooperation

Trait indicating agents are implied to cooperate or receive a benefit from cooperating.
"""
struct Cooperative <: Cooperation end

"""
    Competitive <: Cooperation

Trait indicating agents are implied to compete or receive a benefit from competing. 
"""
struct Competitive <: Cooperation end

"""
    Individual <: Cooperation

Trait indicating agents are implied to act independently, neither cooperating nor competing.
"""
struct Individual  <: Cooperation end

####################

"""
    abstract type MemoryPresence <: DecisionsTrait
    MemoryPresence(::DecisionNetwork)

Abstract trait indicating whether iterates of a dynamic decision network are accrued in an
agent-defined memory.
"""
abstract type MemoryPresence <: DecisionsTrait end

"""
    MemoryPresent <: MemoryPresence

Abstract trait indicating iterates of a dynamic decision network are accrued in an
agent-defined memory.
"""
struct MemoryPresent <: MemoryPresence end

"""
    MemoryAbsent <: MemoryPresence

Abstract trait indicating no accrual of information from iterate to iterate of a dynamic
decision network in any agent-defined memory.
"""
struct MemoryAbsent <: MemoryPresence end

####################

"""
    abstract type RewardStyle{ids} <: DecisionsTrait
    RewardStyle(::DecisionNetwork)

Abstract trait indicating whether a decision network has a node analogous to a reward node:
a node no others are conditioned on, typically for use in an objective. If so, indicates
whether it represents a single or multiple reward, and the other nodes `ids` it is
conditioned on.
"""
abstract type RewardStyle{ids} <: DecisionsTrait end

"""
    struct NoReward <: RewardStyle{()}

Trait indicating a decision network has no node analogous to a "reward" node.
"""
struct NoReward <: RewardStyle{()} end

"""
    SingleReward{ids} <: RewardStyle{ids}
    
Trait indicating a decision network has a "reward" node producing a single value, which is
conditioned on the nodes `ids`.
"""
struct SingleReward{ids} <: RewardStyle{ids} 
    SingleReward(ids...) = new{_sorted_tuple(ids)}()

end

"""
    MultipleRewards{ids} <: RewardStyle{ids}
    
Abstract trait indicating a decision network has a "reward" node producing multiple values,
which is conditioned on the nodes `ids`.

The number of values produced can be known (`DefiniteRewards`) or unknown
(`IndefiniteRewards`).
"""
abstract type MultipleRewards{ids} <: RewardStyle{ids} end

"""
    DefiniteRewards{N, ids} <: MultipleRewards{ids}

Trait indicating a decision network has a "reward" node conditioned on `ids` which produces
exactly `N` values (that is, it is a plate of size `N`).
"""
struct DefiniteRewards{N, ids} <: MultipleRewards{ids}
    DefiniteRewards(n, ids...) = new{n, _sorted_tuple(ids)}()
end

"""
    IndefiniteRewards <: MultipleRewards{ids}

Trait indicating a decision network has a "reward" node conditioned on `ids` which is a
plate of unknown size.
"""
struct IndefiniteRewards{ids} <: MultipleRewards{ids}
    IndefiniteRewards(ids...) = new{_sorted_tuple(ids)}()
end

num_rewards(::MultipleRewards{n}) where {n} = n
num_rewards(::SingleReward) = 1
num_rewards(::NoReward) = 0

reward_conditions(::RewardStyle{ids}) where {ids} = ids

"""
    Centralization <: DecisionsTrait
    Centralization(::DecisionNetwork)

Abstract trait indicating whether agents receive the same input or not.
"""
abstract type Centralization <: DecisionsTrait end

"""
    Centralized <: Centralization

Trait indicating agents receive the same input.
"""
struct Centralized <: Centralization end

"""
    Decentralized <: Centralization

Trait indicating agents do not receive the same input.
"""
struct Decentralized <: Centralization end

####################
"""
    abstract type Statefulness <: DecisionsTrait
    Statefulness(::DecisionNetwork)

Abstract trait indicating whether a "state" / "state update" node is present, and if so, how
it is structured.
"""
abstract type Statefulness <: DecisionsTrait end

"""
    Stateful <: Statefulness

Trait indicating that a decision network has a "state" / "state update" node.
"""
struct Stateful <: Statefulness end

"""
    Stateless <: Statefulness

Trait indicating that a decision network has no "state" / "state update" node.
"""
struct Stateless <: Statefulness end

"""
    AgentFactored <: Statefulness

Trait indicating that a decision network has a "state" / "state update" node, and it is a
plate with an agent-index axis.
"""
struct AgentFactored <: Statefulness end

"""
    abstract type TimestepStyle <: DecisionsTrait
    TimestepStyle(::DecisionNetwork)

Abstract trait indicating the time interpretation of each iterate of a dynamic decision
network. 
"""
abstract type TimestepStyle <: DecisionsTrait end

"""
    SemiMarkov <: TimestepStyle

Trait indicating a dynamic decision network is semi-Markov: the sojourn time from iteration
to iteration is given by a node in the network.
"""
struct SemiMarkov <: TimestepStyle end

"""
    FixedTimestep <: TimestepStyle

Trait indicating iterates in a dynamic decision network are equal, fixed timesteps with no
semi-Markov considerations.
"""
struct FixedTimestep <: TimestepStyle end

####################

"""
    abstract type AgentCorrelation <: DecisionsTrait
    AgentCorrelation(::DecisionNetwork)

Abstract trait indicating whether decision nodes are sampled jointly or independently across
agents.
"""
abstract type AgentCorrelation <: DecisionsTrait end

"""
    Correlated <: AgentCorrelation

Trait indicating all decision nodes are sampled jointly across agents.
"""
struct Correlated <: AgentCorrelation end

"""
    Uncorrelated <: AgentCorrelation

Trait indicating all decision nodes are sampled independently across agents.
"""
struct Uncorrelated <: AgentCorrelation end

####################

"""
    Terminality <: DecisionsTrait
    Terminality(::RVGroup)

Abstract trait on a group of random variables indicating whether the corresponding distribution is
expected to be able to produce `Terminal()` when sampled.
"""
abstract type Terminality <: DecisionsTrait end

"""
    Terminable <: Terminality

Trait indicating a group of random variables might produce `Terminal()` under certain values
of its conditioning variables.
"""
struct Terminable <: Terminality end

"""
    NotTerminable <: Terminality

Trait indicating a group of random variables never produces `Terminal()` under any
circumstances,.
"""
struct NotTerminable <: Terminality end

"""
    MaybeTerminal <: Terminality

Trait indicating a group of random variables may be able to produce `Terminal()` under some
values of its conditioning variables, or for none of them.
"""
struct MaybeTerminable <: Terminality end