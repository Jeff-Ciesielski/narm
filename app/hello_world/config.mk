# The name of our project (and the associated artifacts created)
TARGET = hello_world

# Set our linker script
LINK_MEM = linker.ld
APP_START_ADDRESS = 0x08000000

#Uncomment to use narmos
NARMOS = 1

# Uncomment the following to enable STM32 Peripheral libraries
STM32F0XX_LIBS = 1

#Uncomment the following line to enable stm32 USB libraries
#STM32_USB_LIBS = 1

#Uncomment one of the following to build in support for USB Device/Host
#STM32_USB_DEV = 1
#STM32_USB_HOST = 1

#Uncomment the following to include any USB device classes you might want
#STM32_USB_DEV_CDC = 1

APP_C_FILES += $(sort $(wildcard $(APP_PATH)/*.c))
APP_C_FILES += $(sort $(wildcard $(APP_PATH)/nimcache/*.c))

APP_INCLUDES += -Iutil

#Uncomment the following to enable ESP8266 WIFI support
#ESP8266 = 1

#Uncomment the following to enable MQTT client support
#MQTTE=1

#Uncomment the following to use the ITM (trace macrocell) for printf
#ITM = 1
#APP_DEFINES += -DUSE_ITM

# UNcomment the following to enable AS1117 Driver
AS1117=1

# Uncomment to enable 7 Segment display driver
7_SEG_DISPLAY=1

#HEAP selection
FREERTOS_HEAP=heap_1

APP_DEFINES += -DUSART1_ENABLE -DUSART2_ENABLE -DUSE_I2C2 -DUSE_I2C1
