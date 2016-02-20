var MaxDelay* {.importc: "portMAX_DELAY", header: "FreeRTOSWrap.h".}: uint32

type
  # Task related types
  Task* = (proc(params: pointer):void {.cdecl.})
  TaskHandle* = pointer

  NotificationAction {.pure.} = enum
    None = 0,
    SetBits,
    Increment,
    SetWithOverwrite,
    SetWithoutOverwrite,

  # Timer related types
  TimerHandle* = pointer
  TimerCallback* = (proc(x: TimerHandle):void {.cdecl.})

  # Lock related types
  SemaphoreHandle = pointer

# FreeRTOS Private wrappers
proc xTaskCreate(
    t: Task,
    taskName: cstring,
    stackSize: uint16,
    parameters: pointer,
    priority: uint32,
    created_task: ptr TaskHandle): bool {.importc: "xTaskCreate", header: "FreeRTOSWrap.h", cdecl.}
proc xTaskNotify(
    t: TaskHandle,
    value: uint32,
    action: NotificationAction): bool {.importc: "xTaskNotify", header: "FreeRTOSWrap.h", cdecl.}
proc xTaskNotifyWait(
    bitsClearedOnEntry: uint32,
    bitsClearedOnExit: uint32,
    notificationAction: ptr uint32,
    ticksToWait: uint32): bool {.importc: "xTaskNotifyWait", header:"FreeRTOSWrap.h", cdecl.}

proc vSemaphoreCreateBinary(smphr: SemaphoreHandle): void {.importc: "vSemaphoreCreateBinary", header:"FreeRTOSWrap.h", cdecl.}
proc getCurrentTask(): TaskHandle {.importc:"xTaskGetCurrentTaskHandle", header:"FreeRTOSWrap.h", cdecl.}

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

template currentTask*: TaskHandle =
  getCurrentTask()

template rtosTask*(name, actions: untyped): void =
  proc `name`(params: pointer): void {.cdecl.} =
    actions

proc createTask*(t: Task, taskName: cstring, stackSize: uint16, parameters: pointer = nil, priority: uint32): (bool, TaskHandle)  =
  var tHandle: TaskHandle
  var retVal = xTaskCreate(t, taskname, stackSize, parameters, priority, tHandle.addr)

  return (retVal, tHandle)

proc deleteTask*(t: TaskHandle): void {.importc: "vTaskDelete", header:"FreeRTOSWrap.h", cdecl.}
proc startScheduler*(): void {.importc: "vTaskStartScheduler",header: "FreeRTOSWrap.h", cdecl.}

proc notify*(t: TaskHandle, value: uint32, action: NotificationAction): bool =
  result = xTaskNotify(t, value, action)

proc wait*(bitsClearedOnEntry, bitsClearedOnExit: uint32, ticksToWait: uint32 = MaxDelay): auto =
  var notifyValue: uint32
  var retVal = xTaskNotifyWait(bitsClearedOnEntry, bitsClearedOnExit, notifyValue.addr, ticksToWait)

  return (retVal, notifyValue)

# Timer management
template timerHandler*(name, actions: untyped): void =
  proc `name`(et: TimerHandle): void {.cdecl.}=
    actions

proc createSoftTimer*(
    timerName: cstring,
    periodInTicks: uint32,
    autoReload: bool,
    timerId: pointer = nil,
    handler: TimerCallback): TimerHandle {.importc: "xTimerCreate", header:"FreeRTOSWrap.h", cdecl.}

proc startSoftTimer*(timer: TimerHandle, ticksToWait: uint32): bool {.importc: "xTimerStart", header: "FreeRTOSWrap.h", cdecl.}

# Lock management
proc createBinarySemaphore*(): SemaphoreHandle =
  vSemaphoreCreateBinary(result.addr)

proc give*(smphr: SemaphoreHandle): bool {.importc:"xSemaphoreGive", header:"FreeRTOSWrap.h", cdecl.}
proc take*(smphr: SemaphoreHandle, blockTime: uint32 = MaxDelay): bool {.importc: "xSemaphoreTake", header: "FreeRTOSWrap.h", cdecl}
