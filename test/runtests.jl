using UnifiedBackend
using Test
using KernelAbstractions

@testset "UnifiedBackend.jl" begin
    
    @testset "Type Construction" begin
        @testset "ExecutionPlatforms" begin
            # Test default constructor
            exec = ExecutionPlatforms()
            @test exec isa ExecutionPlatforms
            @test exec.functional == ["Available execution platform(s):"]
            @test isempty(exec.host)
            @test isempty(exec.device)
            
            # Test keyword constructor
            exec2 = ExecutionPlatforms(
                functional = ["test"],
                host = Dict(:dev1 => Dict(:name => "TestCPU")),
                device = Dict()
            )
            @test exec2.functional == ["test"]
            @test length(exec2.host) == 1
            @test exec2.host[:dev1][:name] == "TestCPU"
        end
        
        @testset "Backend" begin
            # Test default constructor
            exec = ExecutionPlatforms()
            bckd = Backend(lib=Dict(), exec=exec)
            @test bckd isa Backend
            @test isempty(bckd.lib)
            @test bckd.exec === exec
            
            # Test immutability of struct
            @test !ismutable(Backend)
            @test ismutable(ExecutionPlatforms)
        end
    end
    
    @testset "Global Backend Access" begin
        @testset "backend() function" begin
            b = backend()
            @test b isa Backend
            @test b.exec isa ExecutionPlatforms
            
            # Test singleton behavior - same instance every time
            b2 = backend()
            @test b === b2
        end
        
        @testset "Initial state" begin
            b = backend()
            
            # Should have initialized execution platforms
            @test !isempty(b.exec.functional)
            @test "Available execution platform(s):" ∈ b.exec.functional
            
            # Should have CPU backend registered
            @test !isempty(b.exec.host)
            
            # GPU may or may not be available
            # Don't test device dict as it depends on system
        end
    end
    
    @testset "Backend Setup" begin
        @testset "list_host_backend()" begin
            backends = UnifiedBackend.list_host_backend()
            
            @test backends isa Dict{Symbol, Dict{Symbol, Any}}
            @test haskey(backends, :x86_64)
            @test haskey(backends, :aarch64)
            
            # Check x86_64 configuration
            x86 = backends[:x86_64]
            @test x86[:host] == "cpu"
            @test x86[:Backend] isa CPU
            @test x86[:wrapper] === Array
            @test "Intel(R)" ∈ x86[:brand] || "AMD" ∈ x86[:brand]
            
            # Check aarch64 configuration
            arm = backends[:aarch64]
            @test arm[:host] == "cpu"
            @test arm[:Backend] isa CPU
            @test "Apple" ∈ arm[:brand] || "AMD" ∈ arm[:brand]
            
            # One should be functional based on current architecture
            @test backends[:x86_64][:functional] || backends[:aarch64][:functional]
        end
        
        @testset "list_cpu_devices()" begin
            devices = UnifiedBackend.list_cpu_devices()
            
            @test devices isa Vector{String}
            @test !isempty(devices)
            
            # Should have at least one CPU
            @test length(devices) >= 1
            
            # Each entry should be a non-empty string
            for dev in devices
                @test dev isa String
                @test !isempty(dev)
            end
        end
        
        @testset "add_backend!()" begin
            # Create a fresh ExecutionPlatforms
            exec = ExecutionPlatforms()
            
            # Add backend based on current architecture
            if Sys.ARCH == :x86_64
                add_backend!(exec, Val(:x86_64))
            elseif Sys.ARCH == :aarch64
                add_backend!(exec, Val(:aarch64))
            end
            
            # Should have populated host devices
            @test !isempty(exec.host)
            
            # Should have functional message
            @test length(exec.functional) > 1
            
            # Check device structure
            for (dev_id, config) in exec.host
                @test dev_id isa Symbol
                @test config isa Dict{Symbol, Any}
                @test config[:host] == "cpu"
                @test config[:platform] == :CPU
                @test haskey(config, :brand)
                @test haskey(config, :name)
                @test config[:Backend] isa CPU
                @test config[:wrapper] === Array
                @test config[:handle] === nothing
            end
        end
    end
    
    @testset "Device Selection" begin
        b = backend()
        
        @testset "get_host()" begin
            # Default mode - should return first device
            cpu = get_host(b.exec)
            @test cpu isa NamedTuple
            @test haskey(cpu, :dev1)
            @test cpu.dev1 isa Dict{Symbol, Any}
            @test cpu.dev1[:platform] == :CPU
            
            # Test that device configuration is complete
            @test haskey(cpu.dev1, :name)
            @test haskey(cpu.dev1, :Backend)
            @test haskey(cpu.dev1, :wrapper)
            @test cpu.dev1[:Backend] isa CPU
            @test cpu.dev1[:wrapper] === Array
        end
        
        @testset "get_device() - no GPU" begin
            # Only test if no GPU is available
            if isempty(b.exec.device)
                @test_throws Exception get_device(b.exec)
            end
        end
        
        @testset "select_execution_backend()" begin
            # Host selection (default mode)
            @testset "Host selection" begin
                cpu = select_execution_backend(b.exec, "host")
                @test cpu isa NamedTuple
                @test haskey(cpu, :dev1)
                @test cpu.dev1[:platform] == :CPU
            end
            
            # Device selection with fallback
            @testset "Device selection with fallback" begin
                result = select_execution_backend(b.exec, "device")
                @test result isa NamedTuple
                
                # Should either be GPU or fallback to CPU
                if !isempty(b.exec.device)
                    # Has GPU
                    @test length(result) >= 1
                else
                    # Fell back to CPU
                    @test haskey(result, :dev1)
                    @test result.dev1[:platform] == :CPU
                end
            end
            
            # Invalid selection string
            @testset "Error handling" begin
                @test_throws ArgumentError select_execution_backend(b.exec, "invalid")
                @test_throws ArgumentError select_execution_backend(b.exec, "")
                @test_throws ArgumentError select_execution_backend(b.exec, "gpu")
            end
        end
    end
    
    @testset "Device Management" begin
        @testset "device_wakeup!() stub" begin
            # Should throw error when called without backend extension
            @test_throws ErrorException device_wakeup!()
        end
        
        @testset "device_free!() CPU" begin
            # Should not throw error
            @test device_free!(nothing, Val(:CPU)) === nothing
            
            # Test with actual data
            data = rand(100)
            @test device_free!(data, Val(:CPU)) === nothing
        end
    end
    
    @testset "Integration Tests" begin
        @testset "End-to-end workflow" begin
            # Get backend
            b = backend()
            @test b isa Backend
            
            # Select CPU
            cpu = select_execution_backend(b.exec, "host")
            @test cpu isa NamedTuple
            
            # Get backend instance
            backend_instance = cpu.dev1[:Backend]
            @test backend_instance isa CPU
            
            # Get array type
            array_type = cpu.dev1[:wrapper]
            @test array_type === Array
            
            # Create array
            data = array_type(rand(10, 10))
            @test data isa Array
            @test size(data) == (10, 10)
            
            # Clean up
            device_free!(data, Val(:CPU))
        end
        
        @testset "Multiple backend accesses" begin
            # Should maintain consistency
            b1 = backend()
            cpu1 = select_execution_backend(b1.exec, "host")
            
            b2 = backend()
            cpu2 = select_execution_backend(b2.exec, "host")
            
            @test b1 === b2
            @test cpu1.dev1[:name] == cpu2.dev1[:name]
        end
    end
    
    @testset "Type Stability" begin
        b = backend()
        
        @testset "Return type stability" begin
            @test @inferred backend() isa Backend
            @test @inferred get_host(b.exec) isa NamedTuple
        end
    end
    
end
