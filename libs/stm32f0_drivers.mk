# Command shell configuration file
#
# Jeff Ciesielski <jeff.ciesielski@gmail.com>

ifneq ($(STM32F0_DRIVERS),)

STM32F0_DRIVERS_SOURCE ?= $(LIB_PATH)/stm32f0_drivers

#LIB_C_FILES += $(wildcard $(STM32F0_DRIVERS_SOURCE)/*.c)
LIB_C_FILES += $(STM32F0_DRIVERS_SOURCE)/usart.c
# Shell includes
LIB_INCLUDES += -I$(STM32F0_DRIVERS_SOURCE)

endif
