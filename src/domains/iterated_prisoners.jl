@enum PrisonerChoice SILENT BETRAY


function IteratedPrisoners()
    transition = @ConditionalDist Tuple{PrisonerChoice, PrisonerChoice} begin
        function rand(rng; s, a)
            Tuple(a)
        end
    end

    reward = @ConditionalDist Float64 begin
        function rand(rng; s, i, a, sp)
            if sp == (SILENT, SILENT)
                -1.0
            elseif sp == (BETRAY, SILENT)
                (i == 1) ? 0.0 : -3.0
            elseif sp == (SILENT, BETRAY)
                (i == 1) ? -3.0 : 0.0
            else
                -2.0
            end
        end
    end

    MG((; i=2);
        sp=transition,
        r_i=reward,
        a_i=FiniteSpace([SILENT, BETRAY])
    )
end

a_i = @ConditionalDist PrisonerChoice begin
    function rand(rng; s, i)
        rand([SILENT, BETRAY])
    end
end

behavior = (; a_i)

mg = IteratedPrisoners()
simulate(mg, behavior, (; s=(SILENT, SILENT))) do output
    println(output)
    return (output[:a][1] == BETRAY) && (output[:a][2] == BETRAY)
end