using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using Plots

β = 0.3      # Коэффициент заражения
γ = 0.1      # Коэффициент выздоровления
tmax = 100.0 # Время симуляции

net, u0, states = build_sir_network(β, γ)

df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.5, rates = [β, γ])

x_positions = [1, 2, 3]
labels = ["S", "I", "R"]

anim = @animate for i in 1:length(df.time)

    S_val = round(Int, df.S[i])
    I_val = round(Int, df.I[i])
    R_val = round(Int, df.R[i])
    t_val = round(df.time[i], digits=1)

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

gif_path = plotsdir("sir_animation_line.gif")
gif(anim, gif_path, fps = 10)

display("text/html", "<img src=\"$(gif_path)\" alt=\"SIR Animation\" style=\"max-width:100%;\">")

println("Анимация сохранена в $gif_path")
println("На анимации видно:")
println("- S постепенно падает от 990 до почти 0")
println("- I растёт, достигает пика, затем снижается")
println("- R растёт и выходит на плато около 990")
