import rtos
import stdio
import usart

var tick_count: int

proc blink_callback(exp_timer: timer_handle): void =
  printf("tick_count: %d\n", tick_count)
  tick_count += 1

proc setup_task(params: pointer): void =

  # Init the debug usart
  usart2.init(115200)
  printf("Hello world\n")
  var blink_timer = rtos.create_soft_timer("Blink", 1000, true, blink_callback)

  discard rtos.start_soft_timer(blink_timer, 0)

  rtos.delete_task(nil)

when isMainModule:
  stdio.enable_unbuffered_io()
  discard rtos.create_task(setup_task, "Setup Task", 100, 8)
  rtos.start_scheduler()
