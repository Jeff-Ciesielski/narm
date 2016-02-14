/*****************************************************************/
/* Copyright (C) 2015 Jeff Ciesielski <jeffciesielski@gmail.com> */
/*                                                               */
/* usart: Interrupt driven usart driver for STM32F0              */
/*                                                               */
/* This software may be modified and distributed under the terms */
/* of the MIT license.  See the LICENSE file for details.        */
/*****************************************************************/

#ifndef _DEBUG_USART_H_
#define _DEBUG_USART_H_

#include <stdbool.h>
#include <stdint.h>

#define UART_BUFFER_SIZE 256

#define USART_1 0
#define USART_2 1

/* TODO: Move these into a common driver includes folder */
int usart_init(int usart_no, uint32_t baud);
int usart_enable_autocrlf(int usart_no, bool enable);
int usart_write(int usart_no, char *s, int len);
int usart_read(int usart_no, char *d, int len, int timeout);
int usart_putchar(int usart_no, char c);
int usart_getchar(int usart_no, char *c, int timeout);
#endif /* _DEBUG_USART_H_ */
