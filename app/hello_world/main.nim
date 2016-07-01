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

var helloMutex = declareMutex()

declareTask(printout1):
  withLock(helloMutex):
    printf("H")
    taskYield()
    printf("e")
    taskYield()
    printf("l")
    taskYield()
    printf("l")
    taskYield()
    printf("o")
    taskYield()
    printf(" ")

declareTask(printout2):
  withLock(helloMutex):
    taskYield()
    printf("W")
    taskYield()
    printf("o")
    taskYield()
    printf("r")
    taskYield()
    printf("l")
    taskYield()
    printf("d")
    taskYield()
    printf("\n")

declareTask(sleepyTask):
  withLock(helloMutex):
    printf("Going to sleep now!\n")
    taskSleep(5000)
    printf("I slept for 5 seconds!\n")

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
  discard createTask(printout1, 1024)
  discard createTask(printout2, 1024)
  discard createTask(sleepyTask, 1024)

proc main() =
  enableUnbufferedIO()
  discard createTask(setupTask, 1024)

  startScheduler()

main()
