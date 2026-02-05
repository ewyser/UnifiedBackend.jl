export add_backend!

"""
    list_host_backend() -> Dict{Symbol, Dict{Symbol, Any}}

Return a dictionary of supported host (CPU) backend configurations.

This function provides the hardcoded specifications for supported CPU architectures,
including their KernelAbstractions backend, supported brands, and functional status
based on the current system architecture.

# Returns

Dictionary mapping architecture symbols to configuration dictionaries:
- `:x86_64`: Intel and AMD x86-64 processors
- `:aarch64`: ARM64 processors (Apple Silicon, ARM servers)

Each configuration contains:
- `:host`: Device category ("cpu")
- `:Backend`: KernelAbstractions CPU backend instance
- `:brand`: Array of supported manufacturer strings
- `:wrapper`: Array type for computations
- `:functional`: Boolean indicating if this architecture matches current system

# Examples

```julia
backends = list_host_backend()
x86_config = backends[:x86_64]
println(x86_config[:brand])  # ["Intel(R)", "AMD"]
println(x86_config[:functional])  # true (on x86-64 systems)
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
    add_backend!(bckd::ExecutionPlatforms, ::Val{:x86_64}) -> Nothing
    add_backend!(bckd::ExecutionPlatforms, ::Val{:aarch64}) -> Nothing

Initialize and populate the execution platform registry with host (CPU) backend configurations.

This function detects the current CPU architecture, identifies the processor brand,
and registers all available CPU cores as execution devices in the provided
`ExecutionPlatforms` structure. It is typically called automatically during
module initialization.

# Arguments

- `bckd::ExecutionPlatforms`: The execution platforms registry to populate
- `::Val{:x86_64}` or `::Val{:aarch64}`: Architecture specification (dispatched by system)

# Behavior

1. Queries system CPU information via `Sys.cpu_info()`
2. Matches detected CPU brand against supported backends
3. Creates a device entry for each logical CPU core
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

# Examples

```julia
using UnifiedBackend

# Get the global backend
b = backend()

# Manually re-initialize (normally automatic)
add_backend!(b.exec, Val(:x86_64))

# Inspect registered devices
for (dev_id, config) in b.exec.host
    println("\$dev_id: \$(config[:name])")
end
# Output:
# dev1: Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz
# dev2: Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz
# ... (one per logical core)
```

# Errors

Throws `ErrorException` if CPU model information cannot be retrieved from the system.

# See Also

- [`ExecutionPlatforms`](@ref): The structure being populated
- [`list_host_backend`](@ref): Backend configuration specifications
- [`list_cpu_devices`](@ref): CPU device enumeration
"""
function add_backend!(bckd::ExecutionPlatforms,::Val{:x86_64})
	for (k,(platform,backend)) ∈ enumerate(list_host_backend())
		if backend[:functional]
            cpu_info = Sys.cpu_info()
            if !isempty(cpu_info) && !isempty(cpu_info[1].model)
				for brand ∈ backend[:brand]
					if occursin(brand,cpu_info[1].model)
                        bckd.host = Dict{Symbol,Any}()
                        for (k,device) ∈ enumerate(list_cpu_devices())
                            bckd.host[Symbol("dev$(k)")] = Dict(
                                :host     => "cpu",   
                                :platform => :CPU,        
                                :brand    => brand,            
                                :name     => cpu_info[1].model,
                                :Backend  => backend[:Backend],
                                :wrapper  => backend[:wrapper],
                                :handle   => nothing,
                            )      
                        end
						push!(bckd.functional,"✓ $(brand) $(platform)")
                        break
					end
				end
            else
                throw(ErrorException("Could not retrieve CPU model"))
            end
		end
	end
    @info join(bckd.functional,"\n")
	return nothing
end
