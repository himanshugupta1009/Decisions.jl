using Decisions
# Quick talk about package structure

# Let's define repeated rock-paper-scissors as a Markov game in discrete space

# DEFINING GENERIC NETWORKS / FRAMEWORKS (DecisionGraphs)
# First we need to define what a Markov game is, in terms of its decision network
# There are four reasonable ways to do this.
# First, MGs happen to be predefined, so we could just use that:
MG_DN

# Second, MGs happen to exist in a special class called the "standard Markov family." 
# (specific set of random variables)
# For these frameworks we can use a special macro to define them based on traits.
traits = MarkovAmbiguousTraits(
    Statefulness => Stateful(),
    Multiagency => IndefiniteAgents(),
    AgentCorrelation => Uncorrelated(),
    MemoryPresence => MemoryAbsent(),
    Centralization => Decentralized(),
    Cooperation => Competitive(),
    RewardStyle => SingleReward(:s, :a, :sp)
)

@markov_alias My_MG_1 traits
# ... you'll see this is identical to MG_DN, and the alias will appear

# Third, we could define the network by hand with the DecisionGraph constructor
# (a DecisionGraph is just a type of DecisionNetwork)
DecisionGraph(
    [ # Regular nodes
    (Dense(:s),)                       => Indep(:a, (:i,)  ; is_terminable = false), 
    (Dense(:a), Dense(:s), Dense(:sp)) => Indep(:r, (:i,), ; is_terminable = false), 
    (Dense(:a), Dense(:s))             => Joint(:sp, (),   ; is_terminable = true)
    ],
    (; # Dynamic nodes
    :s => :sp
    )
    # It's also legal to define specific index ranges here - for instance, a specific number
    # of players. But predefined MG_DN doesn't do that, so we won't here either
)

# Fourth, which I won't show, would be to use a transformation:
# e.g., could imagine something like MDP |> MakeAdversarial(...)


# Let's inspect the DDN for a Markov game by instantiating an empty one:
#   (@show can't be defined for types, which is what MG_DN is)
MG_DN(;)

# We can also plot it:
# dnplot(MG_DN)
# If you're curious about how exactly to read that plot (why are there hexagons??) read that
#   page of the docs.



# DEFINING DECISION *PROBLEMS*
# MG_DN is just the DN underlying a Markov game - we haven't defined what the objective of 
#   a Markov game looks like
#   More exactly, an objective is some value that could depend on ALL of the random 
#   variables of the problem, over all iterations. Typically though they just involve the 
#   "reward" node.
#   We don't say what is to be done with this objective but the idea is it's whatever the 
#   higher level optimizer is supposed to care about

# Obviously this could be a lot of things! For now we'll assume a Markov game is a decision
# problem modeled by the DN we just made, where the objective is some sort of discounted
# reward for each player.

const My_MG = DecisionProblem{<: DiscountedReward, <: MG_DN}



# DEFINING A SPECIFIC DECISION PROBLEM 
# (that is, a domain)
# Let's write down repeated rock-paper-scissors as a Markov game.

# Conveniences
@enum RPSAction ROCK PAPER SCISSORS
const RPSPair = Tuple{RPSAction, RPSAction}

# Constructing RPS is a matter of the following steps:
# * Construct conditional distributions for the transition and reward
# * Make an empty distribution for the action space (WIP)
# * Return a DecisionProblem

# The ConditionalDist framework is quite detailed. See the docs.
#   The relevant thing is that we can define them in an anonymous way,
#   making them on the spot

function RPS() # we could put parameters in here, if we wanted
    # Not much point to a transition function here
    #   (this could really be stateless)
    transition = @ConditionalDist RPSPair begin
        function rand(rng; s, a)
            Tuple(a)
        end
    end

    # Closures are valid in @ConditionalDist
    M = [0 -1 1; 1 0 -1; -1 1 0]
    reward = @ConditionalDist Float64 begin
        function rand(rng; s, i, a, sp)
            if i == 1
                M[Int(a[1])+1, Int(a[2])+1]
            else
                -M[Int(a[1])+1, Int(a[2])+1]
            end
        end
    end

    # If only the space is known and not the distribution
    #   (typical for action distributions)
    #   it will automatically be converted into a ConditionalDist
    action = FiniteSpace([ROCK, PAPER, SCISSORS])

    # Workaround
    initial = @ConditionalDist @NamedTuple{s::RPSPair} begin
        rand(rng) = (; s=(ROCK, ROCK))
    end

    MG(
        DiscountedReward(1.0), 
        initial, 
        (;i=2); 
        a=action, r=reward, sp=transition
    )
end


# DEFINING A SOLVER
# The solver framework is very lightweight for now, and we don't yet make any
#   distinctions between model and environment. 
#   Just return a NamedTuple with distributions for all the action nodes

struct RandomSolver <: DecisionAlgorithm
end

function Decisions.solve(alg::RandomSolver, prob::DecisionProblem)
    
    action_type = eltype(prob[:a])

    pol = @ConditionalDist action_type begin
        function rand(rng; s, i)
            rand([support(prob[:a])...])
        end
    end
    (; a = pol)
end

# (can anyone spot the bug / inadequacy in this solver?)


function run_for_200()
    n = 0
    simulate!(RandomSolver(), RPS()) do vals
        println(vals)
        n +=1
        n >= 200
    end
end

run_for_200()