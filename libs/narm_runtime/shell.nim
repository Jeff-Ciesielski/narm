import stdio
import rtos
import cstrmatch

const
  ShellMaxCommands = 16
  InputBufferSize = 32
  MaxArgs* = 8

type
  ShellCallback = (proc(argc: int, argv: array[0 .. MaxArgs, cstring]):void)

  ShellCommand* = object
    command*: cstring
    action*: ShellCallback
    help*: proc ()

  ShellState = object
    initialized: bool
    lock: SemaphoreHandle
    commands: array[0 .. ShellMaxCommands, ShellCommand]
    commandCount: int
    inputBuf: array[0 .. InputBufferSize, char]
    inputPos: int

var state* =  ShellState()

const shellPromptText = "> ";
const shellBanner = "\n\nCommand Shell";

template registerCommand*(cmd, help_str: string, cb: ShellCallback) {.dirty.} =
  # TODO: Check that we haven't run over our total command count... I
  # feel like we can do this at compile time...

  proc `cb help`(): void =
    printf("%s - %s\n", cmd, help_str)

  state.commands[state.commandCount] = ShellCommand(command: cmd, action: cb, help: `cb help`)
  state.commandCount += 1

template shellHandler*(cmd, actions: untyped) {.dirty.} =
  proc cmd(argc: int, argv: array[0 .. MaxArgs, cstring]): void =
    actions

shellHandler(shellHelp):
  printf("Shell Commands: (case sensitive!)\n")
  for i in 0..state.commandCount - 1:
    state.commands[i].help()

proc isWhiteSpace(c: char): bool =
  case c
  of '\t', '\L', '\r', '\v', '\f', ' ':
    result = true
  else:
    result = false

proc execCommand(argCount: int, argList: array[0 .. MaxArgs, cstring]): void =
  for i in 0 .. state.commandCount - 1:
    let cmd = state.commands[i]
    if argList[0] ~= cmd.command:
      cmd.action(argCount, argList)
      discard putchar('\L')
      return

proc parseCommand(): void =
  var argList: array[0 .. MaxArgs, cstring]
  var inArg: bool
  var argCount: int

  for i in 0 .. state.inputPos - 1:
    if isWhiteSpace(state.inputBuf[i]) and inArg:
        state.inputBuf[i] = '\0'
        inArg = false
    elif not inArg and argCount < MaxArgs:
      argList[argCount] = state.inputBuf[i].addr
      argCount += 1
      inArg = true

  state.inputBuf[state.inputPos] = '\0'

  if argCount > 0:
    execCommand(argCount, argList)

proc processInput(): void =
  let result = getchar()

  if result < 0:
    return

  var c = cast[char](result)

  case c
  of '\r', '\L':
    discard putchar('\L')

    if state.inputPos > 0:
      parseCommand()

    state.inputPos = 0
    printf("%s", shellPromptText)
  of '\b':
    if state.inputPos > 0:
      state.inputPos -= 1
      discard putchar('\b')
      discard putchar(' ')
      discard putchar('\b')
  else:
    if state.inputPos >= state.inputBuf.len - 1:
      printf("Invalid Command!\n");
      state.inputPos = 0
    state.inputBuf[state.inputPos] = c
    state.inputPos += 1
    discard putchar(c)


rtosTask(shellTask):
  printf("%s\n%s", shellBanner, shellPromptText)
  while true:
    processInput()


proc init*(): void =

  state.lock = createBinarySemaphore()
  registerCommand("help", "Show this dialog", shellHelp)
  discard rtos.createTask(shellTask, "Shell", 350, nil, 8)

  state.initialized = true
