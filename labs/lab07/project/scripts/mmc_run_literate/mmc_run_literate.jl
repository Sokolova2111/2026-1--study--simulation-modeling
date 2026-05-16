# Подключение модулей

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

# Построение графиков

p = MMc.plot_results(data)

# Сохранение графика

savefig(plotsdir("mmc_results.png"))
println("График сохранён в plots/mmc_results.png")

# Отображение графика в Jupyter Notebook

display(p)

# Выводы
