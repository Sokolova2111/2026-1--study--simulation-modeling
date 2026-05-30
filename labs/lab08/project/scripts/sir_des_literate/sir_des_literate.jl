using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots, BenchmarkTools

tmax = 40.0
u0 = [990, 10, 0]  # S, I, R
p = [0.05, 10.0, 0.25]  # β, c, γ

Random.seed!(1234)

println("R₀ = $(round(p[1]*p[2]/p[3], digits=2))")

des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

println("Симуляция завершена. Собрано событий: $(length(data_des.t))")

@df data_des plot(
    :t,
    [:S :I :R],
    labels = ["S" "I" "R"],
    xlab = "Время",
    ylab = "Численность",
    title = "Дискретно-событийная SIR модель",
)

savefig(plotsdir("sir_des.png"))
display(p)
println("График сохранён в plots/sir_des.png")

println("\n=== Финальная статистика ===")
println("Время симуляции: $(data_des.t[end])")
println("Восприимчивые (S): $(data_des.S[end])")
println("Инфицированные (I): $(data_des.I[end])")
println("Переболевшие (R): $(data_des.R[end])")

max_I = maximum(data_des.I)
peak_time = data_des.t[argmax(data_des.I)]
println("\nПик эпидемии:")
println("  Максимальное число инфицированных: $max_I")
println("  Время достижения пика: t = $(round(peak_time, digits=2))")
