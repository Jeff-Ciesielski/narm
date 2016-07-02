import stdio


template assertFatal*(assertion: bool, message: string = ""): void =
  const filename = instantiationInfo(-1).filename
  const position = instantiationInfo().line
  if assertion:
    printf("Fatal: Assertion failed @ %s: %d\n", fileName, position)
    when len(message) > 0:
      printf("\t->%s\n", message)
    while true:
      discard

template assertWarn*(assertion: bool, message: string = ""): void =
  const filename = instantiationInfo(-1).filename
  const position = instantiationInfo().line
  if assertion:
    printf("Warning: Assertion failed @ %s: %d\n", filename, position)
    when len(message) > 0:
      printf("\t->%s\n", message)
    return

template errFatal*(message: string): void =
  const filename = instantiationInfo(-1).filename
  const position = instantiationInfo().line
  printf("Fatal error: %s @ %s:%d\n", message, filename, position)
  while true:
    discard

template errWarning*(message: string): void =
  const filename = instantiationInfo(-1).filename
  const position = instantiationInfo().line
  printf("Warning: %s @ %s:%d\n", message, pos.filename, position)
  return
  
