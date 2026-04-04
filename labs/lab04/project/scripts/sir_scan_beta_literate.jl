# # Модель SIR: Параметрическое сканирование коэффициента заразности β
# 
# **Цель работы:** Исследовать, как изменение базовой заразности (β) влияет на 
# эпидемические показатели: пик заболеваемости, долю переболевших и число умерших.
# 
# ## 1. Инициализация проекта и загрузка пакетов

using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV, Random, Statistics
include(srcdir("sir_model.jl"))

# ## 2. Функция запуска одного эксперимента
# 
# Для заданного значения β инициализируется модель, выполняется симуляция
# и возвращаются метрики: пик эпидемии, финальная доля инфицированных,
# финальная доля выздоровевших, общее число умерших.

function run_experiment(p)
    # Создаём β_und и β_det на основе скалярного beta
    beta = p[:beta]
    β_und = fill(beta, 3)
    β_det = fill(beta/10, 3)
    
    # Передаём в модель
    model = initialize_sir(;
        Ns = p[:Ns],
        β_und = β_und,
        β_det = β_det,
        infection_period = p[:infection_period],
        detection_time = p[:detection_time],
        death_rate = p[:death_rate],
        reinfection_probability = p[:reinfection_probability],
        Is = p[:Is],
        seed = p[:seed],
    )
    
    infected_fraction(model) = count(a.status == :I for a in allagents(model)) / nagents(model)
    peak_infected = 0.0
    
    for step = 1:p[:n_steps]
        Agents.step!(model, 1)
        frac = infected_fraction(model)
        if frac > peak_infected
            peak_infected = frac
        end
    end
    
    final_infected = infected_fraction(model)
    final_recovered = count(a.status == :R for a in allagents(model)) / nagents(model)
    total_deaths = sum(p[:Ns]) - nagents(model)
    
    return (
        peak = peak_infected,
        final_inf = final_infected,
        final_rec = final_recovered,
        deaths = total_deaths,
    )
end

# ## 3. Параметры сканирования
# 
# - Диапазон значений β: от 0.1 до 1.0 с шагом 0.1
# - Для каждого значения выполняется 3 прогона с разными seed (42, 43, 44)
# - Остальные параметры фиксированы

beta_range = 0.1:0.1:1.0
seeds = [42, 43, 44]

# Создаём список параметров
params_list = []
for b in beta_range
    for s in seeds
        push!(
            params_list,
            Dict(
                :beta => b,
                :Ns => [1000, 1000, 1000],
                :infection_period => 14,
                :detection_time => 7,
                :death_rate => 0.02,
                :reinfection_probability => 0.1,
                :Is => [0, 0, 1],
                :seed => s,
                :n_steps => 100,
            )
        )
    end
end

# ## 4. Запуск экспериментов
# 
# Для каждой комбинации параметров запускается симуляция,
# результаты собираются в список.

results = []
for params in params_list
    data = run_experiment(params)
    push!(results, merge(params, Dict(pairs(data))))
    println("Завершен эксперимент с beta = $(params[:beta]), seed = $(params[:seed])")
end

# ## 5. Сохранение результатов
# 
# Все прогоны сохраняются в CSV-файл для последующего анализа.

df = DataFrame(results)
CSV.write(datadir("beta_scan_all.csv"), df)

# ## 6. Усреднение по повторным прогонам
# 
# Для каждого значения β усредняем показатели по трём seed.

grouped = combine(
    groupby(df, [:beta]),
    :peak => mean => :mean_peak,
    :final_inf => mean => :mean_final_inf,
    :deaths => mean => :mean_deaths,
)

# ## 7. Визуализация результатов
# 
# Строим график зависимости от β:
# - Пик эпидемии (доля инфицированных в максимуме)
# - Конечная доля инфицированных
# - Доля умерших (нормированная на численность населения)

plot(
    grouped.beta,
    grouped.mean_peak,
    label = "Пик эпидемии",
    xlabel = "Коэффициент заразности β",
    ylabel = "Доля инфицированных",
    marker = :circle,
    linewidth = 2,
)
plot!(
    grouped.beta,
    grouped.mean_final_inf,
    label = "Конечная доля инфицированных",
    marker = :square,
)
plot!(
    grouped.beta,
    grouped.mean_deaths ./ 3000,
    label = "Доля умерших",
    marker = :diamond,
)
savefig(plotsdir("beta_scan.png"))

# ## 8. Вывод информации о завершении

println("Результаты сохранены в data/beta_scan_all.csv и plots/beta_scan.png")