using Pkg
# Pkg.develop(path="d:/Studies/Research/Code/Decisions.jl")
Pkg.activate()
using Decisions
using Random

Pkg.activate(".")
using POMDPs
using POMDPTools


myPOMDP = POMDP_DN(
        # a = (; m) -> "action",
        o = (; s, a) -> "obs",
        r = (; s, a, sp) -> "rwd",
        sp = (; s, a) -> "successor state"
        )
dnplot(myPOMDP)


# Step 1: 
myBMDP = myPOMDP |> Unimplement(:r, :o,:mp)

# Step 2: 
myBMDP = myBMDP |> MergeForward(:s, :sp, :o)
dnplot(myBMDP)


# Step 3: define an updater from memory node m to memory node mp:
# # 3.1 generate environment model graph:
# myEnv = myPOMDP |> Unimplement(:r, :a,:mp)

# myEnv = myEnv |> MergeForward(:m, :mp, :r)
# dnplot(myEnv)


function genObs(rng, m, a)
    # Set s in the environment model to a sample from m, and :a to a.
    s = rand(rng, m)

    sp = rand(myPOMDP[:sp]; s, a)
    o = rand(myPOMDP[:o]; s, a, sp)
    
    return o
end

function update( m, a, o)
    # Set s in the environment model to a sample from m, and :a to a.
    return m
end

mem_updater = @ConditionalDist Any begin
    function rand(rng; m, a)
        o = genObs(rng; m,a)
        update(m, a, o)
    end
end
myBMDP = myBMDP |> Implement(;
    mp = mem_updater 
)

# Step 4: recondition r on m, a, mp
myBMDP = myBMDP |> Recondition(; r =(Dense(:a),Dense(:m),Dense(:mp)))
dnplot(myBMDP)


# Step 5: Rename m--> s, and mp --> sp
myBMDP = myBMDP |> Rename(; m = :s, mp = :sp)
dnplot(myBMDP)