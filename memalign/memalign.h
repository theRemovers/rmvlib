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

/** \file memalign.h 
  \brief Auxiliary function to allocate aligned blocks of memory.
*/

#ifndef _MEMALIGN_H
#define _MEMALIGN_H

#include <stdlib.h>

/** 
 * A mblock is a convenient way to allocate memory aligned buffer.
*/
typedef struct {
  /** address of the aligned buffer */
  void *addr;
} mblock;

/** 
 * Allocate a block of memory with the malloc function and returns a mblock.
 *
 * The mblock::addr field of the ::mblock returned is the address of a buffer 
 * aligned to a multiple of boundary.
 *
 * The length of the aligned buffer is size.
 *
 * To deallocate a mblock and the corresponding buffer, you must use the free function on the ::mblock.
 */
mblock *memalign(/** power of two that specifies the alignment of the buffer */ 
		 size_t boundary, 
		 /** size of the allocated buffer */ 
		 size_t size);

#endif
