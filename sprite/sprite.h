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

/** \file sprite.h 
 * \brief Display manager
 */

#ifndef _SPRITE_H
#define _SPRITE_H

#include <stddef.h>
#include <jagdefs.h>
#include <op.h>
#include <display.h>

/** An animation chunck is used to describe one part of an animation.
 */
typedef struct {
  /** Address of the graphical data. 
   * It must be phrase aligned in memory.
   * If NULL then it is the end of the animation. 
   */
  phrase *data;
  /** Number of VBLs the image is displayed */
  short int speed;
  short int reserved1;
} animation_chunk;

/** 
 * The sprite data structure.
 */
typedef struct {
  sprite_header h;

  /**
   * Characteristics of the sprite.
   */
  struct {
    /* word 1 */
    /** If set, the sprite is scaled according to sprite::hscale and
     * sprite::vscale. */
    unsigned long long scaled : 1;
    /** If set, the sprite use animation described by
     * sprite::animation. */
    unsigned long long animated : 1;
    /** If set, the sprite is invisible. */
    unsigned long long invisible : 1;
    /** If set, the sprite uses a hot spot different of left-upper
     * corner. */
    unsigned long long use_hotspot : 1;
    unsigned long long reserved1 : 5;
    /** First pixel to be displayed for low resolution graphics. */
    unsigned long long firstpix : 6;
    /** Release the bus when displaying the sprite. */
    unsigned long long release : 1;
    /* word 2 */
    /** If set, then use transparency mode. */
    unsigned long long trans : 1;
    /** Use RMW mode when drawing. */
    unsigned long long rmw : 1;
    /** If set, the sprite is horizontally flipped. */
    unsigned long long reflect : 1;
    /** Index in the CLUT for less than 8 bit depth data. */
    unsigned long long index : 7;
    /* word 2 - word 3 */
    /** Image width in phrases. */
    unsigned long long iwidth : 10;
    /* word 3 */
    /** Data width in phrases. */
    unsigned long long dwidth : 10;
    /* word 3 - word 4 */
    /** */
    unsigned long long pitch : 3;
    /* word 4 */
    /** Depth of the graphical data. */
    unsigned long long depth : 3;
    unsigned long long reserved2 : 2;
    /** Height of the sprite (unscaled). */
    unsigned long long height : 10;
  };

  /** X coordinate of the sprite. */
  short int y;
  /** Y coordinate of the sprite. */
  short int x;

  /** X coordinate of the hot spot. */
  short int hy;
  /** Y coordinate of the hot spot. */
  short int hx;

  char reserved4;
  /** Remainder as a 3.5 number. */
  char remainder;
  /** Vertical scale as a 3.5 number. */
  char vscale;
  /** Horizontal scale as a 3.5 number. */
  char hscale;

  /** Address of the graphical data: this must be aligned to a phrase
   * boundary in memory. */
  phrase *data;

  /** Address of an array of ::animation_chunk that describes the animation.
   *
   * The last ::animation_chunk should have it animation_chunk::data
   * field set to NULL
   */
  animation_chunk *animation;

  /** Animation global characteritics */
  struct {
    /** Countdown until the next ::animation_chunk is fetched */
    short int counter;
    struct {
      /** If set, the animation has just looped */
      unsigned short int has_looped : 1;
      /** Index if the current ::animation_chunk */
      unsigned short int index : 15;
    };
  } animation_data;
} sprite;

/** Create a new sprite which is not scaled, not animated, visible and
 * transparent. */
sprite *new_sprite(/** Width in pixels so that the width in bytes is a multiple of 8 */
		   int width, 
		   /** Height in pixels */
		   int height, 
		   /** X coordinate */
		   int x, 
		   /** Y coordinate */ 
		   int y, 
		   /** Depth of the graphical data */
		   depth d, 
		   /** Address of the graphical data: it should be phrase aligned */
		   phrase *data);

/** Initialisation of a sprite. 
 *
 * This can be useful if you want to extend the "class" ::sprite.  It
 * initialises the sprite as function ::new_sprite.
 */
void set_sprite(/** Address of the sprite */
		sprite *s, 
		/** Width in pixels so that the width in bytes is a multiple of 8 */
		int width, 
		/** Height in pixels */
		int height, 
		/** X coordinate */
		int x,
		/** Y coordinate */
		int y, 
		/** Depth of the graphical data */
		depth d, 
		/** Address of the graphical data: it should be phrase aligned */
		phrase *data);

/** Add a ::sprite to a ::display at given layer. */
void attach_sprite_to_display_at_layer(/** Address of the ::sprite */
				       sprite *s, 
				       /** Address of the ::display */
				       display *d, 
				       /** Layer where to add the ::sprite (modulo 16) */
				       int layer);

/** Remove a ::sprite from its ::display. */
void detach_sprite_from_display(/** Address of the ::sprite */
				sprite *s);

/** Change the layer of a ::sprite in a ::display. */
void change_sprite_layer(/** Address of the ::sprite */
			 sprite *s, 
			 /** Address of the ::display */
			 display *d, 
			 /** Layer where to move the ::sprite (modulo 16) */
			 int layer);

/** Sort the given layer of the given display according to
 * the given compare function.
 *
 * The compare function returns a negative (or null) integer if the
 * first ::sprite is "lesser than or equal to" the second ::sprite.
 *
 * The given layer is sorted increasingly. This means that the "least"
 * sprite is displayed first in the layer and the "greatest" one is
 * displayed last.
 *
 * The sorting algorithm uses O(1) space and O(n log(n)) comparisons
 * (merge sort). It is a stable sort.
 *
 * Since the sort is made by the 68k while the GPU possibly reads the
 * display, it is safer to make a call to ::wait_display_refresh
 * before sorting a layer of the current active display.
 */
void sort_display_layer(/** Address of the ::display */
			display *d,
			/** Layer (modulo 16) */
			int layer,
			/** Comparison function */
			int (*compare)(sprite *s1, sprite *s2));

/** Iterate the given function on every ::sprite of the given
 * layer. */
void display_iter_layer(/** Address of the ::display */
			display *d,
			/** Layer (modulo 16) */
			int layer,
			/** Function to iterate */
			void (*f)(sprite *s));

/** Iterate the given function on every ::sprite of the display from
 * layer 0 to layer 15. */
void display_iter_all_layers(/** Address of the ::display */
			     display *d,
			     /** Function to iterate */
			     void (*f)(sprite *s));

/** Move the corresponding layer */
void move_display_layer(/** Address of the ::display */
			display *d,
			/** Layer (modulo 16) */
			int layer,
			/** X coordinates */
			int x,
			/** Y coordinates */
			int y);

/** Hide the corresponding layer */
void hide_display_layer(/** Address of the ::display */
			display *d,
			/** Layer (modulo 16) */
			int layer);

/** Show the corresponding layer */
void show_display_layer(/** Address of the ::display */
			display *d,
			/** Layer (modulo 16) */
			int layer);
#endif

/** \page sprite Sprite Management

    \code
    sprite *new_sprite(int width, int height, int x, int y, depth d, phrase *data);
    void set_sprite(sprite *s, int width, int height, int x, int y, depth d, phrase *data);
    \endcode

    Create (resp. initialise) a sprite with given characteristics.

    By default, the sprite uses transparency (black pixels), is
    visible, still (i.e.  not animated), and at ratio 1:1 (i.e. not scaled).

    \code
    void attach_sprite_to_display_at_layer(sprite *s, display *d, int layer);
    \endcode

    Attach a sprite to a display at given layer. A sprite may be
    attached to at most one display at a time.

    \code
    void detach_sprite_from_display(sprite *s);
    \endcode

    Detach a sprite from its current display.

    \code
    void change_sprite_layer(sprite *s, display *d, int layer);
    \endcode

    Detach a sprite from its current display and attach it to a
    (possibly different) display at given layer.

    \code
    void display_iter_layer(display *d, int layer, void (*f)(sprite *s));
    void display_iter_all_layers(display *d, void (*f)(sprite *s));
    \endcode

    Iterate a function over the sprites of a given layer (resp. every
    layer) in the given display.

    \code
    void sort_display_layer(display *d, int layer, int (*compare)(sprite *s1, sprite *s2));
    \endcode

    Sort the sprites of a given layer in the given display, according
    to the given comparison function.

    This allows to modify the order in which sprites are drawn onto
    screen. The lowest sprite is drawn first while the greatest is
    drawn last.

    Since the modification of the display structure may happen while
    the GPU refresh routine operates, it is recommended to wait for
    the end of the refresh (thanks to ::wait_display_refresh) before
    calling this function.
 */
