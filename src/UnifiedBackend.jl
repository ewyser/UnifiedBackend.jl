"""
    UnifiedBackend

A unified backend abstraction layer for CPU and GPU execution in Julia.

# Overview

UnifiedBackend provides a consistent interface for managing and executing code across
different computational backends (CPU, CUDA, ROCm, Metal) with automatic device detection
and runtime configuration. The package automatically detects available hardware and 
provides a simple API for device selection and management.

# Features

- **Automatic CPU architecture detection**: Supports x86_64 and aarch64 architectures
- **GPU backend support**: CUDA and ROCm via package extensions
- **Interactive device selection**: Choose specific devices via terminal menus
- **Distributed multi-device execution**: Run on multiple CPUs or GPUs simultaneously
- **Backend configuration management**: Centralized configuration with runtime updates

# Main Components

- [`Backend`](@ref): Top-level immutable configuration structure
- [`ExecutionPlatforms`](@ref): Mutable host/device execution platform registry
- [`backend`](@ref): Accessor function for the global backend instance
- [`add_backend!`](@ref): Initialize available execution platforms
- [`select_execution_backend`](@ref): Choose and configure compute devices
- [`get_host`](@ref): Select CPU execution devices
- [`get_device`](@ref): Select GPU execution devices

# Quick Start

```julia
using UnifiedBackend

# Access the global backend configuration
b = backend()

# Use CPU (default - first core)
cpu_device = select_execution_backend(b.exec, "host")

# Use CPU with interactive selection
cpu_device = select_execution_backend(b.exec, "host", prompt=true)

# Use multiple CPU cores
cpu_devices = select_execution_backend(b.exec, "host", distributed=true)

# Use GPU (if available, otherwise falls back to CPU)
gpu_device = select_execution_backend(b.exec, "device")

# Use specific GPU with prompt
gpu_device = select_execution_backend(b.exec, "device", prompt=true)
```

# GPU Support

GPU support is provided through package extensions. Install the appropriate package:

```julia
# For NVIDIA GPUs
using Pkg
Pkg.add("CUDA")
using CUDA

# For AMD GPUs
Pkg.add("AMDGPU")
using AMDGPU
```

# See Also

- [`ExecutionPlatforms`](@ref): Device registry structure
- [`Backend`](@ref): Configuration structure
- [`select_execution_backend`](@ref): Main device selection function
"""
module UnifiedBackend

# Define module location as const
const SRC = @__DIR__

# Include dependencies
using Revise, Pkg, Test
using ProgressMeter, REPL.TerminalMenus

using KernelAbstractions, Adapt, Base.Threads
import KernelAbstractions.@atomic as @atom
import KernelAbstractions.Kernel as Cairn
import KernelAbstractions.synchronize as sync

# Include types
include(joinpath(SRC, "boot/include.jl"))
sucess = superInc(["boot/needs/types"]; root=SRC)

# Include API modules at precompile time
success = superInc(["home/api"]; root=SRC)

# Define global backend
const bckd = Backend(lib=Dict(), exec=ExecutionPlatforms())

function __init__()
    # Initialize execution backend based on system architecture
    invokelatest(add_backend!, bckd.exec, Val(Sys.ARCH))
    
    # Welcome log
    # welcome_log() 
end

"""
    backend() -> Backend

Get the global backend configuration instance.

Returns the singleton `Backend` instance that manages the execution platforms
and library registry for the entire UnifiedBackend session.

# Returns
- `Backend`: The global backend configuration object

# Examples
```julia
using UnifiedBackend

# Access the global backend
b = backend()

# Inspect available platforms
println(b.exec.functional)

# Access host devices
println(keys(b.exec.host))

# Access device (GPU) configurations
println(keys(b.exec.device))
```

# See Also
- [`Backend`](@ref): Backend configuration structure
- [`ExecutionPlatforms`](@ref): Execution platform registry
"""
backend() = bckd

export backend

end
