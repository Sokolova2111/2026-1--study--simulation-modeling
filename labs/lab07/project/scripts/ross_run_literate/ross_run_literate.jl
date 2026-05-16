# Подключение модулей

using DrWatson
@quickactivate "project"
include(srcdir("Ross.jl"))
using .Ross
using Plots

# Параметры модели

N = 10
S = 3
num_repairers = 1

println("=== Модель Росса ===")
println("N=$N, S=$S, ремонтников=$num_repairers")

# Запуск симуляции

result = run_ross_simulation(N=N, S=S, num_repairers=num_repairers, seed=123)

# Вывод статистики

print_stats(result)

# Построение и сохранение графиков

p = plot_ross_results(result)
if p !== nothing
    savefig(plotsdir("ross_results.png"))
    println("\nГрафик сохранён в plots/ross_results.png")
    display(p)
end

# Исследование влияния количества ремонтников

println("\n=== Исследование влияния количества ремонтников ===")
for r in [1, 2, 3]
    res = run_ross_simulation(N=10, S=3, num_repairers=r, seed=123)
    println("Ремонтников: $r, Время падения: $(round(res.stop_time, digits=2)), Результат: $(res.msg)")
end

# Выводы
