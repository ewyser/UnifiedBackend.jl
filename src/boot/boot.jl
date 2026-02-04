# include dependencies
using Revise,Pkg,Test
using ProgressMeter,REPL.TerminalMenus

using KernelAbstractions,Adapt,Base.Threads
import KernelAbstractions.@atomic as @atom
import KernelAbstractions.Kernel as Cairn
import KernelAbstractions.synchronize as sync

# include types &
include(joinpath(SRC,"boot/include.jl"))
sucess = superInc(["boot/needs"]; root=SRC)

# create primitive structs
info = Self(
    sys = Path(
        root = SRC,
	    out  = joinpath(dirname(SRC),"dump"),
	    test = joinpath(dirname(SRC),"test"),
    ), 
    ui = UI(), 
    bckd = Execution(), 
    mpi = Distributed()
)  

# include
include(joinpath(SRC,"boot/needs/utils.jl"))
include(joinpath(SRC,"boot/needs/backend.jl"))
include(joinpath(SRC,"boot/needs/distributed.jl"))


# find & printout active backend(s)
add_backend!(info.bckd, Val(:x86_64))

## include .jl files
#lists = ["home/init","home/api","home/core","home/script"]
#@info join(superInc(lists; root=SRC, lib=info.sys.lib),"\n")