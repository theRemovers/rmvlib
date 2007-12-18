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

/** \file console.h
 * \brief an on-screen console
 */

#ifndef _CONSOLE_H
#define _CONSOLE_H

#include <stdio.h>
#include <sprite.h>

/** Open a new console attached to the given display, at given
    coordinates. It is implemented as a 1 bpp screen buffer: you can
    specify the index in the CLUT.
 */
FILE *open_console(/** display */ display *d, 
		   /** X coordinate */ int x, 
		   /** Y coordinate */ int y, 
		   /** index in CLUT */ int idx);

/** Open a new console attached to the given display, at given
    coordinates. 
 */
FILE *open_custom_console(/** display */ display *d, 
			  /** X coordinate */ int x, 
			  /** Y coordinate */ int y, 
			  /** index in CLUT */ int idx, 
			  /** number of columns */ int width, 
			  /** number of lines */ int height, 
			  /** layer */ int layer);

#endif
