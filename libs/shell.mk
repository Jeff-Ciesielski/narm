# Command shell configuration file
#
# Jeff Ciesielski <jeff.ciesielski@gmail.com>

ifneq ($(COMMAND_SHELL),)

SHELL_SOURCE ?= $(LIB_PATH)/shell

LIB_C_FILES += $(SHELL_SOURCE)/shell.c

# Shell includes
LIB_INCLUDES += -I$(SHELL_SOURCE)

endif
