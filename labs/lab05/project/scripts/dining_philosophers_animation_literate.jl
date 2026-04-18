# # Анимация процесса обедающих философов
# 
# Данный скрипт создаёт анимацию, показывающую динамику маркировки
# сети Петри для задачи "Обедающие философы" во времени.
# Анимация наглядно демонстрирует возникновение deadlock в классической модели.

# ## Подключение модулей

using DrWatson
@quickactivate "project"
include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers
using Plots, Random

# ## Параметры модели
# 
# - `N` - количество философов (для упрощения визуализации берём 3)
# - `tmax` - максимальное время симуляции

N = 3
tmax = 30.0

# ## Построение классической сети Петри

net, u0, names = build_classical_network(N)

# Фиксируем seed для воспроизводимости результатов
Random.seed!(123)

# ## Запуск стохастической симуляции

df = simulate_stochastic(net, u0, tmax)

# ## Создание анимации
# 
# Каждый кадр анимации показывает текущую маркировку сети:
# - По оси X - позиции (Think_i, Hungry_i, Eat_i, Fork_i)
# - По оси Y - количество фишек в каждой позиции
# - Время отображается в заголовке

anim = @animate for row in eachrow(df)
    u = [row[col] for col in propertynames(row) if col != :time]
    bar(
        1:length(u),
        u,
        legend = false,
        ylims = (0, maximum(u0) + 1),
        xlabel = "Позиция",
        ylabel = "Фишки",
        title = "Время = $(round(row.time, digits=2))",
    )
    xticks!(1:length(u), string.(names), rotation = 45)
end

# ## Сохранение анимации

gif(anim, plotsdir("philosophers_simulation.gif"), fps = 2)
println("Анимация сохранена в plots/philosophers_simulation.gif")

# ## Интерпретация результатов
# 
# На анимации видно:
# 1. Философы переходят из состояния Think в Hungry, затем в Eat и обратно
# 2. Фишки перемещаются между позициями
# 3. В какой-то момент может наступить deadlock - все переходы становятся неактивными,
#    маркировка перестаёт меняться