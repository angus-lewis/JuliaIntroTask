import DataStructures, Distributions, StableRNGs, Plots

abstract type Event end 

abstract type Arrival <: Event end 

struct RandomArrival <: Arrival
    t::Float64
end

struct ScheduledArrival <: Arrival
    t::Float64
end

struct Departure <: Event
    t::Float64
end

struct Parameters 
    seed::Int64
    mean_rand_interarrival_time::Float64
    mean_scheduled_interarrival_time::Float64
    mean_service_time::Float64
end

struct DES_RNG
    random_interarrival
    scheduled_interarrival
    service
end

function DES_RNG(p::Parameters)
    rng = StableRNGs.StableRNG(p.seed)
    rand_interarrival() = rand(rng,Distributions.Exponential(p.mean_rand_interarrival_time))
    scheduled_interarrival() = p.mean_scheduled_interarrival_time
    service() = rand(rng,Distributions.Exponential(p.mean_service_time))
    return DES_RNG(rand_interarrival,scheduled_interarrival,service)
end

mutable struct State
    t::Float64
    events::DataStructures.PriorityQueue{<:Event,Float64}
    n::Int64
end

function State() 
    s = State(0.0,DataStructures.PriorityQueue{Event,Float64}(),0)
    DataStructures.enqueue!(s.events,ScheduledArrival(0.0),0.0)
    DataStructures.enqueue!(s.events,RandomArrival(0.0),0.0)
    return s
end

function process_event(s::State,e::Event)
    throw(DomainError("event must be arrival or departure"))
end

function process_event(s::State,e::RandomArrival,rngs::DES_RNG)
    # move time to when arrival occurrs
    s.t = e.t
    s.n += 1

    # corresponding departure 
    corresponding_departure = Departure(s.t + rngs.service())
    DataStructures.enqueue!(s.events,corresponding_departure,corresponding_departure.t)

    # spawn new arrival 
    future_arrival = RandomArrival(s.t + rngs.random_interarrival())
    DataStructures.enqueue!(s.events,future_arrival,future_arrival.t)
end

function process_event(s::State,e::ScheduledArrival,rngs::DES_RNG)
    # move time to when arrival occurrs
    s.t = e.t
    s.n += 1

    # corresponding departure 
    corresponding_departure = Departure(s.t + rngs.service())
    DataStructures.enqueue!(s.events,corresponding_departure,corresponding_departure.t)

    # spawn new arrival 
    future_arrival = ScheduledArrival(s.t + rngs.scheduled_interarrival())
    DataStructures.enqueue!(s.events,future_arrival,future_arrival.t)
end

function process_event(s::State,e::Departure,rngs::DES_RNG)
    # move time to when arrival occurrs
    s.t = e.t
    s.n -= 1
end

function run_sim(p::Parameters,T::Float64)
    system = State()
    rngs = DES_RNG(p)

    events = Array{Any,2}(undef,0,3)
    while system.t < T
        next_event = DataStructures.dequeue!(system.events)
        process_event(system,next_event,rngs)
        events = [events; typeof(next_event) system.t system.n]
    end

    return events
end

p = Parameters(1.0,1.0,0.5,1)

events = run_sim(p,10.0)

times = [events[1:end-1,2]'; events[2:end,2]'][:]
n = [events[1:end-1,3]'; events[1:end-1,3]'][:]

Plots.plot(times,n)