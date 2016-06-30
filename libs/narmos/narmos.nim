import coro
import stdio
import assertions

import narmosqueue
export narmosqueue

# TODO: Improve scheduling all around...

type
  TaskHandle* = pointer
  Task* = (proc(arg: pointer): pointer {.cdecl.})
  TaskIndex* = range[0..16]

  TimerIndex* = range[0..16]
  Timer* = (proc(arg: pointer): void {.cdecl.})

  TimerType* = enum
    inactive = 0
    oneShot = 1
    periodic = 2

  TimerObj = object
    callback: Timer
    expiration: uint64
    period: uint64
    timerType: TimerType

  Scheduler* = object
    tasks: array[16, TaskHandle]
    taskCount: TaskIndex

    timers: array[16, TimerObj]
    timerCount: TimerIndex


# global scheduler singleton
var theScheduler* = Scheduler()

proc systemInit(): int {.importc: "system_init", header: "cpu.h", cdecl.}
proc systemTime*(): uint64 {.importc: "get_system_time", header:"cpu.h", cdecl.}

# Task utilities
template declareTask*(name, actions: untyped) =
  proc `name`(args: pointer): pointer {.cdecl.} =
    actions

template taskYield*() =
  discard coYield(nil)

proc createTask*(t: Task, stackSize: uint = 128): TaskHandle =
  result = t.coSpawn(stackSize)
  theScheduler.tasks[theScheduler.taskCount] = t.coSpawn(stackSize)
  inc(theScheduler.taskCount)

# Timer utilities
template declareTimer*(name, actions: untyped) =
  proc `name`(args: pointer): void {.cdecl.} =
    actions

proc getAvailableTimer(): TimerIndex =
  var timerAvailable = false

  for i in 0..<theScheduler.timers.len:
    if theScheduler.timers[i].timerType == inactive:
      result = i
      timerAvailable = true
      break

  assertFatal(timerAvailable == false)


proc startPeriodicTimer*(t: Timer, period: uint64): TimerIndex =

  result = getAvailableTimer()

  theScheduler.timers[result].callback = t
  theScheduler.timers[result].timerType = periodic
  theScheduler.timers[result].expiration = systemTime() + period
  theScheduler.timers[result].period = systemTime() + period


proc startOneShotTimer*(t: Timer, period: uint64): TimerIndex =

  result = getAvailableTimer()

  theScheduler.timers[result].callback = t
  theScheduler.timers[result].timerType = oneShot
  theScheduler.timers[result].expiration = systemTime() + period


declareTask(timerTask):
  while true:
    for i in 0..theScheduler.timers.high:
      if (theScheduler.timers[i].timerType != inactive) and (systemTime() >= theScheduler.timers[i].expiration):
        let execTime = systemTime()
        theScheduler.timers[i].callback(nil)
        case theScheduler.timers[i].timerType:
          of oneShot:  theScheduler.timers[i].timerType = inactive
          of periodic: theScheduler.timers[i].expiration = execTime + theScheduler.timers[i].period
          else: continue
    taskYield()

proc startScheduler*(): void =

  # TODO: Don't discard
  discard systemInit()
  let timerTask = createTask(timerTask, 512)

  # Simple round robin scheduling
  # TODO: Add other scheduling algos (prio queue, etc)
  # TODO: add a way to mark tasks 'dead'
  while theScheduler.taskCount > 0:
    for i in 0..<theScheduler.taskCount:
      if theScheduler.tasks[i].resumable():
        discard theScheduler.tasks[i].resume()

    if timertask.resumable():
      discard timerTask.resume()

  printf("no more tasks")
