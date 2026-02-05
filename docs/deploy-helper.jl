# deploy-helper.jl
# Helper script to generate Documenter.jl deploy keys for GitHub Pages

using DocumenterTools

# Change these if you fork the repo
user = "ewyser"
repo = "UnifiedBackend.jl"

println("Generating deploy keys for GitHub Pages...")
DocumenterTools.genkeys(user=user, repo=repo)

println("\nInstructions:")
println("1. Copy the public key (ssh-rsa ...) and add it as a Deploy key in your GitHub repo (Settings → Deploy keys) with write access.")
println("2. Copy the private key (LS0tLS1...) and add it as a Secret named DOCUMENTER_KEY in Settings → Secrets and variables → Actions.")
println("3. Done! You can now deploy documentation automatically.")
