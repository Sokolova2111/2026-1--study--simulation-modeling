module Ross

using ResumableFunctions
using ConcurrentSim
using Distributions
using Random
using StableRNGs
using DataFrames
using Plots

export run_ross_simulation, plot_ross_results, print_stats

# Структура для хранения данных мониторинга
mutable struct StateRecord
    time::Float64
    spare::Int
end

# Поведение машины (оригинал из методички)
@resumable function machine(env::Environment, repair_facility::Resource, 
                             spares::Store{Process}, lambda::Float64, mu::Float64, rng::StableRNG)
    while true
        try
            @yield timeout(env, Inf)
        catch
        end
        @yield timeout(env, rand(rng, Exponential(lambda)))
        get_spare = take!(spares)
        @yield get_spare | timeout(env)
        if state(get_spare) != ConcurrentSim.idle
            @yield interrupt(value(get_spare))
        else
            throw(StopSimulation("No more spares!"))
        end
        @yield request(repair_facility)
        @yield timeout(env, rand(rng, Exponential(mu)))
        @yield release(repair_facility)
        @yield put!(spares, active_process(env))
    end
end

# Запуск начальных процессов (оригинал из методички)
@resumable function start_sim(env::Environment, repair_facility::Resource, 
                               spares::Store{Process}, N::Int, S::Int,
                               lambda::Float64, mu::Float64, rng::StableRNG)
    for i = 1:N
        proc = @process machine(env, repair_facility, spares, lambda, mu, rng)
        @yield interrupt(proc)
    end
    for i = 1:S
        proc = @process machine(env, repair_facility, spares, lambda, mu, rng)
        @yield put!(spares, proc)
    end
end

# Мониторинг состояния (упрощённый, только spare)
@resumable function monitor(env::Environment, spares::Store{Process}, 
                             history::Vector{StateRecord})
    while true
        push!(history, StateRecord(now(env), length(spares.items)))
        @yield timeout(env, 0.5)
    end
end

# Основная функция запуска
function run_ross_simulation(; N::Int=10, S::Int=3, num_repairers::Int=1,
                               lambda::Float64=100.0, mu::Float64=1.0, seed::Int=150)
    
    rng = StableRNG(seed)
    sim = Simulation()
    repair_facility = Resource(sim, num_repairers)
    spares = Store{Process}(sim)
    history = Vector{StateRecord}()
    
    @process start_sim(sim, repair_facility, spares, N, S, lambda, mu, rng)
    @process monitor(sim, spares, history)
    
    msg = run(sim)
    stop_time = now(sim)
    
    return (stop_time=stop_time, msg=msg, history=history, N=N, S=S, 
            num_repairers=num_repairers, lambda=lambda, mu=mu, seed=seed)
end

# Построение графиков
function plot_ross_results(result)
    history = result.history
    if isempty(history)
        println("Нет данных для построения графиков")
        return nothing
    end
    
    df = DataFrame(history)
    
    p = plot(df.time, df.spare, label="Spare machines", xlabel="Time", 
             ylabel="Number", title="Ross Model: Spare machines over time", 
             linewidth=2, color=:blue, marker=:circle, markersize=3)
    
    return p
end

# Вывод статистики
function print_stats(result)
    println("\n=== Статистика модели Росса ===")
    println("Параметры: N=$(result.N), S=$(result.S), ремонтников=$(result.num_repairers)")
    println("λ = $(result.lambda), μ = $(result.mu)")
    println("Результат: $(result.msg)")
    println("Время: $(round(result.stop_time, digits=2))")
    println("Записей мониторинга: $(length(result.history))")
    
    if !isempty(result.history)
        df = DataFrame(result.history)
        println("Среднее количество резервных машин: $(round(mean(df.spare), digits=2))")
        println("Минимум резервных машин: $(round(minimum(df.spare), digits=0))")
    end
end

end # module