"""
    CUDAExt

NVIDIA GPUs for UnifiedBackend, loaded with CUDA.jl: when CUDA works on this machine (asked when the package loads,
not when it precompiles), each GPU is registered as a device with `CUDABackend()` and `CuArray`, and
`device_wakeup!` makes one the current device.
"""
module CUDAExt

using CUDA
import UnifiedBackend

function __init__()
    if CUDA.functional()
        UnifiedBackend.register_gpus!(UnifiedBackend.get_backend(), :CUDA, "NVIDIA", CUDABackend(), CuArray,
                                      collect(CUDA.devices()), CUDA.name)
    else
        @info "CUDA.jl is loaded, but CUDA does not work on this machine: no NVIDIA GPU registered"
    end
    return nothing
end

function UnifiedBackend.device_wakeup!(handle::CuDevice)
    CUDA.device!(handle)
    return nothing
end

end
