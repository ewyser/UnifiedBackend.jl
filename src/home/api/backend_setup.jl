export add_backend!

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

function list_cpu_devices()
    return [String(split(string(cpu), ":")[1]) for cpu in Sys.cpu_info()]
end

"""
    add_backend!(bckd::ExecutionPlatforms, ::Val{:x86_64})

Description:
---
Populate ExecutionPlatforms struct with effective host and device backend based on hard-coded supported backends. 
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
