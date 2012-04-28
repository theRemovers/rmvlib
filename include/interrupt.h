/* The Removers'Library */
/* Copyright (C) 2006 Seb/The Removers */
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

/** \file interrupt.h
 * \brief Interrupts management.
 */
#ifndef _INTERRUPT_H
#define _INTERRUPT_H

#define stop68k() { asm("stop #0x2100"); }
/** Size of the VBL queue */
#define VBL_QUEUE_SIZE 8

/** Initialise interrupts. */
void init_interrupts();

/** Wait for the next VBL. */
void vsync();

/** Type of an interrupt handler. */
typedef void (*irq_handler)(void);

/** Array of interrupt handlers to be executed each VBL. */
extern irq_handler vblQueue[VBL_QUEUE_SIZE];

/** VBL counter. */
extern unsigned short int volatile vblCounter;

/** Set timer interrupt */
void set_timer(long count, irq_handler handler);

/** Clear timer interrupt */
void clear_timer();

#endif
