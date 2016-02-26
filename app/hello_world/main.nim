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

timerHandler(tickCallback):
  tickCount += 1

shellHandler(printTicks):
  printf("Tick Count: %d", tickCount)

shellHandler(argExample):
  for x in 1..argc-1:
    if argv[x] ~= "foo":
      printf("handler for 'foo'\n")
    elif argv[x] ~= "bar":
      printf("handler for 'bar'\n")
    elif argv[x] ~= "baz":
      printf("handler for 'baz'\n")
    else:
      printf("Unhandled arg: %d - %s", x, argv[x])

rtosTask(setupTask):
  # Init the debug usart
  usart2.init(115200)
  printf("\nHello world\n")

  shell.init()
  shell.registerCommand("ticks", "print number of elapsed ticks", printTicks)
  shell.registerCommand("arg", "arg example [foo, bar, baz]", argExample)

  var tickTimer = rtos.createSoftTimer("Tick", 1000, true, nil, tickCallback)
  assertFatal(tickTimer == nil)

  discard rtos.startSoftTimer(tick_timer, 0)

  currentTask.deleteTask()

when isMainModule:
  stdio.enableUnbufferedIO()
  discard rtos.createTask(setupTask, "Setup Task", 150, nil, 8)

  rtos.startScheduler()
