
const
  usart1* = 0
  usart2* = 1

# TODO: How much should be ported up to Nim?
# Interfaces to the underlying C Functions
proc usart_init(usart_no: int, baudrate: uint32): void {.importc.}


# Public API
proc init*(usart_no: int, baudrate: uint32): void =
  usart_init(usart_no, baudrate)
