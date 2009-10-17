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

/** Default maximal number of sprites in ::display. */
#define DISPLAY_DFLT_MAX_SPRITE 256

#define DISPLAY_LOG_NB_STRIPS 3
#define DISPLAY_NB_STRIPS (1 << DISPLAY_LOG_NB_STRIPS)

#ifndef DISPLAY_USE_OP_IT
#define DISPLAY_USE_OP_IT 1
#endif

/** The number of layers is 1<<DISPLAY_NB_LAYER */
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

/* typedef struct { */
/*   op_branch_object ob1; */
/*   op_branch_object ob2; */
/*   op_branch_object ob3; */
/*   op_branch_object ob4; */
/*   op_stop_object ob5; */
/*   op_branch_object ob6; */
/*   op_branch_object ob7; */
/*   op_branch_object ob8; */
/*   op_branch_object ob9; */
/*   op_branch_object ob10; */
/*   op_branch_object ob11; */
/*   op_branch_object ob12; */
/*   op_stop_object ob13; */
/*   char _pad0[sizeof(qphrase)-((11*sizeof(op_branch_object) + 2*sizeof(op_stop_object)) % sizeof(qphrase))]; */
/* } display_strip_tree; */

#define DISPLAY_STRIP_TREE_SIZEOF (sizeof(dphrase)*(((sizeof(phrase)*(3*(1<<(DISPLAY_LOG_NB_STRIPS-1))+2))+sizeof(dphrase)-1)/sizeof(dphrase)))

typedef struct {
  int y;
  int offset;
} strip;

/** The display type */
typedef struct {
  qphrase *phys;
  qphrase *log;
  // phrase
  /** Y coordinate of display */
  short int y;
  /** X coordinate of display */
  short int x;
  char _pad0[8-((4+4+2+2) % 8)]; // 4
  // dphrase
  display_list_header h;
  // phrase
  /** strips */
  strip strips[DISPLAY_NB_STRIPS+1];

  //  sprite_header layer[1<<DISPLAY_NB_LAYER];
  layer_desc layer[1<<DISPLAY_NB_LAYER];

  char _pad1[sizeof(qphrase)-((4+4+2+2+4+sizeof(display_list_header)+sizeof(sprite_header)*(1<<DISPLAY_NB_LAYER)+(DISPLAY_NB_STRIPS+1)*sizeof(strip)) % sizeof(qphrase))];
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

/** Creates a new ::display that can contain at most max_nb_sprites
 * ::sprite.
 */
display *new_display(/** maximal number of sprites the ::display can contain. 
		     * If 0 then the default value of ::DISPLAY_DFLT_MAX_SPRITE is used. 
		     */
		    unsigned int max_nb_sprites);
#endif

/** \page display Display driver

    The display driver offer a convenient way to manipulate Jaguar
    (hardware) sprites. It also includes a simple GPU routines
    manager.

    A display is simply a sprite container. It is organized in layers,
    in order to control the order in which the sprites are drawn onto
    %screen.

    Each layer has its own coordinates inside a display and has an
    independent visibility flag.
    
    \section display_api API 

    \code
    void init_display_driver();
    \endcode

    Initialise the display driver (load GPU interrupt routine,
    ...). 

    This must be called prior any other display-related operations.

    \code
    display *new_display(unsigned int max_sprites);
    \endcode

    Create (allocate & initialise) a new display that could contain at
    most the given number of sprites.

    \code
    void show_display(display *d);
    void hide_display(display *d);
    \endcode

    Show/hide the given display. At most one display can be active at
    any time.

    \code
    void wait_display_refresh();
    \endcode
    
    Wait for the display to be refreshed on %screen.

    \code
    void move_display_layer(display *d, int layer, int x, int y);
    \endcode

    Change the layer coordinates in a display.

    \code
    void hide_display_layer(display *d, int layer);
    void show_display_layer(display *d,	int layer);
    \endcode

    Make invisible (resp. visible) a given layer in a display.

    \code
    void jump_gpu_subroutine(void *address);
    \endcode

    Execute a GPU subroutine located at given address (which should be
    located in GPU ram space).

    \section display_example Example
    
    Here is the minimal code to create a display and make it the active one.

    \subsection display_c_example C example

    \code
#include <display.h>

int main(int argc, char *argv[]) {
  // initialise the display driver
  init_display_driver();

  // create a new display that could contain at most DISPLAY_DFLT_MAX_SPRITE
  display *d = new_display(0);

  // make it active
  show_display(d);

  // infinite loop
  for(;;) {
  }
}
    \endcode

    \subsection display_asm_example ASM example

    \code
    .extern _init_display_driver
    .extern _new_display
    .extern _show_display

    .globl _main

    .text
    .m68000
_main:
    jsr _init_display_driver ;; initialise display driver

    move.l #0,-(sp)
    jsr    _new_display    ;; create display
    addq.l #4,sp

    move.l d0,display_addr ;; save display address

    move.l d0,-(sp)
    jsr _show_display      ;; show display
    addq.l #4,sp

.loop:
    bra.s .loop

    .bss
display_addr: ds.l 1
    \endcode

 */
