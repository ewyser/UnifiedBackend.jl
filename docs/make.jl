
using Documenter, UnifiedBackend

DocMeta.setdocmeta!(UnifiedBackend, :DocTestSetup, :(using UnifiedBackend); recursive=true)

repo = "https://github.com/ewyser/UnifiedBackend.jl.git"

# Helper function to generate an @autodocs block string
function write_autodoc_page(filename, pages, modulename)
    check = joinpath(@__DIR__, "src","function")
    if !isdir(check)
        mkpath(check)    
    end
    path = joinpath(check, filename)
    
    open(path, "w") do io
        println(io, "# $modulename Reference\n")
        println(io, "```@meta")
        println(io, "CollapsedDocStrings = true")
        println(io, "```")
        println(io)
        println(io, "```@autodocs")
        println(io, "Modules = [$modulename]")
        println(io, "Pages   = ", repr(pages))
        println(io, "```")
    end
end
write_autodoc_page("api.md"    , UnifiedBackend.info.sys.lib["home/api"]    , :UnifiedBackend)
write_autodoc_page("program.md", UnifiedBackend.info.sys.lib["home/program"], :UnifiedBackend)
write_autodoc_page("script.md" , UnifiedBackend.info.sys.lib["home/script"] , :UnifiedBackend)

# Call makedocs
@info "Making documentation..."
makedocs(;
    modules = [UnifiedBackend],
    authors = "madmax",
    sitename = "UnifiedBackend.jl",
    format = Documenter.HTML(;
        repolink = repo,
        canonical = "https://ewyser.github.io/UnifiedBackend.jl/",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Function Reference" => [
            "Public API" => "function/api.md",
            "Internals"  => "function/program.md",
            "Example"    => "function/script.md",
        ]
    ],
    checkdocs = :none,
)

# Deploy documentation only if inside GitHub Actions
if get(ENV, "GITHUB_ACTIONS", "false") == "true"
    @info "Deploying documentation..."
    deploydocs(; 
        repo = repo,
        devbranch = "main",
        branch = "gh-pages",
        versions = ["stable" => "v^", "dev" => "dev"],
        forcepush = true,
        push_preview = true,
    )
else
    @info "Not running inside CI, skipping deploydocs."
end