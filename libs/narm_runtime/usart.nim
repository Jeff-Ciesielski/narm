
const
  usart1* = 0
  usart2* = 1

# TODO: How much should be ported up to Nim?
# Interfaces to the underlying C Functions
proc usart_init(usart_no: int, baudrate: uint32): void {.importc.}

proc write*(usartNo: int, source: cstring, length: int): int {.importc: "usart_write", header: "usart.h", cdecl.}
proc read*(usartNo: int, dest: cstring, length: int, timeout: uint32): int {.importc: "usart_read", header: "usart.h", cdecl.}

# Public API
proc init*(usart_no: int, baudrate: uint32): void =
  usart_init(usart_no, baudrate)
