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

/** \file op.h 
 * \brief OP related definitions
 */
#ifndef _OP_H
#define _OP_H

#include "jagtypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#define BITOBJ 0
#define SCBITOBJ 1
#define GPUOBJ 2
#define BRANCHOBJ 3
#define STOPOBJ 4

#define O_BREQ 0
#define O_BRGT 1
#define O_BRLT 2
#define O_BROP 3
#define O_BRHALF 4

typedef struct {
  unsigned long long data1 : 32;
  unsigned long long data2 : 28;
  unsigned long long int_flag : 1;
  unsigned long long type : 3;
} op_stop_object;

typedef struct {
  unsigned long long data1 : 32;
  unsigned long long data2 : 29;
  unsigned long long type : 3;
} op_gpu_object;

typedef struct {
  unsigned long long reserved0 : 21;
  unsigned long long link : 19;
  unsigned long long reserved1 : 7;
  unsigned long long cc : 3;
  unsigned long long ypos : 11;
  unsigned long long type : 3;
} op_branch_object;

typedef struct {
  struct {
    unsigned long long data : 21;
    unsigned long long link : 19;
    unsigned long long height : 10;
    unsigned long long ypos : 11;
    unsigned long long type : 3;
  };
  struct {
    unsigned long long reserved : 9;
    unsigned long long firstpix : 6;
    unsigned long long release : 1;
    unsigned long long trans : 1;
    unsigned long long rmw : 1;
    unsigned long long reflect : 1;
    unsigned long long index : 7;
    unsigned long long iwidth : 10;
    unsigned long long dwidth : 10;
    unsigned long long pitch : 3;
    unsigned long long depth : 3;
    unsigned long long xpos : 12;
  };
} op_bitmap_object;

typedef struct {
  struct {
    unsigned long long data : 21;
    unsigned long long link : 19;
    unsigned long long height : 10;
    unsigned long long ypos : 11;
    unsigned long long type : 3;
  };
  struct {
    unsigned long long reserved : 9;
    unsigned long long firstpix : 6;
    unsigned long long release : 1;
    unsigned long long trans : 1;
    unsigned long long rmw : 1;
    unsigned long long reflect : 1;
    unsigned long long index : 7;
    unsigned long long iwidth : 10;
    unsigned long long dwidth : 10;
    unsigned long long pitch : 3;
    unsigned long long depth : 3;
    unsigned long long xpos : 12;
  };
  struct {
    unsigned long long reserved1 : 40;
    unsigned long long remainder : 8;
    unsigned long long vscale : 8;
    unsigned long long hscale : 8;
  };
} op_scaled_bitmap_object;

typedef unsigned long long op_object;

/** Depth of graphical data. */
typedef enum { 
  /** 1 bpp */
  DEPTH1 = 0, 
  /** 2 bpp */
  DEPTH2 = 1, 
  /** 4 bpp */
  DEPTH4 = 2, 
  /** 8 bpp */
  DEPTH8 = 3, 
  /** 16 bpp */
  DEPTH16 = 4, 
  /** 24 bpp */
  DEPTH32 = 5 } depth;

#ifdef __cplusplus
}
#endif

#endif
