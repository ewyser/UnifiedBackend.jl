"""
    tree(sucess, prefix="\n\t", level=0, max_level=1) -> Vector{String}

Formats a list of strings into a tree-like structure for display.

# Arguments
- `sucess`: List of strings to format.
- `prefix="\n\t"`: String prefix for each line.
- `level=0`: Current tree depth.
- `max_level=1`: Maximum tree depth.

# Returns
- `Vector{String}`: Tree-formatted strings.

# Example
```julia
tree(["boot", "home"])
```
"""
function tree(sucess, prefix="\n\t", level=0, max_level=1)
    if level > max_level
        return nothing
    end
    n,printout = length(sucess),[]
    for (i, name) ∈ enumerate(sucess)
        connector = i == n ? "└── " : "├── "
        push!(printout,prefix*connector*name)
    end
    return printout
end

"""
    rootflush(info) -> Vector{String}

Creates or flushes the output directory, removing files that do not match a given pattern.

# Arguments
- `info`: Struct containing system and MPI information.

# Returns
- `Vector{String}`: Messages about created or deleted files.

# Example
```julia
msgs = rootflush(info)
println.(msgs)
```
"""
function rootflush(dir_to_flush::String; except::Vector{String}=String[])
    if !isdir(dir_to_flush)
        msg = ["Creating:\n+ $(trunc_path(dir_to_flush))"]
        mkdir(dir_to_flush) 
    else
        files = readdir(dir_to_flush;join=true)
        if !isempty(files)
            msg = ["Flushing $(trunc_path(dir_to_flush; anchor=basename(dir_to_flush)))/: "]
            for file ∈ files
                if basename(file) ∉ except
                    rm(file,recursive=true)  
                    push!(msg,"\e[31m- $(trunc_path(file))\e[0m")
                end
            end
            @info join(msg,"\n")
        end
    end
    return nothing
end

"""
    trunc_path(full_path::AbstractString; anchor::AbstractString="ElastoPlasm.jl") -> String

Returns the subpath of `full_path` starting from the directory name `anchor`.

# Arguments
- `full_path`: The full absolute or relative path.
- `anchor`: The folder name from which you want to keep the rest of the path.

# Returns
- `String`: Truncated path string.

# Example
```julia
trunc_path("C:/Users/lili8/Documents/GitHub/ElastoPlasm.jl/dump/slump", "ElastoPlasm.jl")
# => "ElastoPlasm.jl/dump/slump"
```
"""
function trunc_path(full_path::AbstractString; anchor::AbstractString="ElastoPlasm.jl")
    parts = splitpath(full_path)
    idx = findfirst(==(anchor), parts)
    return isnothing(idx) ? full_path : joinpath(parts[idx:end]...)
end

"""
    get_version() -> String

Return the current project version as a string, as specified in the Julia project file.

# Returns
- `String`: The project version.

# Example
```julia
v = get_version()
println(v)
```
"""
function get_version()
    return string(Pkg.project().version)
end

"""
    welcome_log(; greeting::String="Welcome to ϵlastσPlasm 👻 v$(get_version())")

Prints a styled welcome message to the console, highlighting "Welcome" and vertical bars in green and bold.

# Arguments
- `greeting::String`: The greeting message to display at the top (default: "Welcome to ϵlastσPlasm 👻 v$(get_version())").

# Returns
- `Nothing`. Prints the welcome message to the console.

# Example
```julia
welcome_log()
welcome_log(greeting="Hello from ElastoPlasm!")
```
"""
function welcome_log(; greeting::String="Welcome to UnifiedBackend v$(get_version())", showcase::String = "on-boarding") 
    printstyled("┌ $greeting\n", color=:green, bold=true)
    printstyled("│", color=:green, bold=true); println(" New comer ? Try $(showcase) out")
    if showcase == "on-boarding"
        printstyled("│", color=:green, bold=true); println("   L,nel  = [64.1584,64.1584/4.0],[40,10];")
        printstyled("│", color=:green, bold=true); println("   jld2   = ic_slump(L,nel;cli()...);")
        printstyled("└", color=:green, bold=true); println("   out    = elastoplasm(jld2; workflow = [elastodynamic!,elastoplastic!]);")
    else
        printstyled("└", color=:green, bold=true); println("   ...$(showcase) ?!? \e[5m¯\\_(ツ)_/¯\e[0m")
    end

    return nothing
end