/* The Removers'Library */
/* Copyright (C) 2006-2011 Seb/The Removers */
/* http://removers.atari.org/ */

/* This library is free software; you can redistribute it and/or */
/* modify it under the terms of the GNU Lesser General Public */
/* License as published by the Free Software Foundation; either */
/* version 2.1 of the License, or (at your option) any later version. */

/* This library is distributed in the hope that it will be useful, */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU */
/* Lesser General Public License for more details. */

/* You should have received a copy of the GNU Lesser General Public */
/* License along with this library; if not, write to the Free Software */
/* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA */

/** \file uart.h
 * \brief UART driver
 */

#ifndef _UART_H
#define _UART_H

#include <stdio.h>

enum uart_baudrate_t { B9600, B19200, B38400, B57600, B115200 };
enum uart_parity_t { PNONE, PODD, PEVEN };

void uart_setup(enum uart_baudrate_t bd, enum uart_parity_t p);
int uart_getc();
int uart_putc();
void uart_flush();
int uart_try_getc(unsigned int timeout, int *c);


#endif
