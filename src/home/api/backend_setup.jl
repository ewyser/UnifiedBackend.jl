export add_backend!

"""
    list_host_backend() -> Dict{Symbol, Dict{Symbol, Any}}

Return a dictionary of supported host (CPU) backend configurations for each architecture.

Each architecture entry (e.g., `:x86_64`, `:aarch64`) contains:
- `:host`: Device category ("cpu")
- `:Backend`: KernelAbstractions CPU backend instance
- `:brand`: Array of supported manufacturer strings
- `:wrapper`: Array type for computations
- `:devices`: Placeholder for device list (usually `nothing`)
- `:name`: Placeholder for device name (usually `nothing`)
- `:handle`: Type handle (e.g., `Val{:Host}`)
- `:functional`: Boolean indicating if this architecture matches the current system

# Returns

Dictionary mapping architecture symbols to configuration dictionaries.

# Examples

```julia
backends = list_host_backend()
x86_config = backends[:x86_64]
println(x86_config[:brand])      # ["Intel(R)", "AMD"]
println(x86_config[:functional]) # true (on x86-64 systems)
println(x86_config[:devices])    # nothing
```
"""
function list_host_backend()
	return Dict( 
		:x86_64  => Dict(
            :host => "cpu",
            :Backend => CPU(),
            :brand => ["Intel(R)","AMD"],
            :wrapper => Array,
            :devices => nothing,
            :name => nothing,
            :handle => Val{:Host},
            :functional => Sys.ARCH==:x86_64,
        ),
		:aarch64 => Dict(
            :host => "cpu",
            :Backend => CPU(),
            :brand => ["Apple","AMD"],
            :wrapper => Array,
            :devices => nothing,
            :name => nothing,
            :handle => Val{:Host},
            :functional => Sys.ARCH==:aarch64,
        ),
	)
end

"""
    list_cpu_devices() -> Vector{String}

Get a list of CPU device names from system information.

Queries `Sys.cpu_info()` and extracts the model name prefix (before the colon)
for each available CPU core. This is used to populate device configurations
in the ExecutionPlatforms structure.

# Returns

Vector of CPU model name strings, one per logical core.

# Examples

```julia
devices = list_cpu_devices()
println(length(devices))  # Number of logical CPU cores
println(devices[1])       # "Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz"
```

# See Also

- `Sys.cpu_info()`: Julia's system CPU information function
"""
function list_cpu_devices()
    return [String(split(string(cpu), ":")[1]) for cpu in Sys.cpu_info()]
end

"""
    add_backend!(bckd::ExecutionPlatforms, ::Val{ARCH}) where ARCH -> Nothing

Initialize and populate the execution platform registry with host (CPU) backend configurations.

This generic implementation works for any CPU architecture: it takes the entry of
`list_host_backend()` for `ARCH` (its backend, array type and known brands).

To add support for a new architecture, simply add an entry to `list_host_backend()`.

# Arguments

- `bckd::ExecutionPlatforms`: The execution platforms registry to populate
- `::Val{ARCH}`: Architecture specification (e.g., `Val(:x86_64)`, `Val(:aarch64)`)

# Behavior

1. Queries system CPU information via `Sys.cpu_info()`
2. Matches the CPU model against the architecture's listed brands (`host_brand`)
3. Creates a device entry for each logical CPU core (at least one)
4. Updates the `functional` status log
5. Logs initialization status via `@info`

# Device Configuration

Each registered device receives:
- `:host`: "cpu"
- `:platform`: `:CPU`
- `:brand`: Detected manufacturer (e.g., "Intel(R)", "AMD", "Apple")
- `:name`: Full CPU model string
- `:Backend`: KernelAbstractions `CPU()` backend
- `:wrapper`: `Array` type for computations
- `:handle`: `nothing` (CPUs don't require device handles)

# Unlisted CPUs

A CPU whose model names no listed brand (Julia under Rosetta, which reports an Apple chip for `:x86_64`; NVIDIA
Grace; other ARM servers), or whose model is unknown, is still registered, with brand `"unknown"` (`host_brand`);
an architecture `list_host_backend()` does not list gets the `CPU()` backend and `Array`. There is always a `:dev1`.

# See Also

- [`ExecutionPlatforms`](@ref): The structure being populated
- [`list_host_backend`](@ref): Backend configuration specifications
- [`list_cpu_devices`](@ref): CPU device enumeration
"""
function add_backend!(bckd::ExecutionPlatforms, ::Val{ARCH}) where ARCH
    hosts  = list_host_backend()
    config = get(hosts, ARCH, Dict{Symbol,Any}(:Backend => CPU(), :wrapper => Array, :brand => String[]))
    info   = Sys.cpu_info()
    model  = isempty(info) ? "" : strip(info[1].model)
    brand  = host_brand(model, config[:brand])
    name   = isempty(model) ? string(ARCH) : String(model)
    bckd.host = Dict{Symbol,Host}(Symbol("dev$(k)") => Host(
        category = :cpu,
        platform = :CPU,
        brand    = brand,
        name     = name,
        Backend  = config[:Backend],
        wrapper  = config[:wrapper],
        handle   = nothing,
    ) for k ∈ 1:max(1, length(info)))
    push!(bckd.functional, "✓ $(brand) $(ARCH)")
    @debug join(bckd.functional, "\n")
    return nothing
end

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