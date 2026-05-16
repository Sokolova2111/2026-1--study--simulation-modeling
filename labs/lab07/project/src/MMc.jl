module MMc

using StableRNGs
using Distributions
using ConcurrentSim
using ResumableFunctions
using DataFrames
using Plots

export setup_and_run, plot_results

# параметры модели
num_customers = 100  # увеличил для статистики
num_servers = 2
mu = 1.0 / 2
lam = 0.9
arrival_dist = Exponential(1 / lam)
service_dist = Exponential(1 / mu)

# структура для хранения данных о клиентах
mutable struct CustomerData
    id::Int
    arrival_time::Float64
    service_start::Float64
    service_end::Float64
    waiting_time::Float64
    service_time::Float64
end

# поведение клиента с записью данных
@resumable function customer(env::Environment, server::Resource, id::Integer, 
                              t_a::Float64, d_s::Distribution, rng, data::Vector{CustomerData})
    @yield timeout(env, t_a)
    arrival = now(env)
    
    @yield request(server)
    service_start = now(env)
    
    service_duration = rand(rng, d_s)
    @yield timeout(env, service_duration)
    @yield release(server)
    service_end = now(env)
    
    push!(data, CustomerData(id, arrival, service_start, service_end,
                              service_start - arrival, service_duration))
end

# настройка и запуск симуляции
function setup_and_run(rng::StableRNG)
    sim = Simulation()
    server = Resource(sim, num_servers)
    arrival_time = 0.0
    data = Vector{CustomerData}()
    
    for i = 1:num_customers
        arrival_time += rand(rng, arrival_dist)
        @process customer(sim, server, i, arrival_time, service_dist, rng, data)
    end
    
    run(sim)
    return data
end

# построение графиков
function plot_results(data::Vector{CustomerData})
    df = DataFrame(data)
    
    # График 1: Время ожидания
    p1 = plot(df.waiting_time, marker=:circle, line=:auto,
              title="Waiting Time per Customer", xlabel="Customer", ylabel="Time", legend=false)
    
    # График 2: Время обслуживания
    p2 = plot(df.service_time, marker=:square, line=:auto,
              title="Service Time per Customer", xlabel="Customer", ylabel="Time", legend=false)
    
    # График 3: Гистограмма времени ожидания
    p3 = histogram(df.waiting_time, bins=20, title="Waiting Time Distribution",
                   xlabel="Waiting Time", ylabel="Frequency", legend=false)
    
    # График 4: Загрузка серверов (время прибытия и ухода)
    p4 = plot()
    for i in 1:nrow(df)
        plot!(p4, [df.arrival_time[i], df.service_end[i]], [1, 1], linewidth=5, 
              label=i==1 ? "Customer service" : "", color=:blue, alpha=0.5)
    end
    p4 = plot!(p4, title="Service Timeline", xlabel="Time", ylabel="Service", legend=true)
    
    # Объединяем все графики
    p_final = plot(p1, p2, p3, p4, layout=(2,2), size=(800, 600))
    
    return p_final
end

# вывод статистики
function print_stats(data::Vector{CustomerData})
    df = DataFrame(data)
    println("\n=== Статистика модели М/М/$num_servers ===")
    println("Количество обслуженных клиентов: $(nrow(df))")
    println("Среднее время ожидания: $(round(mean(df.waiting_time), digits=4))")
    println("Максимальное время ожидания: $(round(maximum(df.waiting_time), digits=4))")
    println("Среднее время обслуживания: $(round(mean(df.service_time), digits=4))")
    println("Общее время моделирования: $(round(maximum(df.service_end), digits=4))")
    
    # Загрузка системы
    total_busy = sum(df.service_time)
    total_time = maximum(df.service_end)
    utilization = total_busy / (num_servers * total_time)
    println("Загрузка системы (utilization): $(round(utilization, digits=4))")
end

end # module