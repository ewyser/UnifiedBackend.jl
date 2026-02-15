export get_host, get_device, select_execution_backend

"""
    get_host(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false) -> NamedTuple

Select and return host (CPU) execution device(s) from the available configurations.

This function provides three selection modes:
- **Default**: Returns the first CPU device (`:dev1`)
- **Interactive** (`prompt=true`): Shows a radio menu to select a single device
- **Distributed** (`distributed=true`): Shows a multi-select menu for multiple devices

# Arguments

- `bckd::ExecutionPlatforms`: The execution platform registry containing host devices
- `prompt::Bool=false`: Enable interactive single-device selection
- `distributed::Bool=false`: Enable multi-device selection

# Returns

`NamedTuple` where:
- Keys are device symbols (`:dev1`, `:dev2`, etc.)
- Values are device configuration dictionaries

# Examples

```julia
using UnifiedBackend

b = backend()

# Get first CPU device (default)
cpu = get_host(b.exec)
# (dev1 = Dict(:name => "Intel...", :platform => :CPU, ...),)

# Interactive selection - shows menu
cpu = get_host(b.exec, prompt=true)

# Multi-device selection - shows checkboxes
cpus = get_host(b.exec, distributed=true)
# (dev1 = Dict(...), dev3 = Dict(...), dev5 = Dict(...),)

# Access device properties
println(cpu.dev1[:name])     # "Intel(R) Core(TM) i9-9900K..."
println(cpu.dev1[:Backend])  # CPU()
```

# Interactive Menus

When `prompt=true` or `distributed=true`, displays terminal menus using REPL.TerminalMenus:
- Use arrow keys to navigate
- Press Enter to confirm (radio menu)
- Use Space to toggle, Enter to confirm (multi-select menu)

# See Also

- [`get_device`](@ref): GPU device selection
- [`select_execution_backend`](@ref): High-level backend selection
- [`ExecutionPlatforms`](@ref): Device registry structure
"""
function get_host(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)
    cpus,devs,names = Dict(),collect(keys(bckd.host)),Vector{String}()
    for key ∈ devs
        push!(names, bckd.host[key].name)
    end
    if distributed
        for dev ∈ request("select device(s):", MultiSelectMenu(names))
            cpus[devs[dev]] = bckd.host[devs[dev]]
        end
        return NamedTuple(cpus)
    elseif prompt
        dev = request("select device:", RadioMenu(names))
        return NamedTuple(Dict(devs[dev] => bckd.host[devs[dev]]))
    else
        return NamedTuple(Dict(:dev1 => bckd.host[:dev1]))
    end
end

"""
    get_device(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false) -> NamedTuple

Select and return accelerator (GPU) execution device(s) from the available configurations.

This function provides three selection modes for GPU devices:
- **Default**: Returns the first GPU device
- **Interactive** (`prompt=true`): Shows a radio menu to select a specific GPU
- **Distributed** (`distributed=true`): Shows a multi-select menu for multiple GPUs

# Arguments

- `bckd::ExecutionPlatforms`: The execution platform registry containing device (GPU) configurations
- `prompt::Bool=false`: Enable interactive single-device selection
- `distributed::Bool=false`: Enable multi-device selection

# Returns

`NamedTuple` where:
- Keys are device symbols (`:dev1`, `:dev2`, etc.)
- Values are GPU configuration dictionaries

# GPU Configuration

Each GPU device contains:
- `:dev`: "gpu"
- `:platform`: `:CUDA`, `:ROCm`, etc.
- `:brand`: "NVIDIA", "AMD", etc.
- `:name`: Full GPU model name
- `:Backend`: KernelAbstractions backend (`CUDABackend()`, `ROCBackend()`)
- `:wrapper`: Array type (`CuArray`, `ROCArray`)
- `:handle`: Native device handle (`CuDevice`, `HIPDevice`)

# Examples

```julia
using UnifiedBackend, CUDA

b = backend()

# Get first GPU (default)
gpu = get_device(b.exec)
# (dev1 = Dict(:name => "NVIDIA GeForce RTX 3090", :platform => :CUDA, ...),)

# Interactive selection
gpu = get_device(b.exec, prompt=true)

# Multi-GPU selection
gpus = get_device(b.exec, distributed=true)
# (dev1 = Dict(...), dev2 = Dict(...),)

# Access GPU properties
println(gpu.dev1[:name])      # "NVIDIA GeForce RTX 3090"
println(gpu.dev1[:platform])  # :CUDA
println(gpu.dev1[:Backend])   # CUDABackend()
println(gpu.dev1[:wrapper])   # CuArray

# Use device handle for manual control
CUDA.device!(gpu.dev1[:handle])
```

# Requirements

GPU devices are only available after loading the appropriate package:
- **NVIDIA**: `using CUDA`
- **AMD**: `using AMDGPU`

If no GPUs are registered, this function will error. Use [`select_execution_backend`](@ref)
for automatic fallback to CPU.

# See Also

- [`get_host`](@ref): CPU device selection
- [`select_execution_backend`](@ref): High-level backend selection with fallback
- [`ExecutionPlatforms`](@ref): Device registry structure
"""
function get_device(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)
    devs, names = collect(keys(bckd.device)), Vector{String}()
    for key ∈ devs
        push!(names, bckd.device[key].name)
    end
    gpus = Dict()
    if distributed
        for dev ∈ request("select device(s):", MultiSelectMenu(names))
            gpus[devs[dev]] = bckd.device[devs[dev]]
        end
        return NamedTuple(gpus)
    elseif prompt
        dev = request("select device:", RadioMenu(names))
        return NamedTuple(Dict(devs[dev] => bckd.device[devs[dev]]))
    else
        return NamedTuple(Dict(devs[1] => bckd.device[devs[1]]))
    end
end

"""
    select_execution_backend(
        bckd::ExecutionPlatforms, 
        select::String="host"; 
        prompt::Bool=false, 
        distributed::Bool=false
    ) -> NamedTuple

High-level function to select execution backend (CPU or GPU) with automatic fallback.

This is the primary interface for backend selection in UnifiedBackend. It provides
a simple string-based API to choose between host (CPU) and device (GPU) execution,
with automatic fallback to CPU if no GPU is available.

# Arguments

- `bckd::ExecutionPlatforms`: The execution platform registry
- `select::String="host"`: Backend type - `"host"` for CPU, `"device"` for GPU
- `prompt::Bool=false`: Enable interactive device selection menu
- `distributed::Bool=false`: Enable multi-device selection

# Selection Modes

Three modes available via keyword arguments:

1. **Default mode** (`prompt=false, distributed=false`):
   - Returns first available device
   - No user interaction
   - Best for scripts and non-interactive use

2. **Interactive mode** (`prompt=true`):
   - Shows radio menu for single device selection
   - User chooses one device from list
   - Ideal for targeting specific hardware

3. **Distributed mode** (`distributed=true`):
   - Shows multi-select checkbox menu
   - User chooses multiple devices
   - For parallel/distributed computations

# Returns

`NamedTuple` of device configurations. Structure depends on selection:
- Single device: `(dev1 = Dict(...),)`
- Multiple devices: `(dev1 = Dict(...), dev2 = Dict(...), ...)`

# GPU Fallback Behavior

When `select="device"`:
- If GPUs are available → returns selected GPU(s)
- If no GPUs found → automatically falls back to CPU
- Logs the fallback for user awareness

# Examples

```julia
using UnifiedBackend

b = backend()

# === CPU Examples ===

# Default: first CPU core
cpu = select_execution_backend(b.exec, "host")

# Interactive: choose specific core
cpu = select_execution_backend(b.exec, "host", prompt=true)

# Distributed: select multiple cores
cpus = select_execution_backend(b.exec, "host", distributed=true)

# === GPU Examples ===

using CUDA  # or AMDGPU

# Default: first GPU
gpu = select_execution_backend(b.exec, "device")

# Interactive: choose specific GPU (multi-GPU systems)
gpu = select_execution_backend(b.exec, "device", prompt=true)

# Multi-GPU computation
gpus = select_execution_backend(b.exec, "device", distributed=true)

# === Practical Usage ===

# Select backend and use in computation
devices = select_execution_backend(b.exec, "device")
backend_instance = devices.dev1[:Backend]
array_type = devices.dev1[:wrapper]

# Create array on selected backend
data = array_type(rand(1000, 1000))
```

# Error Handling

Throws `ArgumentError` if `select` is not `"host"` or `"device"`.

# Logging

Logs selection via `@info`:
- \"Using CPU backend (default mode)\"
- \"Using GPU backend (interactive mode)\"
- \"No GPU available, falling back to CPU backend\"

# See Also

- [`get_host`](@ref): Direct CPU device selection
- [`get_device`](@ref): Direct GPU device selection
- [`ExecutionPlatforms`](@ref): Device registry structure
- [`Backend`](@ref): Top-level configuration
"""
function select_execution_backend(bckd::ExecutionPlatforms, select::String="host"; prompt::Bool=false, distributed::Bool=false)
    mode = distributed ? "distributed" : (prompt ? "interactive" : "default")
    if select == "host"
        @info "Using CPU backend ($mode mode)"
        return get_host(bckd; prompt=prompt, distributed=distributed)
    elseif select == "device"
        if isempty(bckd.device)
            @info "No GPU available, falling back to CPU backend"
            return get_host(bckd; prompt=prompt, distributed=distributed)
        else
            @info "Using GPU backend ($mode mode)"
            return get_device(bckd; prompt=prompt, distributed=distributed)
        end
    else
        throw(ArgumentError("Invalid backend selection: '$(select)'. Use 'host' or 'device'"))
    end
end
