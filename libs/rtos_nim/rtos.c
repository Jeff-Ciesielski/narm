#include <FreeRTOS.h>
#include <task.h>

struct stack_frame {
	uint32_t psr;
	uint32_t pc;
	uint32_t lr;
	uint32_t r12;
	uint32_t r3;
	uint32_t r2;
	uint32_t r1;
	uint32_t r0;
} __attribute__((packed));

__attribute__((optimize("-O0")))
void HardFault_Handler(void)
{
	struct stack_frame *msf = (struct stack_frame*)__get_MSP();
	struct stack_frame *psf = (struct stack_frame*)__get_PSP();
	msf--;
	psf--;

	while(1);
}

void vApplicationTickHook(void)
{
}

void vApplicationStackOverflowHook(xTaskHandle pxTask, signed char *pcTaskName)
{
	(void)pxTask;
	(void)pcTaskName;
}

void *task_create(void(task)(void *params), char *task_name,
                  uint16_t stack_size, uint32_t priority)
{
    void *task_handle;
    
    /* TODO: Does a failure here cause task handle to be == NULL?
     * Need to check this */
    xTaskCreate(task,
                task_name,
                stack_size,
                NULL,
                priority,
                &task_handle);

    return task_handle;
}

void start_scheduler(void)
{
    vTaskStartScheduler();
}

void task_delete(void *task)
{
    vTaskDelete(task);
}
