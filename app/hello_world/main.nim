import rtos
import utils

proc printf(formatstr: cstring) {.importc: "printf", varargs,
                                  header: "<stdio.h>".}

proc usart_init(usart_no: int, baudrate: uint32): void {.importc.}

var tick_count: int

proc blink_callback(exp_timer: timer_handle): void =
  printf("tick_count: %d\n", tick_count)
  tick_count += 1

proc setup_task(params: pointer): void =

  # Init the debug usart
  usart_init(1, 115200)
  printf("Hello world\n")
  var blink_timer = rtos.create_soft_timer("Blink", 1000, true, blink_callback)

  discard rtos.start_soft_timer(blink_timer, 0)

  delete_task(nil)

when isMainModule:
  utils.enable_unbuffered_io() 
  discard rtos.create_task(setup_task, "Setup Task", 100, 8)
  rtos.start_scheduler()
