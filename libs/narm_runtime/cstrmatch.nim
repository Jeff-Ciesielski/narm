
proc c_strncmp(s1, s2: cstring, n: int32): cint {.cdecl, importc: "strncmp", header: "string.h".}

template `~=`* (a: cstring, b: string): bool =
  (c_strncmp(a, b.cstring, b.len) == 0)
  
