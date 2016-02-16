import rtos
import stdio
import usart
import shell
import cstrmatch

var tick_count: int

proc tick_callback(exp_timer: timer_handle): void =
  tick_count += 1

shell_handler(print_ticks):
  printf("Tick Count: %d", tick_count)

shell_handler(arg_example):
  for x in 1..argc-1:
    if argv[x] ~= "foo":
      printf("handler for 'foo'\n")
    elif argv[x] ~= "bar":
      printf("handler for 'bar'\n")
    elif argv[x] ~= "baz":
      printf("handler for 'baz'\n")
    else:
      printf("Unhandled arg: %d - %s", x, argv[x])

proc setup_task(params: pointer): void =

  # Init the debug usart
  usart2.init(115200)
  printf("Hello world\n")

  shell.init()
  discard shell.register_command("ticks", "print number of elapsed ticks", print_ticks)
  discard shell.register_command("arg", "arg example [foo, bar, baz]", arg_example)

  var tick_timer = rtos.create_soft_timer("Tick", 1000, true, tick_callback)

  discard rtos.start_soft_timer(tick_timer, 0)

  rtos.delete_task(nil)

when isMainModule:
  stdio.enable_unbuffered_io()
  discard rtos.create_task(setup_task, "Setup Task", 100, 8)
  rtos.start_scheduler()
