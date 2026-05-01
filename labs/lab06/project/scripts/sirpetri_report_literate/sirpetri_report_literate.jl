# Подключение модулей

using DrWatson
@quickactivate "project"
using DataFrames, CSV, Plots

# Загрузка результатов экспериментов

df_det = CSV.read(datadir("sir_det.csv"), DataFrame)
df_stoch = CSV.read(datadir("sir_stoch.csv"), DataFrame)
df_scan = CSV.read(datadir("sir_scan.csv"), DataFrame)

p1 = plot(
    df_det.time,
    [df_det.I df_stoch.I[1:length(df_det.time)]],
    label = ["Deterministic I" "Stochastic I"],
    xlabel = "Time",
    ylabel = "Infected",
    title = "Comparison: Deterministic vs Stochastic",
    linewidth = 2,
    color = ["blue" "red"],
)

# Сохранение графика
savefig(plotsdir("comparison.png"))

# Отображение графика в Jupyter Notebook
display(p1)

p2 = plot(
    df_scan.β,
    df_scan.peak_I,
    marker = :circle,
    markersize = 6,
    linewidth = 2,
    xlabel = "β (infection rate)",
    ylabel = "Peak I (maximum infected)",
    title = "Sensitivity: Peak I vs β",
    color = :green,
)

# Сохранение графика
savefig(plotsdir("sensitivity.png"))

# Отображение графика в Jupyter Notebook
display(p2)

println("Отчётные графики сохранены в plots/")
println("- comparison.png — сравнение детерминированной и стохастической динамики")
println("- sensitivity.png — зависимость пика I от β")
