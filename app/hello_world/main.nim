import rtos

proc usart_init(usart_no: int, baudrate: uint32): void {.importc.}

proc setup_task(params: pointer): void =
  # Init the debug usart
  usart_init(1, 115200);

  echo("Hello world")
  rtos.task_delete(nil)

when isMainModule:
  discard rtos.task_create(setup_task, "Setup Task", 100, 8)
  rtos.start_scheduler()
