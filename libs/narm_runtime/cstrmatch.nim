
proc c_strncmp(s1, s2: cstring, n: int): cint {.cdecl, importc: "strncmp", header: "string.h".}

template `~=`* (a: cstring, b: string): bool =
  # The +1 handles the terminating zero to ensure 'foo' doesn't match 'foobarbaz'
  (c_strncmp(a, b.cstring, b.len+1) == 0)

template `~=`* (a: cstring, b: cstring): bool =
  # The +1 handles the terminating zero to ensure 'foo' doesn't match 'foobarbaz'
  (c_strncmp(a, b, b.len+1) == 0)
