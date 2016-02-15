
# Misc utilities to enable simple integration of some low level stdlib
# stuff that doesn't map nicely to nim at the moment.

# NOTE: This is (unfortunately) going to be a dumping ground for the
# time being, but my hope is to break things into manageable pieces in
# the future


# These are currently not supported by the 'standalone' implementation
# of Nim.  That said, we need them anyway, so pilfer them until we can
# get this taken care of
type
  CFile {.importc: "FILE", header: "<stdio.h>",
         final, incompletestruct.} = object
  File* = ptr CFile ## The type representing a file handle.

var
  stdin* {.importc: "stdin", header: "<stdio.h>".}: File
  ## The standard input stream.
  stdout* {.importc: "stdout", header: "<stdio.h>".}: File
  ## The standard output stream.
  stderr* {.importc: "stderr", header: "<stdio.h>".}: File
  ## The standard error stream.

const
  IONBF* = 2

proc printf*(formatstr: cstring) {.importc: "printf", varargs,
                                  header: "<stdio.h>".}

# Enabling unbuffered IO will shoot every generated character directly
# to the _write method (typically defined in newlib.c).  Typically
# data written to stdin/stdout is line or block buffered, but this
# requires memory allocations that might not be suitable for deeply
# embedded hosts.  For more info, see the man page for setvbuf
proc setvbuf(stream: File, buf: cstring, buftype: int, size: int32): int {.importc: "setvbuf", header:"<stdio.h>".}
proc enable_unbuffered_io*(): void =
  for stream in [stdin, stdout, stderr]:
      discard setvbuf(stream, nil, IONBF, 0)

