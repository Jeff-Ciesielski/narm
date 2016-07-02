import coro
import stdio
import assertions
import narmosqueue

# Exported namespaces
export narmosqueue
export assertions
export stdio

type
  TaskHandle* = pointer
  Task* = (proc(arg: pointer): pointer {.cdecl.})
  TaskIndex* = range[0..16]

  TimerIndex* = range[0..16]
  Timer* = (proc(arg: pointer): void {.cdecl.})

  TimerType* = enum
    Inactive = 0
    OneShot = 1
    Periodic = 2

  TimerObj = object
    callback: Timer
    expiration: uint64
    period: uint64
    timerType: TimerType
    next: ptr TimerObj

  TaskObj = object
    handle: TaskHandle
    stackSize: uint
    task: Task
    next: ptr TaskObj

  Scheduler* = object

    tasks: array[16, TaskObj]
    taskCount: TaskIndex
    nextTask: ptr TaskObj

    timers: array[16, TimerObj]
    timerCount: TimerIndex
    nextTimer: ptr TimerObj

    started: bool


# global scheduler singleton
var theScheduler* = Scheduler()

# System utilities
proc systemInit(): bool {.importc: "system_init", header: "cpu.h", cdecl.}
proc systemTime*(): uint64 {.importc: "get_system_time", header:"cpu.h", cdecl.}
template stackConsumed*(): uint =
  coGetConsumedStack()

proc systemSleep(): void {.importc: "system_sleep", header:"cpu.h", cdecl.}

# Task utilities
template declareTask*(name, actions: untyped) =
  proc `name`(args: pointer): pointer {.cdecl.} =
    actions

template taskYield*() =
  discard coYield(nil)

proc taskSleep*(ticksToSleep: uint64) =
  let wakeTime = systemTime() + ticksToSleep
  while systemTime() < wakeTime:
    taskYield()

proc createTask*(t: Task, stackSize: uint): TaskHandle =
  assertFatal(theScheduler.started)
  theScheduler.tasks[theScheduler.taskCount].task = t
  theScheduler.tasks[theScheduler.taskCount].stackSize = stackSize
  inc(theScheduler.taskCount)

# Timer utilities
template declareTimer*(name, actions: untyped) =
  proc `name`(args: pointer): void {.cdecl.} =
    actions

proc getAvailableTimer(): TimerIndex =
  var timerAvailable = false

  for i in 0..<theScheduler.timers.len:
    if theScheduler.timers[i].timerType == Inactive:
      result = i
      timerAvailable = true
      break

  assertFatal(timerAvailable == false)

proc sequenceTimer(t: ptr TimerObj, s: ptr Scheduler = theScheduler.addr): void =
  # TODO: Convert to heap or BST
  if s.nextTimer == nil:
    s.nextTimer = t
    t.next = nil
  else:
    var head = s.nextTimer

    # First, check to see if we should just take over the front of the line
    if t.expiration < head.expiration:
      t.next = head
      s.nextTimer = t
    else:
      while head != nil:
        if head.next == nil or t.expiration < head.next.expiration:
          let storage: ptr TimerObj = head.next
          head.next = t
          t.next = storage
          return

        head = head.next

proc queueNextTimer(s: ptr Scheduler = theScheduler.addr): void =
  s.nextTimer = s.nextTimer.next

proc startGenericTimer(t: Timer, tType: TimerType, period, expiration: uint64): TimerIndex =

  result = getAvailableTimer()

  theScheduler.timers[result].callback = t
  theScheduler.timers[result].timerType = tType
  theScheduler.timers[result].expiration = expiration
  theScheduler.timers[result].period = period

  theScheduler.timers[result].addr.sequenceTimer()


template startPeriodicTimer*(t: Timer, period: uint64): TimerIndex =
  startGenericTimer(t, Periodic, period, systemTime() + period)

template startOneShotTimer*(t: Timer, duration: uint64): TimerIndex =
  startGenericTimer(t, OneShot, 0, systemTime() + duration)

template startAbsoluteTimer*(t: Timer, expiration: uint64): TimerIndex =
  startGenericTimer(t, OneShot, 0, expiration)

declareTask(timerTask):
  while true:
    taskYield()
    let execTime = systemTime()
    theScheduler.nextTimer.callback(nil)
    let spentTimer = theScheduler.nextTimer
    theScheduler.addr.queueNextTimer()
    case spentTimer.timerType:
      of OneShot:  spentTimer.timerType = Inactive
      of Periodic:
        spentTimer.expiration = execTime + spentTimer.period
        spentTimer.sequenceTimer()
      else: continue

declareTask(bookEndTask):
  return

proc startScheduler*(requiredStack: uint = 1024): void =

  assertFatal(systemInit())

  # Create the timer task
  let timerTask = createTask(timerTask, 512)

  # Create the bookend.  This is only around to ensure that we stay
  # within our memory bounds and accurately track our stack usage
  let bookEnd = createTask(bookEndTask, 0)

  # Mark the scheduler as started to prevent any further task creation
  theScheduler.started = true
  var lastTask: ptr TaskObj

  # Now, spawn all of the threads using the previous thread's stack
  # space requirement (When stacks are created, they're created to
  # allow the current frame to keep growing) and schedule them in a
  # linked ring formation

  # TODO: Add other scheduling algos (prio queue, etc)
  for i in 0..<theScheduler.taskCount:
    var stackSize: uint
    if i == 0:
      stackSize = requiredStack
    else:
      stackSize = theScheduler.tasks[i - 1].stackSize

    theScheduler.tasks[i].handle = theScheduler.tasks[i].task.coSpawn(stackSize)

    if i == 0:
      lastTask = theScheduler.tasks[i].addr
      theScheduler.nextTask = lastTask
    else:
      lastTask.next = theScheduler.tasks[i].addr
      lastTask = lastTask.next

  # Complete the loop
  lastTask.next = theScheduler.nextTask

  assertFatal(not theScheduler.nextTask.handle.resumable(), "Unable to start first task")

  # Simple round robin scheduling
  while theScheduler.taskCount > 0:

    discard theScheduler.nextTask.handle.resume()
    # If the next task is not resumable, we should just remove it from
    # the list and carry on
    if not theScheduler.nextTask.next.handle.resumable():
      # TODO: add dead tasks list
      theScheduler.nextTask.next = theScheduler.nextTask.next.next
      dec(theScheduler.taskCount)


    # If there are any timers expired, go service them
    if (theScheduler.nextTimer != nil) and (systemTime() >= theScheduler.nextTimer.expiration):
      discard timerTask.resume()
      assertFatal(not timertask.resumable(), "Timer task exited unexpectedly")

    theScheduler.nextTask = theScheduler.nextTask.next

    systemSleep()

  errFatal("Scheduler exited unexpectedly")
