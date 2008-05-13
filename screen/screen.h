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

#define RGBCLUT 0
#define CRYCLUT 1;

/** The type of fixpoint 16.16 integers */
typedef long fixp;

/** Screen characteristics */
typedef struct {
  struct {
    unsigned long reserved0: 17;
    unsigned long exponent: 4;
    unsigned long mantissa: 2;
    unsigned long z_offset: 3;
    unsigned long depth: 3;
    unsigned long reserved1: 1;
    unsigned long pitch: 2;
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

/** Allocate a new ::screen with malloc. */
screen *new_screen();

/** Initialise a ::screen.*/
void set_simple_screen(/** Depth of the graphical data. */
		       depth d,
		       /** Width in pixels of the graphical data. This must be a valid blitter width. */ 
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
			    /** Width in pixels of the graphical data. This must be a valid blitter width. */ 
			    int width,
			    /** Height in pixels of the graphical data. */
			    int height,
			    /** Address of the ::screen. */
			    screen *scr);

/** Allocate a screen buffer for double buffering. Set the two screens accordingly.
 * It returns the address of the buffer allocated. */
phrase *alloc_double_buffered_screens(/** Depth of the graphical data. */
				   depth d,
				   /** Width in pixels of the graphical data. This must be a valid blitter width. */ 
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
				     /** Width in pixels of the graphical data. This must be a valid blitter width. */ 
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

/** Clear the given Z-buffered screen (fill with color 0 and Z = 0). 
    Will only work on 16bpp screens.
 */
void clear_zbuffered_screen(/** Address of the ::screen */ 
			    screen *dst);

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

#endif
