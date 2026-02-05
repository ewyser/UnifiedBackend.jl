export get_host, get_device, select_execution_backend

"""
    get_host(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)

Description:
---
Return a NamedTuple of effective host (CPU) device(s).
"""
function get_host(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)
    cpus,devs,names = Dict(),collect(keys(bckd.host)),Vector{String}()
    for key ∈ devs
        push!(names,bckd.host[key][:name])
    end
    if distributed
        for dev ∈ request("select device(s):",MultiSelectMenu(names))
            cpus[devs[dev]] = bckd.host[devs[dev]]
        end 
        return NamedTuple(cpus)
    elseif prompt
        dev = request("select device:",RadioMenu(names))
        return NamedTuple(Dict(devs[dev] => bckd.host[devs[dev]]))
    else
        return NamedTuple(Dict(:dev1 => bckd.host[:dev1]))
    end
end

"""
    get_device(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)

Description:
---
Return a NamedTuple of device (GPU)(s). When `prompt=true`, show interactive menu for device selection.
"""
function get_device(bckd::ExecutionPlatforms; prompt::Bool=false, distributed::Bool=false)
    devs,names = collect(keys(bckd.device)),Vector{String}()
    for key ∈ devs
        push!(names,bckd.device[key][:name])
    end
    gpus = Dict()
    if distributed
        for dev ∈ request("select device(s):",MultiSelectMenu(names))
            gpus[devs[dev]] = bckd.device[devs[dev]]
        end 
        return NamedTuple(gpus)
    elseif prompt
        dev = request("select device:",RadioMenu(names))
        return NamedTuple(Dict(devs[dev] => bckd.device[devs[dev]]))
    else
        return NamedTuple(Dict(devs[1]=>bckd.device[devs[1]]))
    end
end

"""
    select_execution_backend(bckd::ExecutionPlatforms, select::String="host"; prompt::Bool=false, distributed::Bool=false)

Description:
---
Select execution backend and return a NamedTuple of device(s).

Arguments:
- `select::String`: "host" for CPU, "device" for GPU
- `prompt::Bool`: Show interactive menu to choose specific device/core
- `distributed::Bool`: Enable distributed multi-device selection

Example:
---
```julia
julia> select_execution_backend(info.bckd, "host")  # Direct CPU selection
julia> select_execution_backend(info.bckd, "host", prompt=true)  # Choose which CPU core
julia> select_execution_backend(info.bckd, "host", distributed=true)  # Choose multiple CPU cores
```
"""
function select_execution_backend(bckd::ExecutionPlatforms, select::String="host"; prompt::Bool=false, distributed::Bool=false)
    mode = distributed ? "distributed" : (prompt ? "interactive" : "default")
    if select == "host"
        @info "Using CPU backend ($mode mode)"
        return get_host(bckd; prompt=prompt, distributed=distributed)
    elseif select == "device"
        if isempty(bckd.device)
            @info "No GPU available, falling back to CPU backend"
            return get_host(bckd; prompt=prompt, distributed=distributed)
        else
            @info "Using GPU backend ($mode mode)"
            return get_device(bckd; prompt=prompt, distributed=distributed)
        end
    else
        throw(ArgumentError("Invalid backend selection: '$(select)'. Use 'host' or 'device'"))
    end
end
