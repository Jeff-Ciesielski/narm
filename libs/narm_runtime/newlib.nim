import stdio
import usart
import rtos
import unistd

const
  writeBufMaxSize = 32

var boardDebugIface = usart2

proc nlRead(f: int, dest: cstring, length: int): int {.exportc: "_read", cdecl.} =
  case f
  of stdInFileNo:
    result = boardDebugIface.read(dest, length, MaxDelay)

  else:
    result = -1

proc nlWrite(file: int, src: cstring, length: int): int {.exportc: "_write", cdecl.} =
  case file
  of stdOutFileNo, stdErrFileNo:
    var i = 0
    var tempBuf: array[0..writeBufMaxSize, char]

    while i < length:
      var j = 0
      while j < tempBuf.len - 1 and j < length:
        if src[i] == '\L':
          tempBuf[j] = '\r'
          inc(j)
        tempBuf[j] = src[i]
        inc(i)
        inc(j)

      # TODO: This will need to change once we move to nim based
      # device drivers
      result = boardDebugIface.write(tempBuf[0].addr, j)

  else:
    # TODO: set errno to EBADF
    result = -1
