import stdio

type shell_callback = (proc(argc: cint, argv: cstringArray):void {.cdecl.})

type
  shell_cmd* {.importc: "struct shell_cmd", header: "shell.h".} = object
    command* {.importc: "command".}: cstring
    action* {.importc: "action".}: proc (argc: cint; argv: cstringArray) {.cdecl.}
    help* {.importc: "help".}: proc () {.cdecl.}

proc init*(): void {.cdecl, importc:"shell_init", header: "shell.h".}

proc shell_register_command(command: ptr shell_cmd): cint {.cdecl, importc: "shell_register_command", header: "shell.h".}

template register_command*(cmd, help_str: cstring, cb: shell_callback): int =
  proc `cb help`(): void {.cdecl.} =
    printf("%s - %s\n", cmd, help_str)
  var x = shell_cmd(command: cmd, action: cb, help: `cb help`)

  shell_register_command(x.addr)

template shell_handler*(cmd, actions: untyped) {.dirty.} =
  proc cmd(argc: cint, argv: cstringArray): void {.cdecl.} =
    actions
