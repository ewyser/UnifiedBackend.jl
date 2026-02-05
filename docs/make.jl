
using Documenter, UnifiedBackend

DocMeta.setdocmeta!(UnifiedBackend, :DocTestSetup, :(using UnifiedBackend); recursive=true)

repo = "https://github.com/ewyser/UnifiedBackend.jl.git"

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
        "API Reference" => "api.md",
        "Extensions" => "extensions.md",
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