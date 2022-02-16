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

/** \file lz77.h
 * \brief LZ77 Depacker (to be used with Ray/TSCC packer)
 */
#ifndef _LZ77_H
#define _LZ77_H

#include <routine.h>
#include <gpudriver.h>

#ifdef __cplusplus
extern "C" {
#endif

extern const routine lz77_routine;

/** Initialise the LZ77 Depacker.
 *
 * The given address must be an address in GPU ram where to load the
 * GPU routine.
 *
 * It returns the address of the end of the renderer routine in GPU
 * ram (which is long aligned).
 */
static inline void *lz77_init(void *addr) {
  return init_gpu_routine((routine *)&lz77_routine, addr);
}

/** Unpack LZ77 compressed data. */
static inline void lz77_unpack(void *addr, uint8_t *in, uint8_t *out) {
  call_gpu_routine((routine *)&lz77_routine, addr, in, out);
}

static inline void lz77_unpack_async(void *addr, uint8_t *in, uint8_t *out) {
  async_call_gpu_routine((routine *)&lz77_routine, addr, in, out);
}

static inline void lz77_unpack_wait(void *addr) {
  wait_gpu_routine((routine *)&lz77_routine, addr);
}

#ifdef __cplusplus
}
#endif

#endif
