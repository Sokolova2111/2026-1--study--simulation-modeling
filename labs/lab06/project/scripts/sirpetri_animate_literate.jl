# # Анимация динамики SIR (линия через состояния)
# 
# Анимация показывает, как меняется численность групп S, I, R
# в виде линии, соединяющей точки (S, I, R) на каждом кадре.
# По оси X — группы, по оси Y — численность.
# 
# На анимации видно:
# - На первых кадрах S = 990, I = 10, R = 0
# - Постепенно S падает, I растёт
# - В момент пика I достигает максимума, затем снижается
# - R растёт и выходит на плато
# - Волна инфекции проходит через популяцию

# ## Подключение модулей

using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using Plots

# ## Параметры модели

β = 0.3      # Коэффициент заражения
γ = 0.1      # Коэффициент выздоровления
tmax = 100.0 # Время симуляции

# ## Создание сети Петри

net, u0, states = build_sir_network(β, γ)

# ## Детерминированная симуляция

df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.5, rates = [β, γ])

# ## Настройка осей

x_positions = [1, 2, 3]
labels = ["S", "I", "R"]

# ## Создание анимации

anim = @animate for i in 1:length(df.time)
    # Текущие значения
    S_val = round(Int, df.S[i])
    I_val = round(Int, df.I[i])
    R_val = round(Int, df.R[i])
    t_val = round(df.time[i], digits=1)
    
    # График: линия через точки (S, I, R)
    plot(
        x_positions,
        [S_val, I_val, R_val],
        label = "Population",
        marker = :circle,
        markersize = 8,
        linewidth = 2,
        xlabel = "Compartment",
        ylabel = "Population",
        title = "SIR dynamics at t = $t_val",
        xticks = (x_positions, labels),
        ylims = (0, 1000),
        color = :blue,
    )
end

# ## Сохранение GIF

gif_path = plotsdir("sir_animation_line.gif")
gif(anim, gif_path, fps = 10)

# ## Отображение GIF в Jupyter Notebook
# 
# Следующая команда показывает сохранённую анимацию прямо в ноутбуке.

display("text/html", "<img src=\"$(gif_path)\" alt=\"SIR Animation\" style=\"max-width:100%;\">")

# ## Вывод

println("Анимация сохранена в $gif_path")
println("На анимации видно:")
println("- S постепенно падает от 990 до почти 0")
println("- I растёт, достигает пика, затем снижается")
println("- R растёт и выходит на плато около 990")