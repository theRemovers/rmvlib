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

/** \file blit.h
 * \brief Functions that uses the blitter to set or move buffers.
 */
#ifndef _BLIT_H
#define _BLIT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/** Set the n bytes of the buffer starting at dst with character c. */
void *blitset(/** Buffer address */
	      void *dst, 
	      /** Byte to be used to fill the buffer */
	      int c, 
	      /** Number of bytes to set */
	      size_t n);

/** Move a number of bytes from src buffer to dst buffer. 
 * The two buffers may overlap in memory.
 */
void *blitmove(/** Address of the source buffer */
	       void *src, 
	       /** Address of the target buffer */
	       void *dst, 
	       /** Number of bytes to move */
	       size_t n);

#ifdef __cplusplus
}
#endif

#endif
