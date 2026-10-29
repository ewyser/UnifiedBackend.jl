"""
    Platform(kind, platform, brand, name, backend, arraytype, handle)
    Platform(; kind=:device, platform, brand="", name=string(platform), backend, arraytype, handle=nothing)

A place where kernels run: `kind` `:host` (a CPU) or `:device` (a GPU); its `platform` (`:CPU`, `:CUDA`, `:ROCm`, …),
`brand` and `name`; the KernelAbstractions `backend` that runs kernels there (`CPU()`, `CUDABackend()`, …); the
`arraytype` that holds data there (`Array`, `CuArray`, …); and the native `handle` a device is activated with
(`nothing` for a host).
"""
struct Platform{B,A,H}
    kind      :: Symbol
    platform  :: Symbol
    brand     :: String
    name      :: String
    backend   :: B
    arraytype :: A
    handle    :: H
    function Platform(kind::Symbol, platform::Symbol, brand::AbstractString, name::AbstractString, backend::B,
                      arraytype::A, handle::H) where {B,A,H}
        kind ∈ (:host, :device) || throw(ArgumentError("a platform's kind is :host or :device, not :$kind"))
        return new{B,A,H}(kind, platform, String(brand), String(name), backend, arraytype, handle)
    end
end
function Platform(; kind::Symbol=:device, platform::Symbol, brand::AbstractString="", name::AbstractString=string(platform),
                  backend, arraytype, handle=nothing)
    return Platform(kind, platform, brand, name, backend, arraytype, handle)
end

# the registry, in registration order: the host is registered when the package loads (__init__), the GPUs by the
# extensions when theirs load
const HOSTS   = Platform[]
const DEVICES = Platform[]

"""
    host_platforms() -> Vector{Platform}
    device_platforms() -> Vector{Platform}

The registered hosts (the CPU) and devices (GPUs), in registration order.
"""
function host_platforms()
    return HOSTS
end
function device_platforms()
    return DEVICES
end

"""
    register!(platform) -> platform

Add a platform to the registry: to `host_platforms()` or `device_platforms()`, by its `kind`.
"""
function register!(p::Platform)
    push!(p.kind == :host ? HOSTS : DEVICES, p)
    return p
end

"""
    register_gpus!(platform, brand, backend, arraytype, handles, name) -> device_platforms()

Register one device per native handle (`name(handle)` its name): what a GPU package's extension calls when it loads
and the GPU works (`CUDAExt`, `ROCmExt`).
"""
function register_gpus!(platform::Symbol, brand::AbstractString, backend, arraytype, handles, name)
    for h ∈ handles
        register!(Platform(:device, platform, brand, name(h), backend, arraytype, h))
    end
    return DEVICES
end

# the CPU brands known per architecture: a label only, every CPU is registered
const HOST_BRANDS = Dict(:x86_64 => ["Intel(R)", "AMD"], :aarch64 => ["Apple", "AMD"])

"""
    host_brand(model, brands) -> String

The first of `brands` that the CPU `model` string names, else `"unknown"`.

```julia
host_brand("Intel(R) Core(TM) i5-1038NG7", ["Intel(R)", "AMD"])  # "Intel(R)"
host_brand("Apple M2", ["Intel(R)", "AMD"])                     # "unknown" (x86_64 Julia under Rosetta)
```
"""
function host_brand(model::AbstractString, brands)
    i = findfirst(b -> occursin(b, model), brands)
    return isnothing(i) ? "unknown" : String(brands[i])
end

"""
    host_platform(arch=Sys.ARCH, model=<this CPU's model>) -> Platform

The host: a CPU of any architecture and brand (its brand `"unknown"` when the model names none of
`HOST_BRANDS[arch]`, its name the architecture when the model is unknown), run by KernelAbstractions' `CPU()` on `Array`s.
"""
function host_platform(arch::Symbol=Sys.ARCH, model::AbstractString=cpu_model())
    brand = host_brand(model, get(HOST_BRANDS, arch, String[]))
    return Platform(:host, :CPU, brand, isempty(model) ? string(arch) : model, CPU(), Array, nothing)
end
function cpu_model()
    info = Sys.cpu_info()
    return isempty(info) ? "" : String(strip(info[1].model))
end
