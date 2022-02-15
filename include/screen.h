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

/** \file screen.h
 * \brief Screen management.
 *
 * A "screen" is an additionnal structure that allows to see a part of
 * memory as a frame buffer. It has some private field that are to be
 * used for blitter programming. It also has a logical origin defined
 * by its X coordinate and Y coordinate (screen::x and screen::y) that
 * are to be used by some primitives (for example to define where the
 * left-upper corner of a block is located in the frame).
 *
 * Finally, it has also a screen::data field which is the address of
 * the graphical data viewed as a frame buffer.
 *
 * Some facilities are offered to allocate certain kind of frame
 * buffers.
 */
#ifndef _SCREEN_H
#define _SCREEN_H

#include <jagtypes.h>
#include <op.h>
#include <sprite.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RGBCLUT 0
#define CRYCLUT 1;

/** The type of fixpoint 16.16 integers */
typedef long fixp;

/** Screen characteristics */
typedef struct {
  union {
    struct {
      unsigned long reserved0: 17;
      unsigned long exponent: 4;
      unsigned long mantissa: 2;
      unsigned long z_offset: 3;
      unsigned long depth: 3;
      unsigned long reserved1: 1;
      unsigned long pitch: 2;
    };
    unsigned long blitflags;
  };
  unsigned short int height;
  unsigned short int width;
  /** Y coordinate of the "origin" of the screen. */
  short int y;
  /** X coordinate of the "origin" of the screen. */
  short int x;
  unsigned short int iwidth;
  unsigned short int dwidth;
  /** Address of the graphical data: it must be phrase aligned. Do not modify. */
  phrase *data;
  /** CLUT based screens */
  unsigned char clut_type;
  unsigned char clut_index;
  short int clut_size;
  short int *clut;
} screen;

/** The copy modes available */
typedef enum {
  /** All 0 */
  MODE_ZERO = 0,
  /** Not Source And Not Destination */
  MODE_NSAND = SRCEN|DSTEN|LFU_NAN,
  /** Not Source And Destination */
  MODE_NSAD = SRCEN|DSTEN|LFU_NA,
  /** Not Source */
  MODE_NOTS = SRCEN|LFU_NAN|LFU_NA,
  /** Source And Destination */
  MODE_SAND = SRCEN|DSTEN|LFU_AN,
  /** Not Destination */
  MODE_NOTD = DSTEN|LFU_NAN|LFU_AN,
  /** Not (Source Xor Destination) */
  MODE_N_SXORD = SRCEN|DSTEN|LFU_NAN|LFU_A,
  /** Not Source Or Not Destination */
  MODE_NSORND = SRCEN|DSTEN|LFU_NAN|LFU_NA|LFU_AN,
  /** Source And Destination */
  MODE_SAD = SRCEN|DSTEN|LFU_A,
  /** Source Xor Destination */
  MODE_SXORD = SRCEN|DSTEN|LFU_NA|LFU_AN,
  /** Destination */
  MODE_D = DSTEN|LFU_NA|LFU_A,
  /** Not Source Or Destination */
  MODE_NSORD = SRCEN|DSTEN|LFU_NAN|LFU_NA|LFU_A,
  /** Source */
  MODE_S = SRCEN|LFU_AN|LFU_A,
  /** Source Or Not Destination */
  MODE_SORND = SRCEN|DSTEN|LFU_NAN|LFU_AN|LFU_A,
  /** Source Or Destination */
  MODE_SORD = SRCEN|DSTEN|LFU_NA|LFU_AN|LFU_A,
  /** All 1 */
  MODE_ONE = LFU_NAN|LFU_NA|LFU_AN|LFU_A,
  /** Transparent Source */
  MODE_TRANSPARENT = SRCEN|LFU_AN|LFU_A|DCOMPEN,
  /** Transparent Bit 2 Pixel Expansion */
  MODE_EXPAND_TRANSPARENT = SRCEN|SRCENX|PATDSEL|BCOMPEN,
  /** Transparent Bit 2 Pixel Expansion */
  MODE_EXPAND = SRCEN|SRCENX|PATDSEL|BCOMPEN|BKGWREN
} mode;

/** A screen has basically four characteristics: depth, width, height
    and address of graphical data.

    The width of a screen must be one of the following value
    (a valid blitter width):

    2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80,
    96, 112, 128, 160, 192, 224, 256, 320, 384, 448, 512, 640, 768,
    896, 1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584

    Otherwise, the behaviour of the functions manipulating screens is
    unpredictable. */

/** Allocate a new ::screen with malloc. */
screen *new_screen();

/** Initialise a ::screen.*/
void set_simple_screen(/** Depth of the graphical data. */
		       depth d,
		       /** Width in pixels of the graphical data. This must be a valid blitter width (see above). */
		       int width,
		       /** Height in pixels of the graphical data. */
		       int height,
		       /** Address of the ::screen. */
		       screen *scr,
		       /** Address of the graphical data. This must be phrase aligned. */
		       phrase *data);

/** Allocate a screen buffer and set the ::screen accordingly.
 * It returns the address of the buffer allocated. */
phrase *alloc_simple_screen(/** Depth of the graphical data. */
			    depth d,
			    /** Width in pixels of the graphical data. This must be a valid blitter width (see above). */
			    int width,
			    /** Height in pixels of the graphical data. */
			    int height,
			    /** Address of the ::screen. */
			    screen *scr);

/** Allocate a screen buffer for double buffering. Set the two screens accordingly.
 * It returns the address of the buffer allocated. */
phrase *alloc_double_buffered_screens(/** Depth of the graphical data. */
				   depth d,
				   /** Width in pixels of the graphical data. This must be a valid blitter width (see above). */
				   int width,
				   /** Height in pixels of the graphical data. */
				   int height,
				   /** Address of the first ::screen. */
				   screen *scr1,
				   /** Address of the second ::screen. */
				   screen *scr2);

/** Allocate a screen buffer for double buffering with Z-buffer. Set the two screens accordingly.
 * It returns the address of the buffer allocated. */
phrase *alloc_z_double_buffered_screens(/** Depth of the graphical data. */
				     depth d,
				     /** Width in pixels of the graphical data. This must be a valid blitter width (see above). */
				     int width,
				     /** Height in pixels of the graphical data. */
				     int height,
				     /** Address of the first ::screen. */
				     screen *scr1,
				     /** Address of the second ::screen. */
				     screen *scr2);

/** Create a ::sprite corresponding to the given screen. The sprite is not transparent by default. */
sprite *sprite_of_screen(/** X coordinate of the ::sprite */
			 int x,
			 /** Y coordinate of the ::sprite */
			 int y,
			 /** Address of the ::screen */
			 screen *scr);

/** Clear the given screen (fill with color 0).  For low depth screen
 * (< 8bpp), prefer ::blitset instead. */
void clear_screen(/** Address of the ::screen */
		  screen *dst);

/** Fill the given screen with given color. */
void fill_screen(/** Address of the ::screen */
		 screen *dst,
		 /** Color */
		 int color);

/** Clear the given Z-buffered screen (fill with color 0 and Z = 0).
    Will only work on 16bpp screens.
 */
void clear_zbuffered_screen(/** Address of the ::screen */
			    screen *dst);

/** Fill the given Z-buffered screen with given color and Z.
    Will only work on 16bpp screens.
 */
void fill_zbuffered_screen(/** Address of the ::screen */
			   screen *dst,
			   /** Color */
			   int color,
			   /** Z */
			   int z);

/** Copy a box of the source ::screen in the target ::screen
 *
 * You can specify from and where it copies with fields screen::x and screen::y.
 *
 * This function does not require fb2d manager to be initialised by ::init_fb2d_manager.
 */
void screen_copy_straight(/** Source ::screen */
			  screen *src,
			  /** Target ::screen */
			  screen *dst,
			  /** Width of box */
			  int w,
			  /** Height of box */
			  int h,
			  /** Mode of copy */
			  mode m,
			  /** Depends on mode */
			  ...);

/** Write a pixel to the specified position in the screen */
void put_pixel(/** Address of the ::screen */
	       screen *dst,
	       /** X coordinate */
	       int x,
	       /** Y coordinate */
	       int y,
	       /** Color */
	       int color);

/** Type of pixel */
typedef struct {
  short int x;
  short int y;
} pixel;

/** Write a serie of pixels in the screen */
void put_pixels(/** Address of the ::screen */
	       screen *dst,
	       /** Color */
	       int color,
	       /** Number of pixels */
	       int nb,
	       /** Array of pixels */
	       pixel pixels[]);

/** Draw a horizontal line onto the screen, from point (xmin, y) to (xmax, y). */
void hline(/** Address of the ::screen */
	   screen *dst,
	   /** Xmin */
	   int xmin,
	   /** Y */
	   int y,
	   /** Xmax */
	   int xmax,
	   /** Color */
	   int color);

/** Draw a vertical line onto the screen, from point (x, ymin) to (x, ymax). */
void vline(/** Address of the ::screen */
	   screen *dst,
	   /** X */
	   int x,
	   /** Ymin */
	   int ymin,
	   /** Ymax */
	   int ymax,
	   /** Color */
	   int color);

/** Draw a line onto the screen, from point (x1, y1) to point (x2, y2).

    Even if hardware clipping is enabled, it is recommended that the
    (x1, y1) and (x2, y2) are coordinates inside the screen. */
void line(/** Address of the ::screen */
	  screen *dst,
	  /** X1 */
	  int x1,
	  /** Y1 */
	  int y1,
	  /** X2 */
	  int x2,
	  /** Y2 */
	  int y2,
	  /** Color */
	  int color);

/** Rotate a screen and put the result in target screen of the given
    angle.

    Center of rotation is (scr->x, scr->y) and is mapped in target
    screen to (tgt->x, tgt->y). */
void screen_rotate(/** Address of source screen */
		   screen *src,
		   /** Adress of target screen */
		   screen *tgt,
		   /** Angle of rotation (from 0 to 255) */
		   int alpha);

#ifdef __cplusplus
}
#endif

#endif
