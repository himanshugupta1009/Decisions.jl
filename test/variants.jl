
@testset "Variants are in the Markov family" begin
    T = (s, a) -> s + a
    Z = (s) -> s + rand()
    R = (s) -> s

    pomdp = POMDP(T, Z, R)

    @test pomdp isa MarkovProblem
end

@testset "Disambiguate based on reward conditioning" begin
    uses_sas(m::POMDP{MemoryPresent, SConditioned}) = false
    uses_sas(m::POMDP{MemoryPresent, SAConditioned}) = false
    uses_sas(m::POMDP{MemoryPresent, SASConditioned}) = true

    T = (s, a) -> s + a
    Z = (s) -> s + rand()
    R_s = (s) -> s
    R_sa = (s, a) -> s
    R_sas = (s, a, sp) -> s
    p_s = POMDP(T, Z, R_s)
    p_sa = POMDP(T, Z, R_sa)
    p_sas = POMDP(T, Z, R_sas)

    @test ! uses_sas(p_s)
    @test ! uses_sas(p_sa)
    @test uses_sas(p_sas)
end

# @testset "Disambiguate a problem "