# include dependencies
using Revise,Pkg,Test
using ProgressMeter,REPL.TerminalMenus

using KernelAbstractions,Adapt,Base.Threads
import KernelAbstractions.@atomic as @atom
import KernelAbstractions.Kernel as Cairn
import KernelAbstractions.synchronize as sync

# include types
include(joinpath(SRC,"boot/include.jl"))
sucess = superInc(["boot/needs/types"]; root=SRC)

# create primitive structs
info = Backend(
    lib  = Dict(),
    exec = Execution(), 
)  

# include .jl files
lists = ["home/api"]
@info join(superInc(lists; root=SRC, lib=info.lib),"\n")