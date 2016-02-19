import stdio
import strutils

template assertFatal*(assertion: bool): void =
  if assertion == true:
    const position = instantiationInfo()
    const fnSplit = position.filename.split("/")
    const fileName = fnSplit[fnSplit.len - 1]
    printf("Fatal: Assertion failed @ %s: %s\n", fileName, $position.line)
    while true:
      discard

template assertWarn*(assertion: bool): void =
  if assertion != true:
    const position = instantiationInfo()
    const fnSplit = position.filename.split("/")
    const fileName = fnSplit[fnSplit.len - 1]
    printf("Warning: Assertion failed @ %s: %s\n", fileName, $position.line)

template errFatal*(message: string): void =
  const position = instantiationInfo()
  const fnSplit = position.filename.split("/")
  const fileName = fnSplit[fnSplit.len - 1]
  printf("Fatal error: %s @ %s:%s\n", message, fileName, $position.line)
  while true:
    discard

template errWarning*(message: string): void =
  const position = instantiationInfo()
  const fnSplit = position.filename.split("/")
  const fileName = fnSplit[fnSplit.len - 1]
  printf("Warning: %s @ %s:%s\n", message, fileName, $position.line)
  
