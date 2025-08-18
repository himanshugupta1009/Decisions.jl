
@testset "Named problems are valid decision problems" begin
    T = (s, a) -> s + a
    Z = (s) -> s + rand()
    R = (s) -> s

    pomdp = POMDP(T, Z, R)

    @test pomdp isa DecisionNetwork
end

@testset "Disambiguate based on reward conditioning" begin
    T = (s, a) -> s + a
    Z = (s) -> s + rand()
    R_s = (s) -> s
    R_sa = (s, a) -> s
    p_s = POMDP(T, Z, R_s)
    p_sa = POMDP(T, Z, R_sa)


    uses_sa(m::typeof(p_s)) = false
    uses_sa(m::typeof(p_sa)) = true


    @test ! uses_sa(p_s)
    @test uses_sa(p_sa)
end

# @testset "Disambiguate a problem "