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

/** \file display.h
 * \brief Display manager.
 */
#ifndef _DISPLAY_H
#define _DISPLAY_H

#ifndef DISPLAY_USE_LEGACY_ANIMATION
#define DISPLAY_USE_LEGACY_ANIMATION 0
#endif

#ifndef DISPLAY_SWAP_METHOD
#define DISPLAY_SWAP_METHOD 1
#endif

#ifndef DISPLAY_USE_OP_IT
#define DISPLAY_USE_OP_IT 1
#endif

#define DISPLAY_NB_LAYER 4

#include <op.h>

#define RGBCOLOR(r,g,b) (((((r) >> 3) & 0x1f) << 11) | ((((b) >> 3) & 0x1f) << 6) | (((g) >> 2) & 0x3f))
#define CRYCOLOR(c,r,y) ((((c) & 0xf) << 12) | (((r) & 0xf) << 8) | ((y) & 0xff))

#define SET_BG_RGB(r,g,b) { SET_SHORT_INT(RGBCOLOR(r,g,b),BG); }
#define SET_BG_CRY(c,r,y) { SET_SHORT_INT(CRYCOLOR(c,r,y),BG); }
#define SET_CLUT_RGB(idx,r,g,b) { SET_SHORT_INT(RGBCOLOR(r,g,b),CLUT+2*((idx) & 0xff)); }
#define SET_CLUT_CRY(idx,c,r,y) { SET_SHORT_INT(CRYCOLOR(c,r,y),CLUT+2*((idx) & 0xff)); }
#define SET_BG(c) { SET_SHORT_INT(c,BG); }
#define SET_CLUT(idx,c) { SET_SHORT_INT(c,CLUT+2*((idx) & 0xff)); }

typedef struct _sprite_header {
  struct _sprite_header *previous;
  struct _sprite_header *next;
} sprite_header;

typedef struct {
  struct {
    unsigned long reserved : 31;
    unsigned long visible : 1;
  } attribute;
  short int y;
  short int x;
  sprite_header sprites;
} layer_desc;

typedef struct {
  op_branch_object ob1;
  op_branch_object ob2;
  op_branch_object ob3;
  op_branch_object ob4;
#if DISPLAY_USE_OP_IT
  op_gpu_object ob5;
#else
  op_branch_object ob5;
#endif
  op_branch_object ob6;
  op_stop_object ob7;
} display_list_header;

/** The display type */
typedef struct {
  qphrase *phys;
  qphrase *log;
  // phrase
  /** Y coordinate of display */
  short int y;
  /** X coordinate of display */
  short int x;
#if DISPLAY_SWAP_METHOD
  char _pad0[8-((4+4+2+2) % 8)];
  // dphrase
  display_list_header h;
  // phrase
#else
  // long
#endif

  //  sprite_header layer[1<<DISPLAY_NB_LAYER];
  layer_desc layer[1<<DISPLAY_NB_LAYER];

#if DISPLAY_SWAP_METHOD
  char _pad1[sizeof(qphrase)-((4+4+2+2+4+7*sizeof(op_object)+sizeof(sprite_header)*(1<<DISPLAY_NB_LAYER)) % sizeof(qphrase))];
#else
  char _pad1[sizeof(qphrase)-((4+4+2+2+sizeof(sprite_header)*(1<<DISPLAY_NB_LAYER)) % sizeof(qphrase))];
#endif
  qphrase op_list[];
} display;

/** Initialises the display driver and the GPU subroutine manager. */
void init_display_driver();

/** Show the given display. */
void show_display(/** display to be displayed */
		  display *d);

/** Hide display */
void hide_display();

/** Wait for the refresh of the current display to be completed.
 * If there is no active display, this will enter a deadlock.
 *
 * This synchronisation mechanism is useful if you use functions that
 * manipulate the active display (especially ::sort_display_layer).
 *
 * For this synchronisation mechanism to really work, you should have
 * first initialised interrupts with ::init_interrupts since it uses
 * the ::vblCounter variable.
 */
void wait_display_refresh();

/** Call a GPU subroutine in GPU ram. */
void jump_gpu_subroutine(/** Address of the subroutine */
			 void *addr);

/** Free GPU ram is available at &_GPU_FREE_RAM. */
extern long _GPU_FREE_RAM;

#endif
