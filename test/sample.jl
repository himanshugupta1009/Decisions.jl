

@testset "Sample from a POMDP" begin
    Z = (s) -> s + randn()
    A = (o) -> 100
    T = (s, a) -> s + a
    R = (s, a, sp) -> sp

    pomdp = POMDP{MemoryAbsent}(T, Z, R)

    r = sample(pomdp, (; a = (o) -> 10), (; s=0), (:r,))[:r]
    @test r > 0
end