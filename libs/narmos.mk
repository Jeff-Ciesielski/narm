# Command shell configuration file
#
# Jeff Ciesielski <jeff.ciesielski@gmail.com>

ifneq ($(NARMOS),)

NARMOS_SOURCE ?= $(LIB_PATH)/narmos

LIB_C_FILES += $(NARMOS_SOURCE)/gqueue.c \
	$(NARMOS_SOURCE)/picoro/picoro.c

# Shell includes
LIB_INCLUDES += -I$(NARMOS_SOURCE) -I$(NARMOS_SOURCE)/picoro

endif
