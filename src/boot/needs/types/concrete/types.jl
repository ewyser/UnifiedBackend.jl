#============================================================================================================================================================================================
============================================================================================================================================================================================#
# Exports
export Host, Device, ExecutionPlatforms, Backend

#============================================================================================================================================================================================
============================================================================================================================================================================================#
# Abstract and concrete device types
abstract type AbstractExecutionDevice end

#============================================================================================================================================================================================
============================================================================================================================================================================================#
"""
    Host

Struct representing a CPU (host) device configuration.

# Fields
- `category::Symbol`: Device category (`:cpu`)
- `platform::Symbol`: Platform identifier (e.g., `:CPU`)
- `brand::String`: Manufacturer brand (e.g., "Intel", "AMD")
- `name::String`: Specific device model name
- `Backend::Any`: KernelAbstractions backend instance
- `wrapper::Any`: Array wrapper type (e.g., `Array`)
- `handle::Any`: Device handle (unused for CPU)

# Example
```julia
Host(brand="AMD", name="AMD Ryzen 7 9800X3D", Backend=CPU())
```
"""
Base.@kwdef mutable struct Host <: AbstractExecutionDevice
    category::Symbol = :cpu
    platform::Symbol = :CPU
    brand::String = ""
    name::String = ""
    Backend::Any = nothing
    wrapper::Any = Array
    handle::Any = nothing
end

#============================================================================================================================================================================================
============================================================================================================================================================================================#
"""
    Device

Struct representing an accelerator (GPU) device configuration.

# Fields
- `category::Symbol`: Device category (`:gpu`)
- `platform::Symbol`: Platform identifier (e.g., `:CUDA`, `:ROCm`)
- `brand::String`: Manufacturer brand (e.g., "NVIDIA", "AMD")
- `name::String`: Specific device model name
- `Backend::Any`: KernelAbstractions backend instance
- `wrapper::Any`: Array wrapper type (e.g., `CuArray`, `ROCArray`)
- `handle::Any`: Device handle for direct device manipulation

# Example
```julia
Device(brand="NVIDIA", name="RTX 4090", Backend=CUDA())
```
"""
Base.@kwdef mutable struct Device <: AbstractExecutionDevice
    category::Symbol = :gpu
    platform::Symbol = :CUDA
    brand::String = ""
    name::String = ""
    Backend::Any = nothing
    wrapper::Any = nothing
    handle::Any = nothing
end

#============================================================================================================================================================================================
============================================================================================================================================================================================#
"""
    ExecutionPlatforms

Mutable struct representing the execution platform configuration for host (CPU) and device (GPU).

This structure maintains the registry of available computational devices and their configurations.
It is designed to be populated at runtime as backends are initialized and devices are detected.

# Fields
- `functional::Vector{String}`: List of successfully initialized execution platforms with status messages
- `host::Dict{Symbol,Host}`: Host (CPU) device configurations, indexed by device symbols (`:dev1`, `:dev2`, etc.)
- `device::Dict{Symbol,Device}`: Accelerator (GPU) device configurations, indexed by device symbols

# Example
```julia
using UnifiedBackend

# Create a new execution platforms registry
exec = ExecutionPlatforms()

# Populate with CPU backend
add_backend!(exec, Val(:x86_64))

# Check what's available
println(exec.functional)  # ["Available execution platform(s):", "✓ Intel x86_64"]

# Access first CPU device configuration
cpu_dev = exec.host[:dev1]
println(cpu_dev.name)      # "Intel(R) Core(TM) i9-9900K..."
println(cpu_dev.platform)  # :CPU
println(cpu_dev.Backend)   # CPU()

# After loading CUDA
using CUDA
# GPU devices automatically registered in exec.device
gpu_dev = exec.device[:dev1]
println(gpu_dev.brand)     # "NVIDIA"
```

# See Also
- [`Backend`](@ref): Top-level configuration containing an `ExecutionPlatforms` instance
- [`add_backend!`](@ref): Function to populate this structure with available devices
"""
Base.@kwdef mutable struct ExecutionPlatforms
    functional::Vector{String} = ["Available execution platform(s):"]
    host  ::Dict{Symbol,Host} = Dict()
    device::Dict{Symbol,Device} = Dict()
end

#============================================================================================================================================================================================
============================================================================================================================================================================================#
"""
    Backend

Immutable struct representing the unified backend system configuration.
    host  ::Hosts = Hosts()
    device::Devices = Devices()
It provides an immutable container for library tracking and execution platform management.
The structure itself is immutable, but the contained dictionaries and `ExecutionPlatforms`
are mutable, allowing runtime updates to device configurations.

# Fields

- `lib::Dict{String,Any}`: Library and module registry for loaded components and file tracking
- `exec::ExecutionPlatforms`: Mutable execution platform configuration for host and device backends

# Design Pattern

The `Backend` struct uses an immutable wrapper around mutable data pattern:
- The struct itself cannot be reassigned, ensuring singleton integrity
- The `lib` and `exec` fields can be mutated internally for runtime configuration updates
- This provides both safety and flexibility

# Examples

```julia
using UnifiedBackend

# Access the global backend instance
b = get_backend()

# Inspect library registry (populated by module loading system)
println(keys(b.lib))

# Access execution platforms
println(b.exec.functional)

# Get CPU devices
cpus = b.exec.host
for (dev_id, config) in cpus
    println("\$dev_id: \$(config[:name])")
end

# Create a custom backend (typically not needed - use global instance)
custom_backend = Backend(
    lib = Dict{String,Any}("custom" => "data"),
cpus = b.exec.host
)
```

# Global Instance

UnifiedBackend maintains a global singleton instance accessed via [`get_backend()`](@ref):

```julia
b = get_backend()
devices = select_execution_backend(b.exec, "host")
```

# See Also

- [`ExecutionPlatforms`](@ref): Execution platform registry structure
- [`get_backend`](@ref): Accessor for the global `Backend` instance
- [`select_execution_backend`](@ref): Device selection function
"""
Base.@kwdef struct Backend
    lib::Dict{String,Any} = Dict{String,Any}()
	exec::ExecutionPlatforms
end