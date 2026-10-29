"""
    UnifiedBackend

Where KernelAbstractions kernels can run on this machine: a registry of platforms, the host (the CPU, registered when
the package loads) and the devices (GPUs, registered by the CUDA and ROCm extensions when CUDA.jl or AMDGPU.jl is
loaded and works). Each `Platform` carries the KernelAbstractions backend that runs kernels there and the array type
that holds data there.

```julia
using UnifiedBackend
p = select_platform("device")   # the first GPU, or the host when there is none
activate!(p)                    # make it the current device (nothing to do for a host)
p.backend, p.arraytype          # e.g. CUDABackend(), CuArray
```

`host_platforms()` and `device_platforms()` list what is registered; `register!` adds a platform (a test can register
a stand-in device).
"""
module UnifiedBackend

using KernelAbstractions

export Platform, host_platforms, device_platforms, register!, select_platform, activate!

include("platform.jl")
include("select.jl")

function __init__()
    empty!(HOSTS)
    register!(host_platform())
    return nothing
end

end
