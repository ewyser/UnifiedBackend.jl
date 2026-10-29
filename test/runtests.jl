using UnifiedBackend
using Test
using KernelAbstractions

@kernel function twice!(a)
    i = @index(Global)
    a[i] = 2 * a[i]
end

@testset "UnifiedBackend.jl" begin
    @testset "Platform" begin
        p = Platform(:device, :Fake, "Brand", "a GPU", CPU(), Array, 7)
        @test (p.kind, p.platform, p.brand, p.name, p.backend, p.arraytype, p.handle) == (:device, :Fake, "Brand", "a GPU", CPU(), Array, 7)
        @test Platform(; platform=:Fake, backend=CPU(), arraytype=Array).name == "Fake"          # keywords, defaults
        @test !ismutable(p)
        @test_throws ArgumentError Platform(:gpu, :Fake, "", "", CPU(), Array, nothing)          # :host or :device
    end

    @testset "the host is registered when the package loads" begin
        @test length(host_platforms()) == 1
        h = only(host_platforms())
        @test h.kind == :host && h.platform == :CPU && h.backend isa CPU && h.arraytype === Array && h.handle === nothing
        @test !isempty(h.name) && !isempty(h.brand)
    end

    @testset "any CPU is a host" begin
        hb = UnifiedBackend.host_brand
        @test hb("Intel(R) Core(TM) i5-1038NG7 CPU @ 2.00GHz", ["Intel(R)", "AMD"]) == "Intel(R)"
        @test hb("AMD Ryzen 7 9800X3D", ["Intel(R)", "AMD"]) == "AMD"
        @test hb("Apple M2", ["Intel(R)", "AMD"]) == "unknown"          # x86_64 Julia under Rosetta
        @test hb("Neoverse-V2", ["Apple", "AMD"]) == "unknown"          # NVIDIA Grace
        @test hb("", ["Intel(R)", "AMD"]) == "unknown"
        h = UnifiedBackend.host_platform(:riscv64, "")                 # an architecture with no brands, no model
        @test h.name == "riscv64" && h.brand == "unknown" && h.backend isa CPU && h.arraytype === Array
    end

    @testset "selecting" begin
        @test select_platform() === first(host_platforms()) === select_platform("host")
        @test isempty(device_platforms())
        @test (@test_logs (:info, r"No GPU registered") select_platform("device")) === first(host_platforms())   # falls back, says so
        @test_throws ArgumentError select_platform("gpu")
        try
            UnifiedBackend.register_gpus!(:Fake, "Brand", CPU(), Array, [7, 8], h -> "gpu $h")       # what an extension does
            register!(Platform(; platform=:Other, backend=CPU(), arraytype=Array, handle=9))
            @test [d.handle for d ∈ device_platforms()] == [7, 8, 9]                                         # registration order
            @test device_platforms()[2].name == "gpu 8" && device_platforms()[2].kind == :device
            @test select_platform("device") === first(device_platforms())
        finally
            empty!(device_platforms())
        end
    end

    @testset "activating, and running a kernel there" begin
        h = select_platform()
        @test activate!(h) === h                                                                   # nothing to do for a host
        a = h.arraytype([1.0, 2.0, 3.0])
        twice!(h.backend)(a; ndrange=length(a)); KernelAbstractions.synchronize(h.backend)
        @test a == [2.0, 4.0, 6.0]
    end
end
