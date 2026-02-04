export Backend, Execution

"""
    Execution

Mutable struct representing the execution backend configuration for CPU and GPU devices.

# Fields
- `functional::Vector{String}`: List of available/initialized execution platforms
- `cpu::Dict{Symbol,Dict{Symbol,Any}}`: CPU device configurations indexed by device symbol (e.g., :dev1, :dev2)
- `gpu::Dict{Symbol,Dict{Symbol,Any}}`: GPU device configurations indexed by device symbol (e.g., :dev1, :dev2)

# Example
```julia
exec = Execution()
add_backend!(exec, Val(:x86_64))
```
"""
Base.@kwdef mutable struct Execution
    functional::Vector{String} = String["Available execution platform(s):"]
	cpu::Dict{Symbol,Dict{Symbol,Any}} = Dict{Symbol,Dict{Symbol,Any}}()
	gpu::Dict{Symbol,Dict{Symbol,Any}} = Dict{Symbol,Dict{Symbol,Any}}()
end

"""
    Backend

Mutable struct representing the unified backend system configuration.

# Fields
- `lib::Dict{String,Any}`: Library/module registry for loaded components
- `exec::Execution`: Execution backend configuration for CPU/GPU devices

# Example
```julia
backend = Backend(
    lib = Dict{String,Any}(),
    exec = Execution()
)
```
"""
Base.@kwdef mutable struct Backend
    lib::Dict{String,Any} = Dict{String,Any}()
	exec::Execution
end