# Extensions

```@meta
CurrentModule = UnifiedBackend
```

GPUs come from package extensions, loaded with the GPU package. Each asks, when it loads, whether its GPUs work on
this machine (not when it was precompiled, so a cache built on a login node without a GPU still finds them on a GPU
node), registers each GPU with [`register_gpus!`](@ref UnifiedBackend.register_gpus!), and adds the
[`activate!`](@ref) method for its device handles.

| Package     | Extension | Backend         | Array type | Handle      | `activate!`        |
|:------------|:----------|:----------------|:-----------|:------------|:-------------------|
| CUDA.jl     | `CUDAExt` | `CUDABackend()` | `CuArray`  | `CuDevice`  | `CUDA.device!`     |
| AMDGPU.jl   | `ROCmExt` | `ROCBackend()`  | `ROCArray` | `HIPDevice` | `AMDGPU.device!`   |

```julia
using UnifiedBackend, CUDA
device_platforms()               # the NVIDIA GPUs, if CUDA works here
```

If the package loads but its GPUs do not work (no driver, no device), the extension says so and registers none;
`select_platform("device")` then returns the host.

A new platform is an extension of the same shape: in its `__init__`, `UnifiedBackend.register_gpus!(platform, brand,
backend, arraytype, handles, name)` when the package works, and an `UnifiedBackend.activate!(handle)` method.
