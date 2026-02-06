```@meta
CurrentModule = UnifiedBackend
```

# UnifiedBackend.jl

A unified backend abstraction layer for CPU and GPU execution in Julia.

## Overview

UnifiedBackend provides a consistent interface for managing and executing code across different computational backends (CPU, CUDA, ROCm) with automatic device detection and runtime configuration.

## Features

- **Automatic CPU detection**: Supports x86_64 and aarch64 (Apple Silicon)
- **GPU support**: NVIDIA CUDA and AMD ROCm via package extensions  
- **Interactive selection**: Choose devices via terminal menus
- **Multi-device**: Run on multiple CPUs or GPUs
- **Type-stable**: Uses KernelAbstractions.jl

## Quick Start

```julia
using UnifiedBackend

# Access backend
b = backend()

# Use CPU
cpu = select_execution_backend(b.exec, "host")
data = cpu.dev1[:wrapper](rand(1000, 1000))

# Use GPU (with CUDA.jl loaded)
gpu = select_execution_backend(b.exec, "device")
data = gpu.dev1[:wrapper](rand(1000, 1000))
```

See the [API Reference](api.md) and [Extensions](extensions.md) for more details.
