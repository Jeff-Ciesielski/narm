type rtos_task = (proc(x: pointer):void)
type task_handle = pointer

proc task_create*(task: rtos_task, task_name: string, stack_size: uint16, priority: uint32): task_handle {.importc.}
proc start_scheduler*(): void {.importc.}
proc task_delete*(task: task_handle): void {.importc.}
