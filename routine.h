/* The Removers'Library */
/* Copyright (C) 2008 Seb/The Removers */
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

/** \file routine.h
 * \brief GPU/DSP Routine defines
 */
#ifndef _ROUTINE_H
#define _ROUTINE_H

#include <jagtypes.h>

typedef struct routine {
  int kind;
  phrase *addr;
  unsigned long size;
  int param_offset;
  int nb_subroutines;
  int subroutine_offset[];
} routine;

#define GPU_ROUTINE (1<<0)
#define DSP_ROUTINE (1<<1)

#endif
