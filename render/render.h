/* The Removers'Library */
/* Copyright (C) 2006-2008 Seb/The Removers */
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

/** \file render.h
 * \brief Software renderer
 */
#ifndef _RENDER_H
#define _RENDER_H

#include <jagdefs.h>
#include <screen.h>

typedef struct {
  fixp y;
  fixp x;
  fixp i;
  fixp z;
  fixp u;
  fixp v;
} vertex;

typedef struct polygon {
  /* Next polygon or NULL */
  struct polygon *next;
  /* Rendering flags */
  short int flags;
  /* Number of vertices */
  short int size;
  /* Rendering parameter. Color or pure intensity. */
  unsigned long param;
  /* Texture address if TXTMAPPING */
  screen *texture;
  /* Vertices are given in clockwise order (on screen) */
  vertex vertices[];
} polygon;

/** Initialise the Software Renderer.
 *
 * The given address must be an address in GPU ram where to load the
 * GPU routine.
 *
 * It returns the address of the end of the renderer routine in GPU
 * ram (which is long aligned).
 */
void *init_renderer(/** Address where to load the GPU routine. It
		     * should be long aligned. */
		    void *addr);

/** Asynchronous rendering. Of course the blitter is not available for
    other tasks since it is drawing polygons. */
void render_polygon_list_and_wait(screen *target,
				  polygon *p,
				  int clear_flags);

/** Synchronous rendering. */
void render_polygon_list(screen *target,
			 polygon *p,
			 int clear_flags);

/** Wait completion of the renderer. */
void wait_renderer_completion();

/** Any combination of these will work. */
#define FLTSHADING 0x0
#define GRDSHADING 0x1
#define ZBUFFERING 0x2
#define TXTMAPPING 0x4

/** Clear flags can be one of these */
#define NO_CLR_SCREEN 0x0
#define CLR_SCREEN 0x1
#define CLR_Z_SCREEN 0x2

#endif
