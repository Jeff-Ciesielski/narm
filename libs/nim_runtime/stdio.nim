
# Misc utilities to enable simple integration of some low level stdlib
# stuff that doesn't map nicely to nim at the moment.

# NOTE: This is (unfortunately) going to be a dumping ground for the
# time being, but my hope is to break things into manageable pieces in
# the future


proc enable_unbuffered_io*(): void {.importc.}
proc printf*(formatstr: cstring) {.importc: "printf", varargs,
                                  header: "<stdio.h>".}

