using Decisions


# Let's define repeated rock-paper-scissors as a Markov game in discrete space

# DEFINING MARKOV GAME
# First we need to define what a Markov game is, in terms of its decision network
# There are three ways to do this.
# First, MGs happen to be predefined, so we could just use them directly:
MG_DN


# @enum PrisonerChoice SILENT BETRAY
# const ChoicePair = Tuple{PrisonerChoice, PrisonerChoice}
# function IteratedPrisoners()
#     transition = @ConditionalDist ChoicePair begin
#         function rand(rng; s, a)
#             Tuple(a)
#         end
#     end
#     reward = @ConditionalDist Float64 begin
#         function rand(rng; s, i, a, sp)
#             if sp == (SILENT, SILENT)
#                 -1.0
#             elseif sp == (BETRAY, SILENT)
#                 (i == 1) ? 0.0 : -3.0
#             elseif sp == (SILENT, BETRAY)
#                 (i == 1) ? -3.0 : 0.0
#             else
#                 -2.0
#             end
#         end
#     end
#     Decisions.MG_DN((; i=2); sp=transition, r=reward, 
#         a=FiniteSpace([SILENT, BETRAY]))
# end
# action = @ConditionalDist PrisonerChoice begin
#     function rand(rng; s, i)
#         rand([SILENT, BETRAY])
#     end
# end
# behavior = (; a=action)

# mg = IteratedPrisoners()
# sample(mg, behavior, (; s=(SILENT, SILENT))) do output
#     println(output)
#     return (output[:a][1] == BETRAY) && (output[:a][2] == BETRAY)
# end 