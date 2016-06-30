import narmos
import usart
import shell
import cstrmatch

var  tickCount: int

declareTimer(OneSecondTick):
  inc(tickCount)

declareTimer(TenSecondNotification):
  printf("\nIt's been 10 seconds. System Time: (%dms)\n", systemTime().uint32)

declareTimer(TwelveFifteen):
  printf("\nIt's been 1215 ms. System Time: (%dms)\n", systemTime().uint32)

shellHandler(printTicks):
  printf("Tick Count: %d\n", tickCount)

shellHandler(printTime):
  printf("System Time (u32 scaled): %ld\n", systemTime().uint32)

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

declareTask(setupTask):
  # Init the debug usart
  usart2.init(115200)
  printf("\nHello world\n")

  shell.init()
  shell.registerCommand("ticks", "print number of elapsed ticks", printTicks)
  shell.registerCommand("time", "print the system time", printTime)
  shell.registerCommand("arg", "arg example [foo, bar, baz]", argExample)

  discard startPeriodicTimer(OneSecondTick, 1000)
  discard startOneShotTimer(TenSecondNotification, 10 * 1000)
  discard startAbsoluteTimer(TwelveFifteen, 1215)

when isMainModule:
  enableUnbufferedIO()
  discard createTask(setupTask, 1024)

  startScheduler()
