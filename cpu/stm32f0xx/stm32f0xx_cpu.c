#include <cpu.h>
#include <stdio.h>
#include "stm32f0xx.h"

volatile static uint64_t ticks = 0;

void SysTick_Handler(void)
{
	ticks += 1;
}

int system_init(void)
{
	SysTick_Config(SystemCoreClock / 1000);
	return 0;
}

uint64_t get_system_time(void)
{
	return ticks;
}

void system_sleep(void)
{
	__WFI();
}
