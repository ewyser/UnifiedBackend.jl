""" 
    CUDAExt

Package extension providing NVIDIA CUDA GPU support for UnifiedBackend.

This extension is automatically loaded when both UnifiedBackend and CUDA are available
in the Julia session. It registers CUDA-capable GPUs in the execution platform registry
and enables GPU computation via KernelAbstractions.CUDABackend().

# Requirements

- Julia 1.9+ (for package extensions)
- CUDA.jl package installed
- NVIDIA GPU with CUDA support
- Compatible CUDA toolkit installation

# Installation

```julia
using Pkg
Pkg.add("CUDA")
```

# Usage

```julia
using UnifiedBackend
using CUDA  # Triggers automatic loading of CUDAExt

b = get_backend()

# Check if CUDA devices were registered
if !isempty(b.exec.device)
    println("CUDA GPUs available: ", length(b.exec.device))
    
    # Select GPU
    gpu = select_execution_backend(b.exec, "device")
    
    # Access CUDA-specific properties
    println(gpu[:dev1].name)      # "NVIDIA GeForce RTX 3090"
    println(gpu[:dev1].Backend)   # CUDABackend()
    println(gpu[:dev1].wrapper)   # CuArray
    println(gpu[:dev1].handle)    # CuDevice(0)
end
```

# Registered Functions

- `add_backend!(::Val{:CUDA}, ::Backend)`: Detects and registers CUDA GPUs
- `device_wakeup!(::CuDevice)`: Activates a specific CUDA device

# See Also

- `CUDA.jl`: NVIDIA CUDA support for Julia
- `KernelAbstractions.CUDABackend`: Backend for GPU kernel execution
"""
module CUDAExt

@info "📦 Including extension module"

using UnifiedBackend
import UnifiedBackend: add_backend!, device_wakeup!, device_free!

try
    @info "🔧 Using CUDA backend"
    using CUDA
    @info "🧠 CUDA 🔁 overloading stub functions..."
    include(joinpath(@__DIR__, "CUDAExt", "CUDA_backend.jl"))
    global cuda_success = true
catch e
    @warn """
    ⚠️ CUDA extension failed to load.
    
    To enable CUDA support:
      1. Install CUDA.jl in your base environment:
        using Pkg
        Pkg.activate()  # Activate your base environment
        Pkg.add("CUDA")
      2. Restart Julia, and:
        using UnifiedBackend
        using CUDA  # Triggers automatic loading of CUDAExt
    
    Error: $e
    """
    global cuda_success = false
end

# whether CUDA works is asked here, when the package loads, not while it precompiles: a cache built without a GPU
# (a login node, a container build) would otherwise never register one
function __init__()
    if cuda_success && CUDA.functional()
        @info "✅ CUDA extension loaded successfully. Registering CUDA backend..."
        add_backend!(Val(:CUDA), UnifiedBackend.get_backend())
        return nothing
    elseif cuda_success
        @info "🟡 CUDA extension loaded successfully but CUDA is not functional on this system."
        return nothing
    else
        @info "❌ CUDA backend registration failed"
        return nothing
    end

end

end