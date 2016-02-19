import rtos
import stdio
import usart
import shell
import cstrmatch
import assertions

var tickCount: int

# Application and stack overflow hooks are implemented as templates to
# free the user from the underlying pragma requirements
rtosApplicationTickHook:
  return

rtosStackOverflowHook:
  errFatal("Stack overflowed")

timerHandler(tick_callback):
  tickCount += 1

shellHandler(print_ticks):
  printf("Tick Count: %d", tickCount)

shellHandler(arg_example):
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
  printf("\nHello world\n")

  shell.init()
  discard shell.registerCommand("ticks", "print number of elapsed ticks", print_ticks)
  discard shell.registerCommand("arg", "arg example [foo, bar, baz]", arg_example)

  var tickTimer = rtos.createSoftTimer("Tick", 1000, true, nil, tick_callback)
  assertFatal(tickTimer == nil)

  discard rtos.startSoftTimer(tick_timer, 0)

  rtos.deleteTask(nil)

when isMainModule:
  stdio.enableUnbufferedIO()
  discard rtos.createTask(setup_task, "Setup Task", 150, nil, 8)

  rtos.startScheduler()
