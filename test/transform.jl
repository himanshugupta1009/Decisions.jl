
@testset "Named DPs can be produced by transformations" begin
    @test POMDP |> Collapse((:o,)) == MDP
end