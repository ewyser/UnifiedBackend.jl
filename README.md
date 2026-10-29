# UnifiedBackend

[![Build Status](https://github.com/ewyser/UnifiedBackend.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ewyser/UnifiedBackend.jl/actions/workflows/CI.yml?query=branch%3Amain)

Where [KernelAbstractions](https://github.com/JuliaGPU/KernelAbstractions.jl) kernels can run on this machine: the host
(the CPU) and, when CUDA.jl or AMDGPU.jl is loaded and works, its GPUs. Each `Platform` carries the backend that runs
kernels there and the array type that holds data there.

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

- `select_platform("host")` (the default) or `select_platform("device")`: one `Platform`.
- `host_platforms()`, `device_platforms()`: what is registered, in order; `register!(platform)` adds one (for
  instance a stand-in device in tests).
- A `Platform` has `kind` (`:host`, `:device`), `platform` (`:CPU`, `:CUDA`, `:ROCm`), `brand`, `name`, `backend`,
  `arraytype` and `handle` (the native device, `nothing` for the host).
- Any CPU is registered as the host, whatever its brand or architecture. GPUs are registered when their package loads,
  if it works on the machine at that time (not when the package was precompiled).
