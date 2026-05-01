using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using Plots

# Параметры
β = 0.3
γ = 0.1
tmax = 100.0

# Создаём сеть
net, u0, states = build_sir_network(β, γ)

# Детерминированная симуляция
df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.5, rates = [β, γ])

# Позиции на оси X
x_positions = [1, 2, 3]
labels = ["S", "I", "R"]

# Создание анимации
anim = @animate for i in 1:length(df.time)
    # Текущие значения
    S_val = df.S[i]
    I_val = df.I[i]
    R_val = df.R[i]
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

# Сохранение GIF
gif(anim, plotsdir("sir_animation.gif"), fps = 10)
println("Анимация сохранена в plots/sir_animation_line.gif")