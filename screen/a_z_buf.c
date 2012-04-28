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

#include <stdlib.h>
#include "screen.h"

#include "screen_inline.c"

phrase *alloc_z_double_buffered_screens(depth d,int width,int height,screen *scr1, screen *scr2) {
  int iwidth = get_iwidth(d,width);
  int dwidth = 3 * iwidth;
  phrase *data = malloc(8 * dwidth * height);
  scr1->iwidth = iwidth;
  scr1->dwidth = dwidth;
  scr1->data = data;
  scr1->width = width;
  scr1->height = height;
  scr1->depth = d;
  scr1->z_offset = 2;
  scr1->pitch = 3;
  scr1->x = 0;
  scr1->y = 0;
  set_exponent_mantissa(width,scr1);
  scr2->exponent = scr1->exponent;
  scr2->mantissa = scr1->mantissa;
  scr2->iwidth = iwidth;
  scr2->dwidth = dwidth;
  scr2->data = data+1;
  scr2->width = width;
  scr2->height = height;
  scr2->depth = d;
  scr2->z_offset = 1;
  scr2->pitch = 3;
  scr2->x = 0;
  scr2->y = 0;
  return data;
}
