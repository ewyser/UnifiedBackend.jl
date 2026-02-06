"""
    ROCmExt

Package extension providing AMD ROCm GPU support for UnifiedBackend.

This extension is automatically loaded when both UnifiedBackend and AMDGPU are available
in the Julia session. It registers ROCm-capable AMD GPUs in the execution platform registry
and enables GPU computation via KernelAbstractions.ROCBackend().

# Requirements

- Julia 1.9+ (for package extensions)
- AMDGPU.jl package installed
- AMD GPU with ROCm support
- ROCm runtime installation

# Installation

```julia
using Pkg
Pkg.add("AMDGPU")
```

# Usage

```julia
using UnifiedBackend
using AMDGPU  # Triggers automatic loading of ROCmExt

b = backend()

# Check if ROCm devices were registered
if !isempty(b.exec.device)
    println("ROCm GPUs available: ", length(b.exec.device))
    
    # Select GPU
    gpu = select_execution_backend(b.exec, "device")
    
    # Access ROCm-specific properties
    println(gpu.dev1[:name])      # "AMD Radeon RX 6900 XT"
    println(gpu.dev1[:Backend])   # ROCBackend()
    println(gpu.dev1[:wrapper])   # ROCArray
    println(gpu.dev1[:handle])    # HIPDevice(0)
end
```

# Registered Functions

- `add_backend!(::Val{:ROCm}, ::Backend)`: Detects and registers ROCm GPUs
- `device_wakeup!(::HIPDevice)`: Activates a specific ROCm device

# See Also

- `AMDGPU.jl`: AMD ROCm support for Julia
- `KernelAbstractions.ROCBackend`: Backend for GPU kernel execution
"""
module ROCmExt

@info "📦 Including extension module"

using UnifiedBackend
import UnifiedBackend: add_backend!

try
    @info "🔧 Using ROCm backend"
    using AMDGPU
    @info "🧠 ROCm 🔁 overloading stub functions..."
    include(joinpath(@__DIR__, "ROCmExt", "ROCm_backend.jl"))
    global rocm_success = true
catch e
    @warn """
    ⚠️ ROCm extension failed to load.
    
    To enable ROCm support:
      1. Install AMDGPU.jl in your base environment:
        using Pkg
        Pkg.activate()  # Activate your base environment
        Pkg.add("AMDGPU")
      2. Ensure ROCm runtime is installed on your system
      3. Restart Julia, and:
        using UnifiedBackend
        using AMDGPU  # Triggers automatic loading of ROCmExt

    Error: $e
    """
    global rocm_success = false
end

function __init__()
    if rocm_success
        add_backend!(Val(:ROCm), backend())
        return @info "✅ ROCm backend registered successfully"
    else
        return @info "❌ ROCm backend registration failed"
    end
end

end
