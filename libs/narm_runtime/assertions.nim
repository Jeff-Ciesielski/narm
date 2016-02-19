import stdio
import strutils


template assertFatal*(assertion: bool, message: string): void =
  if assertion == true:
    const position = instantiationInfo()
    const fnSplit = position.filename.split("/")
    const fileName = fnSplit[fnSplit.len - 1]
    printf("Assertion failed at - %s: %s\n", fileName, $position.line)
    printf("Fatal: %s\n", message)
    while true:
      discard

template assertWarn*(assertion: untyped, message: string): void =
  if assertion != true:
    const position = instantiationInfo()
    const fnSplit = position.filename.split("/")
    const fileName = fnSplit[fnSplit.len - 1]
    printf("Assertion failed at - %s: %s\n", fileName, $position.line)
    printf("Warning, failed assertion. %s\n", message)

template errFatal*(message: string): void =
  printf("Fatal error: %s\n", message)
  while true:
    discard

template errWarning*(message: string): void =
  printf("Warning error: %s\n", message)
  
