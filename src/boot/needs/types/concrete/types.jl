export Backend, ExecutionPlatforms

"""
    ExecutionPlatforms

Mutable struct representing the execution platform configuration for host (CPU) and device (GPU).

This structure maintains the registry of available computational devices and their configurations.
It is designed to be populated at runtime as backends are initialized and devices are detected.

# Fields

- `functional::Vector{String}`: List of successfully initialized execution platforms with status messages
- `host::Dict{Symbol,Dict{Symbol,Any}}`: Host (CPU) device configurations, indexed by device symbols (`:dev1`, `:dev2`, etc.)
- `device::Dict{Symbol,Dict{Symbol,Any}}`: Accelerator (GPU) device configurations, indexed by device symbols

# Host/Device Configuration Keys

Each device dictionary contains:
- `:host` or `:dev`: Device category ("cpu" or "gpu")
- `:platform`: Platform identifier (`:CPU`, `:CUDA`, `:ROCm`, etc.)
- `:brand`: Manufacturer brand (e.g., "Intel", "AMD", "NVIDIA")
- `:name`: Specific device model name
- `:Backend`: KernelAbstractions backend instance
- `:wrapper`: Array wrapper type (`Array`, `CuArray`, `ROCArray`, etc.)
- `:handle`: Device handle for direct device manipulation

# Examples

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
println(cpu_dev[:name])      # "Intel(R) Core(TM) i9-9900K..."
println(cpu_dev[:platform])  # :CPU
println(cpu_dev[:Backend])   # CPU()

# After loading CUDA
using CUDA
# GPU devices automatically registered in exec.device
gpu_dev = exec.device[:dev1]
println(gpu_dev[:brand])     # "NVIDIA"
```

# See Also

- [`Backend`](@ref): Top-level configuration containing an `ExecutionPlatforms` instance
- [`add_backend!`](@ref): Function to populate this structure with available devices
- [`select_execution_backend`](@ref): Select devices from this registry
"""
Base.@kwdef mutable struct ExecutionPlatforms
    functional::Vector{String} = String["Available execution platform(s):"]
    host  ::Dict{Symbol,Dict{Symbol,Any}} = Dict()  
    device::Dict{Symbol,Dict{Symbol,Any}} = Dict()
end

"""
    Backend

Immutable struct representing the unified backend system configuration.

This is the top-level configuration structure that manages the entire UnifiedBackend session.
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
b = backend()

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
    exec = ExecutionPlatforms()
)
```

# Global Instance

UnifiedBackend maintains a global singleton instance accessed via [`backend()`](@ref):

```julia
b = backend()
devices = select_execution_backend(b.exec, "host")
```

# See Also

- [`ExecutionPlatforms`](@ref): Execution platform registry structure
- [`backend`](@ref): Accessor for the global `Backend` instance
- [`select_execution_backend`](@ref): Device selection function
"""
Base.@kwdef struct Backend
    lib::Dict{String,Any} = Dict{String,Any}()
	exec::ExecutionPlatforms
end