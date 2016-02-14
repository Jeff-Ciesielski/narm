
# Task related types
type rtos_task = (proc(x: pointer):void)
type task_handle = pointer

# Timer related types
type timer_handle* = pointer
type timer_callback* = (proc(x: timer_handle):void)

# Task management functions
proc create_task*(task: rtos_task, task_name: string, stack_size: uint16, priority: uint32): task_handle {.importc.}
proc start_scheduler*(): void {.importc.}
proc delete_task*(task: task_handle): void {.importc.}

# Timer management
proc create_soft_timer*(timer_name: string, tick_rate: uint32, auto_reload: bool, callback: timer_callback): timer_handle {.importc.}
proc start_soft_timer*(timer: timer_handle, ticks_to_wait: uint32): bool {.importc.}

