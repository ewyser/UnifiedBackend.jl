export device_wakeup!, device_free!

"""
    device_wakeup!()

Description:
---
Return Dicts of effective cpu and gpu backend based on hard-coded supported backends. 

"""
function device_wakeup!()
    throw(ErrorException("🚧 `device_wakeup!()` is a stub. It must be overloaded in CUDAExt, ROCmExt or MtlExt."))
end

"""
    device_free(mesh,::Val{:CPU})

Description:
---
Free device memory and trigger garbage collection. 
"""
function device_free!(mesh,::Val{:CPU})
    GC.gc()
    return nothing
end
