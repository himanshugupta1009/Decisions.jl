using Decisions
using Test

@testset "All tests" begin
    include("conditionals.jl")
    include("variants.jl")
    include("sample.jl")
end