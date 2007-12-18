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

/** \file joypad.h 
 * \brief Joypad management
 */
#ifndef _JOYPAD_H
#define _JOYPAD_H

// Standard Controller
/** Up */
#define JOYPAD_UP (1<<0)
/** Down */
#define JOYPAD_DOWN (1<<1)
/** Left */
#define	JOYPAD_LEFT (1<<2)
/** Right */
#define JOYPAD_RIGHT (1<<3)
/** * */
#define JOYPAD_STAR (1<<4)
/** 7 */
#define JOYPAD_7 (1<<5)
/** 4 */
#define JOYPAD_4 (1<<6)
/** 1 */
#define JOYPAD_1 (1<<7)
/** 0 */
#define JOYPAD_0 (1<<8)
/** 8 */
#define JOYPAD_8 (1<<9)
/** 5 */
#define JOYPAD_5 (1<<10)
/** 2 */
#define JOYPAD_2 (1<<11)
/** # */
#define JOYPAD_SHARP (1<<12)
/** 9 */
#define JOYPAD_9 (1<<13)
/** 6 */
#define JOYPAD_6 (1<<14)
/** 3 */
#define JOYPAD_3 (1<<15)
/** Pause */
#define JOYPAD_PAUSE (1<<16)
/** A */
#define JOYPAD_A (1<<17)
#define JOYPAD_D (1<<18)
/** B */
#define JOYPAD_B (1<<19)
#define JOYPAD_E (1<<20)
/** C */
#define JOYPAD_C (1<<21)
#define JOYPAD_F (1<<22)
/** Option */
#define JOYPAD_OPTION (1<<23)

// Pro Controller
/** L */
#define JOYPAD_L JOYPAD_4
/** R */
#define JOYPAD_R JOYPAD_6
/** X */
#define JOYPAD_X JOYPAD_9
/** Y */
#define JOYPAD_Y JOYPAD_8
/** Z */
#define JOYPAD_Z JOYPAD_7

/** Joypad states */
typedef struct {
  /** Joypad 1 */
  unsigned long j1;
  /** Joypad 3 */
  unsigned long j3;
  /** Joypad 4 */
  unsigned long j4;
  /** Joypad 5 */
  unsigned long j5;
  /** Joypad 2 */
  unsigned long j2;
  /** Joypad 6 */
  unsigned long j6;
  /** Joypad 7 */
  unsigned long j7;
  /** Joypad 8 */
  unsigned long j8;
} joypad_state;

/** Read the joypad states. */
void read_joypad_state(/** Address of a ::joypad_state structure where
			* to write the joypad states
			*/
		       joypad_state *state);

#endif
