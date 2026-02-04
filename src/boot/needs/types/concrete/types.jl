export Backend

Base.@kwdef mutable struct Execution
    functional::Vector{String} = ["Available execution platform(s):"]
    prompt::Bool = false
	cpu::Dict = Dict()
	gpu::Dict = Dict()
end
Base.@kwdef mutable struct Backend
    lib ::Dict   = Dict()
	exec::Execution
end