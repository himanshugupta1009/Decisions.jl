import RockSample
import POMDPs
import POMDPTools
import Distributions
using Decisions

# # function RockSampleDecisions()
#     m = RockSample.RockSamplePOMDP()
#     up = POMDPTools.DiscreteUpdater(m)
#     dnm = POMDP(DiscountedReward(POMDPs.discount(m));
#     sp = (s,a) -> transition(m,s,a),
#     r = (s,a,sp) -> reward(m,s,a),
#     o = (a,s,sp) -> observation(m,a,sp),
#     mp = (a,m,o) -> update(up,m,a,o)
#     )
# # end

function RockSampleDecisions()
    pomdp = RockSample.RockSamplePOMDP()
    up = POMDPTools.DiscreteUpdater(m)
    m0 = POMDPs.initialize_belief(up,POMDPs.initialstate(pomdp))
    rstransition = @ConditionalDist Tuple{RockSample.RSState,Int} begin
        function support(;s,a)
            if isnothing(s) || isnothing(a)
                POMDPTools.ordered_states(pomdp)
            else
                Distributions.support(POMDPs.transition(pomdp,s,a))
            end
        end

        function rand(rng;s,a)
            if POMDPs.isterminal(pomdp,s)
                Terminal()
            else
                rand(rng,POMDPs.transition(pomdp,s,a))
            end
        end

        function pdf(sp;s,a)
            Distributions.pdf(POMDPs.transition(pomdp,s,a),sp)
        end
    end

    rsreward = @ConditionalDist Float64 begin
        function rand(rng; s, a, sp)
            POMDPs.reward(pomdp,s,a,sp)
        end
    end

    rsobservation = @ConditionalDist Int begin
        function support(;s,a,sp)
            if isnothing(s) || isnothing(a)
                POMDPTools.ordered_observations(pomdp)
            else
                Distributions.support(POMDPs.observation(pomdp,s,a,sp))
            end
        end

        function rand(rng;s,a)
            rand(rng,POMDPs.observation(pomdp,s,a,sp))
        end

        function pdf(o;s,a,sp)
            Distributions.pdf(POMDPs.observation(pomdp,s,a,sp),o)
        end
    end

    rsmemory = @ConditionalDist Tuple{RockSample.RSState,Int} begin
        function support(;a,m,o)
            POMDPs.update(up,m,a,o)
        end
        
        function rand(rng;a,m,o)
            rand(rng,POMDPs.update(up,m,a,o))
        end

        function pdf(mp;a,m,o)
            true_mp = POMDPs.update(up,m,a,o) #Bad? - Handle mp not in support?
            if mp == true_mp
                return 1.0
            else
                return 0.0
            end
        end
    end
    
    rsinitialbel = @ConditionalDist Tuple{RockSample.RSState,Int} begin
        function support(;)
            m0
        end
        function pdf(m;)
            if m == m0
                1.0
            else
                0.0
            end
        end
    end
    return POMDP(DiscountedReward(POMDPs.discount(pomdp)),rsinitialbel;
    sp = rstransition,
    r = rsreward,
    o = rsobservation,
    mp = rsmemory
    )
end



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
end

function transform(components::ToMixedObservability{X,Y}, model::POMDP_DN) where {X,Y}
    s = model[:s].support()[1]
    if Symbol==X #Make better, handle vectors/tuples
        xp = getfield(s,components.fully_observable_state_components)
    elseif Int==X
        xp = s[components.fully_observable_state_components]
    end
    return xp

    # return MOMDP_DN(;xp = (x,y,a) -> x+1,
    # yp = (x,y,a) -> y+1,
    # r = (x,y,a,xp,yp) -> x,
    # o = (a,x,y,xp,yp) -> xp+yp,
    # mp = (a,m,o) -> update(up,m,a,o))
end