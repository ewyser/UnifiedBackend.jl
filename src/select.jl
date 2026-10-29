"""
    select_platform(which="host") -> Platform

The platform to run on: `"host"`, the host (the CPU); `"device"`, the first registered device (a GPU), or the host
when there is none, which it says.
"""
function select_platform(which::AbstractString="host")
    which ∈ ("host", "device") || throw(ArgumentError("select \"host\" or \"device\", not \"$which\""))
    if which == "device"
        isempty(DEVICES) || return first(DEVICES)
        @info "No GPU registered (load CUDA.jl or AMDGPU.jl on a machine that has one): running on the host"
    end
    return first(HOSTS)
end

"""
    activate!(platform) -> platform

Make `platform` the current device of its GPU package (`CUDA.device!`, `AMDGPU.device!`, from the extensions'
`activate!(handle)` methods); a host has nothing to activate.
"""
function activate!(p::Platform)
    activate!(p.handle)
    return p
end
function activate!(::Nothing)
    return nothing
end
