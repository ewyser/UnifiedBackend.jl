export Backend, ExecutionPlatforms

"""
    ExecutionPlatforms

Mutable struct representing the execution platform configuration for host (CPU) and device (GPU).

# Fields
- `functional::Vector{String}`: List of available/initialized execution platforms
- `host::Dict{Symbol,Dict{Symbol,Any}}`: Host (CPU) device configurations indexed by device symbol (e.g., :dev1, :dev2)
- `device::Dict{Symbol,Dict{Symbol,Any}}`: Device (GPU) configurations indexed by device symbol (e.g., :dev1, :dev2)

# Example
```julia
exec = ExecutionPlatforms()
add_backend!(exec, Val(:x86_64))
```
"""
Base.@kwdef mutable struct ExecutionPlatforms
    functional::Vector{String} = String["Available execution platform(s):"]
    host  ::Dict{Symbol,Dict{Symbol,Any}} = Dict()  
    device::Dict{Symbol,Dict{Symbol,Any}} = Dict()
end

"""
    Backend

Immutable struct representing the unified backend system configuration.

# Fields
- `lib::Dict{String,Any}`: Library/module registry for loaded components
- `exec::ExecutionPlatforms`: Execution platform configuration for host and device backends

# Example
```julia
backend = Backend(
    lib = Dict{String,Any}(),
    exec = ExecutionPlatforms()
)
```
"""
Base.@kwdef struct Backend
    lib::Dict{String,Any} = Dict{String,Any}()
	exec::ExecutionPlatforms
end