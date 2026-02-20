# Package Extensions

```@meta
CurrentModule = UnifiedBackend
```

UnifiedBackend uses Julia's package extension system to provide optional GPU support. Extensions are automatically loaded when you install and load the corresponding GPU package.

## Available Extensions

### CUDAExt - NVIDIA GPU Support

Provides CUDA support for NVIDIA GPUs via CUDA.jl.

#### Installation

```julia
using Pkg
Pkg.add("CUDA")
```

#### Usage

```julia
using UnifiedBackend
using CUDA  # Automatically loads CUDAExt

b = get_backend()

# Check for CUDA devices
if !isempty(b.exec.device)
    println("Found ", length(b.exec.device), " CUDA GPU(s)")
    
    # Select GPU
    gpu = select_execution_backend(b.exec, "device")
    
    # Access CUDA-specific properties
    println("GPU: ", gpu.dev1[:name])
    println("Backend: ", gpu.dev1[:Backend])  # CUDABackend()
    println("Array type: ", gpu.dev1[:wrapper])  # CuArray
    
    # Create data on GPU
    data = gpu.dev1[:wrapper](rand(1000, 1000))
end
```

#### Extended Functions

- `add_backend!(::Val{:CUDA}, ::Backend)` - Detects and registers CUDA GPUs
- `device_wakeup!(::CuDevice)` - Activates a specific CUDA device
- `device_free!(::Mesh, ::Val{:CUDA})` - Frees CUDA memory

### ROCmExt - AMD GPU Support

Provides ROCm support for AMD GPUs via AMDGPU.jl.

#### Installation

```julia
using Pkg
Pkg.add("AMDGPU")
```

#### Usage

```julia
using UnifiedBackend
using AMDGPU  # Automatically loads ROCmExt

b = get_backend()

# Check for ROCm devices
if !isempty(b.exec.device)
    println("Found ", length(b.exec.device), " ROCm GPU(s)")
    
    # Select GPU
    gpu = select_execution_backend(b.exec, "device")
    
    # Access ROCm-specific properties
    println("GPU: ", gpu.dev1[:name])
    println("Backend: ", gpu.dev1[:Backend])  # ROCBackend()
    println("Array type: ", gpu.dev1[:wrapper])  # ROCArray
    
    # Create data on GPU
    data = gpu.dev1[:wrapper](rand(1000, 1000))
end
```

#### Extended Functions

- `add_backend!(::Val{:ROCm}, ::Backend)` - Detects and registers ROCm GPUs
- `device_wakeup!(::HIPDevice)` - Activates a specific ROCm device
- `device_free!(::Mesh, ::Val{:ROCm})` - Frees ROCm memory

## GPU Fallback Behavior

When requesting GPU execution without GPU extensions loaded, UnifiedBackend automatically falls back to CPU:

```julia
# No GPU package loaded
gpu = select_execution_backend(get_backend().exec, "device")
# Info: No GPU available, falling back to CPU backend
# Returns CPU device instead
```

## Requirements

### CUDA Requirements
- Julia 1.9+
- NVIDIA GPU with CUDA support
- CUDA toolkit installed
- CUDA.jl package

### ROCm Requirements
- Julia 1.9+
- AMD GPU with ROCm support
- ROCm runtime installed
- AMDGPU.jl package

## Troubleshooting

If extensions fail to load, check:

1. **Package installation**:
```julia
using Pkg
Pkg.status()  # Verify CUDA/AMDGPU is installed
```

2. **GPU drivers**:
```julia
using CUDA  # or AMDGPU
CUDA.versioninfo()  # Check CUDA installation
AMDGPU.versioninfo()  # Check ROCm installation
```

3. **Extension loading**:
```julia
using UnifiedBackend
get_backend()  # Check exec.functional for loaded backends
```

Warnings during extension loading are captured and displayed with troubleshooting hints.
