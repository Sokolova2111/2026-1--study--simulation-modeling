# # Модель SIR: Базовый эксперимент
# 
# **Цель работы:** Запустить эпидемиологическую модель SIR с параметрами по умолчанию
# и визуализировать динамику распространения инфекции в трёх городах.
# 
# Модель SIR делит популяцию на три группы:
# - **S (Susceptible)** — восприимчивые к заболеванию
# - **I (Infectious)** — инфицированные, способные заражать
# - **R (Recovered)** — выздоровевшие (или умершие), получившие иммунитет
# 
# ## 1. Инициализация проекта и загрузка пакетов

using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots
using JLD2
include(srcdir("sir_model.jl"))

# ## 2. Параметры эксперимента
# 
# Задаём параметры модели:
# - **Ns** — численность населения в трёх городах (по 1000 человек)
# - **β_und** — коэффициент заражения для невыявленных больных (0.5)
# - **β_det** — коэффициент заражения для выявленных больных (0.05)
# - **infection_period** — длительность болезни (14 дней)
# - **detection_time** — время до выявления заболевания (7 дней)
# - **death_rate** — вероятность летального исхода (2%)
# - **reinfection_probability** — вероятность повторного заражения (10%)
# - **Is** — начальное количество инфицированных в каждом городе (0, 0, 1)
# - **seed** — зерно генератора случайных чисел для воспроизводимости

params = Dict(
    :Ns => [1000, 1000, 1000],
    :β_und => [0.5, 0.5, 0.5],
    :β_det => [0.05, 0.05, 0.05],
    :infection_period => 14,
    :detection_time => 7,
    :death_rate => 0.02,
    :reinfection_probability => 0.1,
    :Is => [0, 0, 1],
    :seed => 42,
)

# ## 3. Инициализация модели
# 
# Создаём модель SIR с заданными параметрами. Агенты (люди) распределены по трём городам,
# соединённым полным графом (каждый город связан с каждым).

model = initialize_sir(; params...)

# ## 4. Сбор данных
# 
# Создаём массивы для хранения динамики численности групп S, I, R на каждом шаге.

times = Int[]
S_vals = Int[]
I_vals = Int[]
R_vals = Int[]
total_vals = Int[]

# ## 5. Запуск симуляции
# 
# Выполняем 100 дней симуляции. На каждом шаге:
# 1. Агенты мигрируют между городами
# 2. Инфицированные заражают восприимчивых
# 3. Инфицированные выздоравливают или умирают
# 
# Сохраняем текущее состояние популяции.

for step = 1:100
    Agents.step!(model, 1)
    push!(times, step)
    push!(S_vals, susceptible_count(model))
    push!(I_vals, infected_count(model))
    push!(R_vals, recovered_count(model))
    push!(total_vals, total_count(model))
end

# ## 6. Формирование DataFrame
# 
# Преобразуем собранные данные в таблицы для удобного анализа.

agent_df = DataFrame(time = times, susceptible = S_vals, infected = I_vals, recovered = R_vals)
model_df = DataFrame(time = times, total = total_vals)

# ## 7. Визуализация результатов
# 
# Строим график динамики эпидемии:
# - Синяя кривая — восприимчивые (S)
# - Красная кривая — инфицированные (I)
# - Зелёная кривая — выздоровевшие (R)
# - Пунктирная линия — общая численность населения (уменьшается из-за смертей)

plot(
    agent_df.time,
    agent_df.susceptible,
    label = "Восприимчивые",
    xlabel = "Дни",
    ylabel = "Количество",
)
plot!(agent_df.time, agent_df.infected, label = "Инфицированные")
plot!(agent_df.time, agent_df.recovered, label = "Выздоровевшие")
plot!(agent_df.time, model_df.total, label = "Всего (включая умерших)", linestyle = :dash)
savefig(plotsdir("sir_basic_dynamics.png"))

# ## 8. Сохранение данных
# 
# Сохраняем результаты в формате JLD2 для последующего анализа.

@save datadir("sir_basic_agent.jld2") agent_df
@save datadir("sir_basic_model.jld2") model_df

# ## 9. Вывод результатов в консоль
# 
# Печатаем основные показатели эпидемии.

println("\n=== РЕЗУЛЬТАТЫ ЭПИДЕМИИ ===")
println("Пик инфицированных: ", maximum(I_vals))
println("День пика: ", argmax(I_vals))
println("Всего выздоровело: ", maximum(R_vals))
println("Всего умерло: ", 3000 - total_count(model))
println("Доля переболевших: ", round(maximum(R_vals)/3000*100, digits=1), "%")