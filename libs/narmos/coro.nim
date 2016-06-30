{.compile: "picoro/picoro.c".}

# TODO: Fix this when PR gets merged
{.passC: "-Ipicoro/".}
{.passC: "-std=gnu99".}

## #
## #  picoro - minimal coroutines for C.
## #  Written by Tony Finch <dot@dotat.at>
## #  http://creativecommons.org/publicdomain/zero/1.0/
## #  API modelled after Lua's coroutines
## #  http://www.lua.org/manual/5.1/manual.html#2.11
## #
## #  Nim port (c) Jeff Ciesielski <jeffciesielski@gmail.com>

type
  CoroHandle* = pointer
  Coroutine* = (proc(arg: pointer): pointer {.cdecl.})

## #
## #  Create a coroutine that will run fun(). The coroutine starts off suspended.
## #  When it is first resumed, the argument to resume() is passed to fun().
## #  If fun() returns, its return value is returned by resume() as if the
## #  coroutine yielded, except that the coroutine is then no longer resumable
## #  and may be discarded.
## # 

proc coSpawn*(c: Coroutine, stack_size: uint = 128): CoroHandle {.cdecl,
                                                                  importc: "coroutine",
                                                                  header: "picoro.h".}
  ## #
  ## #  Returns false when the coroutine has run to completion
  ## #  or when it is blocked inside resume().
  ## # 

proc resumable*(c: CoroHandle): bool {.cdecl,
                                       importc: "resumable",
                                       header: "picoro.h".}
## #
## #  Transfer control to another coroutine. The second argument is returned by
## #  yield() inside the target coroutine (except for the first time resume() is
## #  called). A coroutine that is blocked inside resume() is not resumable.
## # 

proc resume*(c: CoroHandle, arg: pointer = nil): pointer {.cdecl,
                                                           importc: "resume",
                                                           header: "picoro.h".}
## #
## #  Transfer control back to the coroutine that resumed this one. The argument
## #  is returned by resume() in the destination coroutine. A coroutine that is
## #  blocked inside yield() may be resumed by any other coroutine.
## # 

proc coYield*(arg: pointer = nil): pointer {.cdecl, importc: "yield", header: "picoro.h".}
