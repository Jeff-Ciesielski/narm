import stdio


template assertFatal*(assertion: bool): void =
  const filename = instantiationInfo(-1, false).filename
  const position = instantiationInfo().line
  if assertion == true:
    printf("Fatal: Assertion failed @ %s: %d\n", fileName, position)
    while true:
      discard

template assertWarn*(assertion: bool): void =
  const filename = instantiationInfo(-1, false).filename
  const position = instantiationInfo().line
  if assertion != true:
    printf("Warning: Assertion failed @ %s: %d\n", filename, position)
    return

template errFatal*(message: string): void =
  const filename = instantiationInfo(-1, ).filename
  const position = instantiationInfo().line
  printf("Fatal error: %s @ %s:%d\n", message, filename, position)
  while true:
    discard

template errWarning*(message: string): void =
  const filename = instantiationInfo(-1, false).filename
  const position = instantiationInfo().line
  printf("Warning: %s @ %s:%d\n", message, pos.filename, $position.line)
  return
  
