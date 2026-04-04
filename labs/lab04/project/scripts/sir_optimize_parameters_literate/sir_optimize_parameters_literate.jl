using DrWatson
@quickactivate "project"
using BlackBoxOptim, Random, Statistics
include(srcdir("sir_model.jl"))

function cost_multi(x)
    replicates = 3
    peak_vals = Float64[]
    dead_vals = Float64[]

    for rep in 1:replicates
        model = initialize_sir(;
            Ns = [1000, 1000, 1000],
            β_und = fill(x[1], 3),
            β_det = fill(x[1]/10, 3),
            infection_period = 14,
            detection_time = round(Int, x[2]),
            death_rate = x[3],
            reinfection_probability = 0.1,
            Is = [0, 0, 1],
            seed = 42 + rep,
        )

        infected_frac(model) = count(a.status == :I for a in allagents(model)) / nagents(model)
        peak = 0.0

        for step in 1:100
            Agents.step!(model, 1)
            frac = infected_frac(model)
            if frac > peak
                peak = frac
            end
        end

        deaths = 3000 - nagents(model)
        push!(peak_vals, peak)
        push!(dead_vals, deaths / 3000)
    end

    return (mean(peak_vals), mean(dead_vals))
end

result = bboptimize(
    cost_multi,
    Method = :borg_moea,
    FitnessScheme = ParetoFitnessScheme{2}(is_minimizing=true),
    SearchRange = [(0.1, 1.0), (3.0, 14.0), (0.01, 0.1)],
    NumDimensions = 3,
    MaxTime = 60,
    TraceMode = :compact,
)

best = best_candidate(result)
fitness = best_fitness(result)

println("\nОптимальные параметры:")
println("β_und = $(round(best[1], digits=3))")
println("Время выявления = $(round(Int, best[2])) дней")
println("Смертность = $(round(best[3], digits=4))")
println("\nПик заболеваемости: $(round(fitness[1], digits=4))")
println("Доля умерших: $(round(fitness[2], digits=4))")
