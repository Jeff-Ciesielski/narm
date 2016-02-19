import assertions

var MaxDelay* {.importc: "portMAX_DELAY", header: "FreeRTOSWrap.h".}: cint

type
  # Task related types
  Task* = (proc(params: pointer):void {.cdecl.})
  TaskHandle* = pointer

  # Timer related types
  TimerHandle* = pointer
  TimerCallback* = (proc(x: TimerHandle):void {.cdecl.})

  # Lock related types
  SemaphoreHandle = pointer

# FreeRTOS Private wrappers
proc vTaskStartScheduler(): void {.importc: "vTaskStartScheduler",header: "FreeRTOSWrap.h", cdecl.}
proc vTaskDelete(t: TaskHandle): void {.importc: "vTaskDelete", header:"FreeRTOSWrap.h", cdecl.}
proc xTaskCreate(
    t: Task,
    taskName: cstring,
    stackSize: uint16,
    parameters: pointer,
    priority: uint32,
    created_task: TaskHandle): uint32 {.importc: "xTaskCreate", header: "FreeRTOSWrap.h", cdecl.}

proc xTimerCreate(
    timerName: cstring,
    periodInTicks: uint32,
    autoReload: uint32,
    timerId: pointer,
    callback: TimerCallback): TimerHandle {.importc: "xTimerCreate", header:"FreeRTOSWrap.h", cdecl.}

proc vSemaphoreCreateBinary(smphr: SemaphoreHandle): void {.importc: "vSemaphoreCreateBinary", header:"FreeRTOSWrap.h", cdecl.}
proc xSemaphoreGive(smphr: SemaphoreHandle): bool {.importc: "vSemaphoreCreateBinary", header:"FreeRTOSWrap.h", cdecl.}
proc xSemaphoreTake(smphr: SemaphoreHandle, blockTime: int): bool {.importc: "vSemaphoreCreateBinary", header:"FreeRTOSWrap.h", cdecl.}

proc xTimerStart(timer: TimerHandle, ticksToWayt: uint32): bool {.importc: "xTimerStart", header:"FreeRTOSWrap.h", cdecl.}

# OS Hooks
# TODO: Add some sort of check that generates a better error if these
# are declared twice
template rtosStackOverflowHook*(actions: untyped): void =
  proc vApplicationStackOverflowHook(pxTask: TaskHandle, pcTaskName: cstring): void {.exportc: "vApplicationStackOverflowHook", cdecl.} =
    actions

template rtosApplicationTickHook*(actions: untyped): void =
  proc vApplicationTickHook(): void {.exportc: "vApplicationTickHook", cdecl.} =
    actions
  

# Task management functions

template rtosTask*(name, actions: untyped): void =
  proc `name`(params: pointer): void {.cdecl.} =
    actions

proc createTask*(t: Task, taskName: cstring, stackSize: uint16, parameters: pointer = nil, priority: uint32): TaskHandle  =
  discard xTaskCreate(t, taskname, stackSize, parameters, priority, result.addr)

proc deleteTask*(t: TaskHandle): void =
  vTaskDelete(t)

proc startScheduler*(): void  =
  vTaskStartScheduler()

# Timer management
template timerHandler*(name, actions: untyped): void =
  proc `name`(et: TimerHandle): void {.cdecl.}=
    actions

proc createSoftTimer*(timerName: cstring, periodInTicks: uint32, autoReload: bool, timerId: pointer = nil, handler: TimerCallback): TimerHandle =
  result = xTimerCreate(timerName, periodInTicks, autoReload.uint32, timerId, handler)

proc startSoftTimer*(timer: TimerHandle, ticksToWait: uint32): bool =
  result = xTimerStart(timer, ticksToWait)

# Lock management
proc createBinarySemaphore*(): SemaphoreHandle =
  vSemaphoreCreateBinary(result.addr)

proc give*(smphr: SemaphoreHandle): bool =
  result = xSemaphoreGive(smphr)

proc take*(smphr: SemaphoreHandle, blockTime: int = MaxDelay): bool =
  result = xSemaphoreTake(smphr, blockTime)
