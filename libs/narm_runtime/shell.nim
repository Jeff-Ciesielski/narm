import stdio


type
  ShellCallback = (proc(argc: cint, argv: cstringArray):void {.cdecl.})

  ShellCommand* {.importc: "struct shell_cmd", header: "shell.h".} = object
    command* {.importc: "command".}: cstring
    action* {.importc: "action".}: proc (argc: cint; argv: cstringArray) {.cdecl.}
    help* {.importc: "help".}: proc () {.cdecl.}

proc init*(): void {.cdecl, importc:"shell_init", header: "shell.h".}

proc cshellRegisterCommand(command: ptr ShellCommand): cint {.cdecl, importc: "shell_register_command", header: "shell.h".}

template registerCommand*(cmd, help_str: cstring, cb: ShellCallback): int =
  proc `cb help`(): void {.cdecl.} =
    printf("%s - %s\n", cmd, help_str)
  var x {.global.} = ShellCommand(command: cmd, action: cb, help: `cb help`)

  cshellRegisterCommand(x.addr)

template shellHandler*(cmd, actions: untyped) {.dirty.} =
  proc cmd(argc: cint, argv: cstringArray): void {.cdecl.} =
    actions
