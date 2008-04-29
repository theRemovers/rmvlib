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
  fixp x;
  fixp y;
} vertex;

typedef struct {
  int size;
  unsigned long reserved[2];
  vertices vertex[]
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

void render_polygon(screen *target,
		    polygon *p);

#endif
