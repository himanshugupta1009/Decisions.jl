# const MetaDecision = DecisionNetwork{DecisionGraph{
#     (; 
#         decision = (:network, :params), 
#         output = (:new_network,),
#         new_params = (:network, :params, :output, :decision),
#         new_network = (:network)
#     ), (; params = :new_params, network = :new_network)
# }}

# function (::Type{MetaDecision})(dn::DecisionNetwork, dm::DecisionMetrics)
#     Type{MetaDecision}(
#         decision = TypeSpace{ConditionalDist}(),
#         output = dm,
#         new_network = SingletonSpace{dn}(),
#         new_params = TypeSpace{Any}()
#     )
# end