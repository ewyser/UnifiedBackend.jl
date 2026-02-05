#__precompile__(false)
# Note: Install CUDA.jl in your default Julia environment (not as a cORIUm dependency)
# To enable: ] activate; add CUDA

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
      2. Restart Julia and load UnifiedBackend.jl again.
    
    Error: $e
    """
end

end