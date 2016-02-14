# Copyright (C) 2015 Jeff Ciesielski <jeffciesielski@gmail.com>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.

ifeq ($(APP),)
  ifeq ($(wildcard app.default),)
    $(error APP is not defined.  Pass it in as APP= or create a config.mk file)
  else
    APP = $(shell cat app.default)
  endif
else
  $(shell echo "$(APP)" > app.default)
endif

APP_PATH     := app/$(APP)
LIB_PATH     := libs
APP_INCLUDES += -I$(APP_PATH)

# load the board specific configuration
include $(APP_PATH)/config.mk

ifeq ($(CPU_TYPE),)
  $(error CPU_TYPE is not defined, please ensure it is defined in your cpu config.mk)
endif

PREFIX	?= arm-none-eabi-

CC      := $(PREFIX)gcc
AS      := $(PREFIX)as
CXX     := $(PREFIX)g++
AR      := $(PREFIX)gcc-ar
NM      := $(PREFIX)gcc-nm
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE    := $(PREFIX)size
RANLIB  := $(PREFIX)gcc-ranlib

OPENOCD := openocd
DDD     := ddd
GDB     := $(PREFIX)gdb

NIM     := $(shell which nim)

# Grab the nim base include path
NIM_PATHS = $(shell nim dump 2>&1 | grep /lib)
NIM_INCLUDES = $(patsubst %, -I%, $(NIM_PATHS))

LIBS = -lnosys

INCLUDES += $(CPU_INCLUDES) $(BOARD_INCLUDES) $(LIB_INCLUDES) $(APP_INCLUDES) $(NIM_INCLUDES)
CFLAGS    = $(INCLUDES) $(CPU_DEFINES) $(BOARD_DEFINES) $(APP_DEFINES) $(CPU_FLAGS) \
	-Os -Wall -Wno-pragmas -fno-common -c -mthumb -ffunction-sections -fdata-sections -flto \
	-mcpu=$(CPU_TYPE) -MD -std=gnu99

ASFLAGS   = -mcpu=$(CPU_TYPE) $(FPU) -g -Wa,--warn
ARFLAGS   = rcs
LDFLAGS  ?= --specs=nano.specs -lc -lgcc $(LIBS) -mcpu=$(CPU_TYPE) -g -gdwarf-2 \
	 -L. -Lcpu/common -L$(APP_PATH) -T$(LINK_MEM) \
	 -nostartfiles -Wl,--gc-sections -mthumb -mcpu=$(CPU_TYPE) \
	 -msoft-float -ffunction-sections -fdata-sections -flto -Os -Wl,-Map,$(TARGET).map

# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
  Q := @
  # Do not print "Entering directory ...".
  MAKEFLAGS += --no-print-directory
  # Redirect stdout/stderr for chatty tools
  NOOUT = 1> /dev/null 2> /dev/null
endif

# This file is dynamically created based on the libraries in the libs/ folder
-include libs.mk

LIB_C_FILES += $(wildcard libs/rtos_nim/*.c) $(wildcard libs/nim_runtime/*.c)

APP_O_FILES = $(APP_C_FILES:.c=.o) $(APP_S_FILES:.s=.o)
LIB_O_FILES  = $(LIB_C_FILES:.c=.o) $(LIB_S_FILES:.s=.o)

ifeq ($(TARGET),)
  $(error TARGET is not defined, please define it in your applications config.mk)
endif

LIB_CONFIGS = $(wildcard $(LIB_PATH)/*.mk)

all: $(TARGET).bin

libs.mk: Makefile
	@printf " Generating library includes\n"
	@( $(foreach L,$(LIB_CONFIGS),echo 'include $L';) ) >$@

$(TARGET).bin: $(TARGET).elf
	@printf "  OBJCOPY $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(OBJCOPY) -Obinary $< $@

nimcache:
	@printf " Regenerating Nim cache\n"
	$(Q)nim c --compile_only -p=libs/nim_runtime -p=libs/rtos_nim $(APP_PATH)/main.nim

$(TARGET).elf: nimcache libs.mk $(APP_O_FILES) $(LIB_O_FILES)
	@printf "  LD      $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(CC) -o $@ $(APP_O_FILES) $(LIB_O_FILES) $(LDFLAGS)
	$(Q)$(SIZE) $(TARGET).elf

%.nim: %.c
	@printf "  NIMC    $(subst $(shell pwd)/,,$(@))\n"

%.o: %.c
	@printf "  CC      $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.s
	@printf "  AS      $(subst $(shell pwd)/,,$(@))\n"
	$(Q)$(CC) $(ASFLAGS) -c -o $@ $<

clean:
	$(Q)rm -f \
	$(APP_D_FILES)              \
	$(APP_O_FILES)              \
	$(LIB_D_FILES)              \
	$(LIB_O_FILES)              \
	$(TARGET).bin $(TARGET).elf \
	$(TARGET).map               \
	$(LIBS_ALL)                 \
	libs.mk

st-flash: $(TARGET).bin
	sudo st-flash write $(TARGET).bin 0x08000000

debug: $(TARGET).elf
	$(OPENOCD) -f $(APP_PATH)/debug.ocd

flash: $(TARGET).elf
	$(OPENOCD) -f $(APP_PATH)/debug.ocd -f $(APP_PATH)/flash.ocd

ddd: $(TARGET).elf
	$(DDD) --eval-command="target remote localhost:3333" --debugger $(GDB) $(TARGET).elf

gdb: $(TARGET).elf
	$(GDB) -ex "target ext localhost:3333" -ex "mon reset halt" -ex "mon arm semihosting enable" $(TARGET).elf

.PHONY: clean st-flash debug flash ddd gdb nimcache
