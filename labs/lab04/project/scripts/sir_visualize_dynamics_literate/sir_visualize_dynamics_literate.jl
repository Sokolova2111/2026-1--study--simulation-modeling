using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV
include(srcdir("sir_model.jl"))

df = CSV.read(datadir("beta_scan_all.csv"), DataFrame)

p1 = plot(df.beta, df.peak,
    label = "Пик",
    xlabel = "β",
    ylabel = "Доля инфицированных",
    linewidth = 2,
    color = :blue
)
plot!(p1, df.beta, df.final_inf,
    label = "Конечная",
    linewidth = 2,
    color = :red
)

p2 = plot(df.beta, df.deaths,
    xlabel = "β",
    ylabel = "Число умерших",
    linewidth = 2,
    color = :green,
    label = "Умершие"
)

p3 = plot(df.beta, df.final_rec,
    xlabel = "β",
    ylabel = "Доля выздоровевших",
    linewidth = 2,
    color = :purple,
    label = "Выздоровевшие"
)

plot(p1, p2, p3,
    layout = (3, 1),
    size = (800, 900)
)

savefig(plotsdir("comprehensive_analysis.png"))

println("График сохранён в: $(plotsdir("comprehensive_analysis.png"))")
