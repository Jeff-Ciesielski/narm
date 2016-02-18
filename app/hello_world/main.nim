import rtos
import stdio
import usart
import shell
import cstrmatch

var tick_count: int

rtosApplicationTickHook:
  return

rtosStackOverflowHook:
  printf("Stack overflowed")

timerHandler(tick_callback):
  tick_count += 1

shell_handler(print_ticks):
  printf("Tick Count: %d", tick_count)

shell_handler(arg_example):
  for x in 1..argc-1:
    if argv[x] == "foo":
      printf("handler for 'foo'\n")
    elif argv[x] == "bar":
      printf("handler for 'bar'\n")
    elif argv[x] == "baz":
      printf("handler for 'baz'\n")
    else:
      printf("Unhandled arg: %d - %s", x, argv[x])

rtosTask(setup_task):
  # Init the debug usart
  usart2.init(115200)
  printf("Hello world\n")

  shell.init()
  discard shell.register_command("ticks", "print number of elapsed ticks", print_ticks)
  discard shell.register_command("arg", "arg example [foo, bar, baz]", arg_example)

  var tick_timer = rtos.createSoftTimer("Tick", 1000, true, nil, tick_callback)

  discard rtos.startSoftTimer(tick_timer, 0)

  rtos.deleteTask(nil)

when isMainModule:
  stdio.enable_unbuffered_io()
  discard rtos.createTask(setup_task, "Setup Task", 100, nil, 8)
  rtos.startScheduler()
