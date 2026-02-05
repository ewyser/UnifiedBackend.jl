"""
    UnifiedBackend

A unified backend abstraction layer for CPU and GPU execution in Julia.

# Overview
UnifiedBackend provides a consistent interface for managing and executing code across
different computational backends (CPU, CUDA, ROCm, Metal) with automatic device detection
and runtime configuration.

# Features
- Automatic CPU architecture detection (x86_64, aarch64)
- GPU backend support (CUDA, ROCm via extensions)
- Device selection with interactive prompts
- Distributed multi-device execution
- Backend configuration management

# Main Components
- `Backend`: Top-level configuration structure
- `ExecutionPlatforms`: Host/device execution platform registry
- `add_backend!`: Initialize available execution platforms
- `select_execution_backend`: Choose and configure devices

# Example
```julia
using UnifiedBackend

# Access the global backend configuration
backend = UnifiedBackend.BACKEND

# Select execution backend
devices = select_execution_backend(backend.exec, "host")  # Use CPU
devices = select_execution_backend(backend.exec, "device")  # Use GPU if available
```
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
    # Initialize execution backend
    invokelatest(add_backend!, bckd.exec, Val(:x86_64))
    
    # Welcome log
    # welcome_log() 
end

# Accessor function
backend() = bckd

export backend

end
