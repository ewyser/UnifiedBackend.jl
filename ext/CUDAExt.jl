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

b = backend()

# Check if CUDA devices were registered
if !isempty(b.exec.device)
    println("CUDA GPUs available: ", length(b.exec.device))
    
    # Select GPU
    gpu = select_execution_backend(b.exec, "device")
    
    # Access CUDA-specific properties
    println(gpu.dev1[:name])      # "NVIDIA GeForce RTX 3090"
    println(gpu.dev1[:Backend])   # CUDABackend()
    println(gpu.dev1[:wrapper])   # CuArray
    println(gpu.dev1[:handle])    # CuDevice(0)
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
    add_backend!(Val(:CUDA), backend())
catch e
    @warn """
    ⚠️ CUDA extension failed to load.
    
    To enable CUDA support:
      1. Install CUDA.jl in your base environment:
         ] activate
         ] add CUDA
      2. Restart Julia and load UnifiedBackend
    
    Error: $e
    """
end

end