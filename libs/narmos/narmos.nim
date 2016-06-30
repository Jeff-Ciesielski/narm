import coro
import stdio

import narmosqueue
export narmosqueue

type
  TaskHandle* = pointer
  Task* = (proc(arg: pointer): pointer {.cdecl.})

  Scheduler* = object
    tasks: array[16, TaskHandle]
    taskCount: range[0..16]


# global scheduler singleton
var theScheduler* = Scheduler()

template declareTask*(name, actions: untyped) =
  proc `name`(args: pointer): pointer {.cdecl.} =
    actions

template taskYield*() =
  discard coYield(nil)

proc createTask*(t: Task, stackSize: uint = 128): TaskHandle =
  result = t.coSpawn(stackSize)
  theScheduler.tasks[theScheduler.taskCount] = result
  inc(theScheduler.taskCount)


proc systemInit(): int {.importc: "system_init", header: "cpu.h", cdecl.}
proc systemTime(): uint64 {.importc: "get_system_time", header:"cpu.h", cdecl.}

proc startScheduler*(): void =

  discard systemInit()

  # Simple round robin scheduling
  # TODO: Add other scheduling algos (prio queue, etc)
  while theScheduler.taskCount > 0:
    for i in 0..<theScheduler.taskCount:
      if theScheduler.tasks[i].resumable:
        discard theScheduler.tasks[i].resume()
      else:
        dec(theScheduler.taskCount)

  printf("no more tasks")

  
