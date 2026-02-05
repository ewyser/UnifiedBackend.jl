export device_wakeup!, device_free!

"""
    device_wakeup!() -> Nothing

Stub function for activating a specific device.

This is a placeholder function that must be overloaded by backend extensions
(CUDAExt, ROCmExt) to provide device-specific wake-up functionality. Device
wake-up typically involves setting the active GPU context for subsequent operations.

# Backend Implementations

Extensions should implement:
- `device_wakeup!(::CuDevice)` for CUDA GPUs
- `device_wakeup!(::HIPDevice)` for ROCm GPUs

# Examples

```julia
# Will error - stub not overloaded
device_wakeup!()  # ErrorException

# After loading CUDA
using CUDA
gpu = select_execution_backend(backend().exec, "device")
device_wakeup!(gpu.dev1[:handle])  # Sets active CUDA device
```

# Errors

Throws `ErrorException` if called without backend extension loaded.

# See Also

- Extensions: `CUDAExt`, `ROCmExt`
- Device selection: [`select_execution_backend`](@ref)
"""
function device_wakeup!()
    throw(ErrorException("🚧 `device_wakeup!()` is a stub. It must be overloaded in CUDAExt, ROCmExt or MtlExt."))
end

"""
    device_free!(mesh, ::Val{:CPU}) -> Nothing

Free device memory for CPU backend and trigger garbage collection.

For CPU execution, this function simply calls Julia's garbage collector to
reclaim memory. GPU backend extensions may override this with device-specific
memory management.

# Arguments

- `mesh`: Any object whose memory should be freed (typically ignored for CPU)
- `::Val{:CPU}`: Type parameter specifying CPU backend

# Examples

```julia
# Free CPU memory
data = rand(1000, 1000)
device_free!(data, Val(:CPU))
# Triggers GC.gc()

# GPU backends would call device-specific free functions
# device_free!(gpu_data, Val(:CUDA))  # Would call CUDA.unsafe_free!
```

# Notes

This is primarily useful for consistency with GPU backends. For CPU-only
code, directly calling `GC.gc()` is equivalent.

# See Also

- `GC.gc()`: Julia's garbage collector
- Extensions: `CUDAExt`, `ROCmExt` (provide GPU-specific implementations)
"""
function device_free!(mesh,::Val{:CPU})
    GC.gc()
    return nothing
end
