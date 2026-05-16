using DrWatson
@quickactivate "project"
include(srcdir("MMc.jl"))
using .MMc
using StableRNGs
using Plots

# Запуск симуляции
rng = StableRNG(123)
data = MMc.setup_and_run(rng)

# Вывод статистики
MMc.print_stats(data)

# Построение и сохранение графиков
p = MMc.plot_results(data)
savefig(plotsdir("mmc_results.png"))
println("\nГрафик сохранён в plots/mmc_results.png")

# Отображение графика
display(p)