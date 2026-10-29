"""
    ROCmExt

AMD GPUs for UnifiedBackend, loaded with AMDGPU.jl: when ROCm works on this machine (asked when the package loads,
not when it precompiles), each GPU is registered as a device with `ROCBackend()` and `ROCArray`, and
`device_wakeup!` makes one the current device.
"""
module ROCmExt

using AMDGPU
import UnifiedBackend

function __init__()
    if AMDGPU.functional()
        UnifiedBackend.register_gpus!(UnifiedBackend.get_backend(), :ROCm, "AMD", ROCBackend(), ROCArray,
                                      collect(AMDGPU.devices()), AMDGPU.HIP.name)
    else
        @info "AMDGPU.jl is loaded, but ROCm does not work on this machine: no AMD GPU registered"
    end
    return nothing
end

function UnifiedBackend.device_wakeup!(handle::HIPDevice)
    AMDGPU.device!(handle)
    return nothing
end

end
