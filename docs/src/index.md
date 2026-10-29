```@meta
CurrentModule = UnifiedBackend
```

# UnifiedBackend.jl

Where KernelAbstractions kernels can run on this machine: the host (the CPU, registered when the package loads) and
the GPUs that CUDA.jl or AMDGPU.jl registers when loaded (see [Extensions](extensions.md)). Each `Platform` carries
the backend that runs kernels there and the array type that holds data there.

```julia
using UnifiedBackend
using CUDA                       # optional: registers NVIDIA GPUs (AMDGPU for AMD ones)

p = select_platform("device")   # the first GPU, or the host when there is none (it says so)
activate!(p)                    # make it the current device; nothing to do for a host
p.backend                       # the KernelAbstractions backend: CUDABackend(), ROCBackend() or CPU()
p.arraytype                     # the array type for its data: CuArray, ROCArray or Array

a = p.arraytype(rand(1000))     # data on the platform
kernel!(p.backend)(a; ndrange=length(a))
```

See the [API Reference](api.md).
