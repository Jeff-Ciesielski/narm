/*****************************************************************/
/* Copyright (C) 2015 Jeff Ciesielski <jeffciesielski@gmail.com> */
/*                                                               */
/* Interrupt driven SPI Master driver for STM32F0                */
/*                                                               */
/* This software may be modified and distributed under the terms */
/* of the MIT license.  See the LICENSE file for details.        */
/*****************************************************************/

#include <spi_master.h>
#include <stm32f0xx_gpio.h>
#include <stm32f0xx_rcc.h>
#include <stm32f0xx_misc.h>
#include <stm32f0xx_spi.h>

#include <stdint.h>
#include <stdbool.h>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))

struct rcc_params {
	void (*clock_cmd)(uint32_t, FunctionalState);
	uint32_t periph;
};

struct spi_pin {
	uint16_t pin_mask;
	uint8_t pin_source;
	GPIO_TypeDef *port;
	uint8_t pin_af;
	struct rcc_params rcc;
};

struct spi_priv {
        enum spi_bus bus;
        SPI_TypeDef *ll_dev;
        bool initialized;
        xQueueHandle transact_q;
        xSemaphoreHandle transact_lock;
        xSemaphoreHandle event_lock;
        uint8_t *buf;
        uint8_t len;
        uint8_t total;
	struct {
		struct spi_pin miso;
		struct spi_pin mosi;
		struct spi_pin sck;
	} pins;
	struct rcc_params rcc;
	uint8_t irqn;
	bool error_flag;
};

static struct spi_priv priv_drivers[] = {
#ifdef USE_SPI1
	{
		.initialized = false,
                .bus = SPI_1,
		.ll_dev = SPI1,
#ifndef REMAP_SPI1_PORTB
		.pins = {
			.miso = {
				.pin_mask = GPIO_Pin_6,
				.pin_source = GPIO_PinSource6,
				.port = GPIOA,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOA,
				},
			},
			.mosi = {
				.pin_mask = GPIO_Pin_7,
				.pin_source = GPIO_PinSource7,
				.port = GPIOA,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOA,
				},
			},
			.sck = {
				.pin_mask = GPIO_Pin_5,
				.pin_source = GPIO_PinSource5,
				.port = GPIOA,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOA,
				},
			},
		},
#else
		.pins = {
			.sck = {
				.pin_mask = GPIO_Pin_3,
				.pin_source = GPIO_PinSource3,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
			.miso = {
				.pin_mask = GPIO_Pin_4,
				.pin_source = GPIO_PinSource4,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
			.mosi = {
				.pin_mask = GPIO_Pin_5,
				.pin_source = GPIO_PinSource5,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
		},
#endif
		.rcc = {
			.clock_cmd = RCC_APB2PeriphClockCmd,
			.periph = RCC_APB2Periph_SPI1,
		},
		.irqn = SPI1_IRQn,
		.len = 0,
		.error_flag = false,
	},
#endif	/* USE_SPI1 */
#ifdef USE_SPI2
	{
		.initialized = false,
                .bus = SPI_2,
		.ll_dev = SPI2,
		.pins = {
			.miso = {
				.pin_mask = GPIO_Pin_14,
				.pin_source = GPIO_PinSource14,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
			.mosi = {
				.pin_mask = GPIO_Pin_15,
				.pin_source = GPIO_PinSource15,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
			.sck = {
				.pin_mask = GPIO_Pin_13,
				.pin_source = GPIO_PinSource13,
				.port = GPIOB,
				.pin_af = GPIO_AF_0,
				.rcc = {
					.clock_cmd = RCC_AHBPeriphClockCmd,
					.periph = RCC_AHBPeriph_GPIOB,
				},
			},
		},
		.rcc = {
			.clock_cmd = RCC_APB2PeriphClockCmd,
			.periph = RCC_APB2Periph_SPI2,
		},
		.irqn = SPI2_IRQn,
		.len = 0,
		.error_flag = false,
	}
#endif	/* USE_SPI2 */
};

static struct spi_priv *spi_get_dev(enum spi_bus bus)
{
        for (int i = 0; i < ARRAY_SIZE(priv_drivers); i++) {
                if (priv_drivers[i].bus == bus) {
                        return &priv_drivers[i];
                }
        }
        return NULL;
}

static uint16_t spi_calc_prescaler(uint32_t target_baud)
{
	RCC_ClocksTypeDef clocks;
	uint32_t div;

	RCC_GetClocksFreq(&clocks);

	div = clocks.PCLK_Frequency / target_baud;

	if (div <= 2) {
		return SPI_BaudRatePrescaler_2;
	} else if (div > 2 && div <= 4) {
		return SPI_BaudRatePrescaler_4;
	} else if (div > 4 && div <=8) {
		return SPI_BaudRatePrescaler_8;
	} else if (div > 8 && div <= 16) {
		return SPI_BaudRatePrescaler_16;
	} else if (div > 16 && div <= 32) {
		return SPI_BaudRatePrescaler_32;
	} else if (div > 32 && div <= 64) {		
		return SPI_BaudRatePrescaler_64;
	} else if (div > 64 && div <= 128) {
		return SPI_BaudRatePrescaler_128;
	} 

	/* Else... */
	return SPI_BaudRatePrescaler_256;
}

int spi_init(enum spi_bus bus, enum spi_mode mode,
	     enum spi_bit_order bit_order, uint32_t baud)
{

        GPIO_InitTypeDef GPIO_InitStruct;

        struct spi_priv *p = spi_get_dev(bus);

	if (p == NULL)
		return -1;

        /* initialize the gpio clocks */
	p->pins.sck.rcc.clock_cmd(p->pins.sck.rcc.periph, ENABLE);
	p->pins.miso.rcc.clock_cmd(p->pins.miso.rcc.periph, ENABLE);
	p->pins.mosi.rcc.clock_cmd(p->pins.mosi.rcc.periph, ENABLE);

        /* Init GPIO Pins */
        GPIO_InitStruct.GPIO_Mode = GPIO_Mode_AF;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_InitStruct.GPIO_OType = GPIO_OType_PP;
	GPIO_InitStruct.GPIO_PuPd = GPIO_PuPd_NOPULL;

        GPIO_InitStruct.GPIO_Pin = p->pins.sck.pin_mask;
	GPIO_Init(p->pins.sck.port, &GPIO_InitStruct);
        
        GPIO_InitStruct.GPIO_Pin = p->pins.miso.pin_mask;
	GPIO_Init(p->pins.miso.port, &GPIO_InitStruct);
        
        GPIO_InitStruct.GPIO_Pin = p->pins.mosi.pin_mask;
	GPIO_Init(p->pins.mosi.port, &GPIO_InitStruct);

        GPIO_PinAFConfig(p->pins.sck.port,
			 p->pins.sck.pin_source,
			 p->pins.sck.pin_af);
	GPIO_PinAFConfig(p->pins.miso.port,
			 p->pins.miso.pin_source,
			 p->pins.miso.pin_af);
	GPIO_PinAFConfig(p->pins.mosi.port,
			 p->pins.mosi.pin_source,
			 p->pins.mosi.pin_af);

        /* Initialize locks */
        vSemaphoreCreateBinary(p->transact_lock);
	vSemaphoreCreateBinary(p->event_lock);
	xSemaphoreTake(p->event_lock, portMAX_DELAY);

        SPI_InitTypeDef spi_init_struct;

        SPI_StructInit(&spi_init_struct);

        p->rcc.clock_cmd(p->rcc.periph, ENABLE);

	spi_init_struct.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	spi_init_struct.SPI_Mode = SPI_Mode_Master;
	spi_init_struct.SPI_DataSize = SPI_DataSize_8b;

	switch (mode) {
	case SPI_MODE_0:
		spi_init_struct.SPI_CPOL = SPI_CPOL_Low;
		spi_init_struct.SPI_CPHA = SPI_CPHA_1Edge;
		break;
	case SPI_MODE_1:
		spi_init_struct.SPI_CPOL = SPI_CPOL_Low;
		spi_init_struct.SPI_CPHA = SPI_CPHA_2Edge;
		break;
	case SPI_MODE_2:
		spi_init_struct.SPI_CPOL = SPI_CPOL_High;
		spi_init_struct.SPI_CPHA = SPI_CPHA_1Edge;
		break;
	case SPI_MODE_3:
		spi_init_struct.SPI_CPOL = SPI_CPOL_High;
		spi_init_struct.SPI_CPHA = SPI_CPHA_2Edge;
		break;
	default:
		return -1;
	}

	spi_init_struct.SPI_NSS = SPI_NSS_Soft;

	switch (bit_order) {
	case SPI_MSB_FIRST:
		spi_init_struct.SPI_FirstBit = SPI_FirstBit_MSB;
		break;
	case SPI_LSB_FIRST:
		spi_init_struct.SPI_FirstBit = SPI_FirstBit_LSB;
		break;
	default:
		return -2;
	}

	spi_init_struct.SPI_BaudRatePrescaler = spi_calc_prescaler(baud);

        NVIC_InitTypeDef nvic_init;

	nvic_init.NVIC_IRQChannel = p->irqn;
	nvic_init.NVIC_IRQChannelPriority = 5;
	nvic_init.NVIC_IRQChannelCmd = ENABLE;

	NVIC_Init(&nvic_init);

	SPI_Init(p->ll_dev, &spi_init_struct);
	SPI_RxFIFOThresholdConfig(p->ll_dev, SPI_RxFIFOThreshold_QF);
        SPI_Cmd(p->ll_dev, ENABLE);
        return 0;
}

int spi_read(enum spi_bus bus, uint32_t len, uint8_t *dst)
{
    int ret = 0;
    struct spi_priv *p = spi_get_dev(bus);

    xSemaphoreTake(p->transact_lock, portMAX_DELAY);

    p->buf = dst;
    p->len = len;
    p->total = 0;

    SPI_I2S_ITConfig(p->ll_dev, SPI_I2S_IT_RXNE, ENABLE);

    SPI_SendData8(p->ll_dev, 0x00);

    if (xSemaphoreTake(p->event_lock, 1000) == pdFALSE) {
            ret = -2;
            goto unlock_and_return;
    }

    while (SPI_I2S_GetFlagStatus(p->ll_dev, SPI_I2S_FLAG_BSY) == SET);

unlock_and_return:
    xSemaphoreGive(p->transact_lock);

    return ret;
}

int spi_write(enum spi_bus bus, uint32_t len, uint8_t *src)
{
        int ret = 0;
        struct spi_priv *p = spi_get_dev(bus);

	xSemaphoreTake(p->transact_lock, portMAX_DELAY);

        p->buf = src;
        p->len = len;
	p->total = 0;

        SPI_I2S_ITConfig(p->ll_dev, SPI_I2S_IT_TXE, ENABLE);

        if (xSemaphoreTake(p->event_lock, 1000) == pdFALSE) {
		ret = -2;
		goto unlock_and_return;
        }

	while (SPI_I2S_GetFlagStatus(p->ll_dev, SPI_I2S_FLAG_BSY) == SET);

unlock_and_return:
	xSemaphoreGive(p->transact_lock);
    
        /* Return */
        return ret;
}

void spi_common_irq_handler(struct spi_priv *p)
{
        portBASE_TYPE task_woken = pdFALSE;

        if (SPI_I2S_GetITStatus(p->ll_dev,  SPI_I2S_IT_TXE)) {
                if (p->total < p->len) {
                        SPI_SendData8(p->ll_dev, *(p->buf++));
                        p->total++;
                } else {
                        SPI_I2S_ITConfig(p->ll_dev, SPI_I2S_IT_TXE, DISABLE);
                        xSemaphoreGiveFromISR(p->event_lock, &task_woken);
                }
        }

        if (SPI_I2S_GetITStatus(p->ll_dev,  SPI_I2S_IT_RXNE)) {
		p->total++;
		*(p->buf++) = SPI_ReceiveData8(p->ll_dev);
                if (p->total < p->len) {
                        SPI_SendData8(p->ll_dev, 0x00);
                } else {
                        SPI_I2S_ITConfig(p->ll_dev, SPI_I2S_IT_RXNE, DISABLE);
                        xSemaphoreGiveFromISR(p->event_lock, &task_woken);
                }
        }
        portEND_SWITCHING_ISR(task_woken);
}

#ifdef USE_SPI1

void SPI1_IRQHandler(void)
{
        struct spi_priv *p = spi_get_dev(SPI_1);
        spi_common_irq_handler(p);
}
#endif

#ifdef USE_SPI2
void SPI2_IRQHandler(void)
{
        struct spi_priv *p = spi_get_dev(SPI_2);
        spi_common_irq_handler(p);
}
#endif
