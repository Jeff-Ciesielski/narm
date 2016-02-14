/*****************************************************************/
/* Copyright (C) 2015 Jeff Ciesielski <jeffciesielski@gmail.com> */
/*                                                               */
/* Interrupt driven SPI Master driver for STM32F0                */
/*                                                               */
/* This software may be modified and distributed under the terms */
/* of the MIT license.  See the LICENSE file for details.        */
/*****************************************************************/

#ifndef _SPI_MASTER_H_
#define _SPI_MASTER_H_

enum spi_bus {
	SPI_1,
	SPI_2,
};

enum spi_mode {
	SPI_MODE_0,
	SPI_MODE_1,
	SPI_MODE_2,
	SPI_MODE_3,
};

enum spi_bit_order {
	SPI_MSB_FIRST,
	SPI_LSB_FIRST,
};

int spi_init(enum spi_bus bus, enum spi_mode mode,
	     enum spi_bit_order bit_order, uint32_t baud);
int spi_read(enum spi_bus bus, uint32_t len, uint8_t *dst);
int spi_write(enum spi_bus bus, uint32_t len, uint8_t *src);

#endif	/* _SPI_MASTER_H_ */
