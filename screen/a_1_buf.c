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

phrase *alloc_simple_screen(depth d,int width,int height,screen *scr) {
  int iwidth = get_iwidth(d,width);
  int dwidth = iwidth;
  phrase *data = malloc(8 * dwidth * height);
  scr->iwidth = iwidth;
  scr->dwidth = dwidth;
  scr->data = data;
  scr->width = width;
  scr->height = height;
  scr->depth = d;
  scr->z_offset = 0;
  scr->pitch = 0;
  scr->x = 0;
  scr->y = 0;
  set_exponent_mantissa(width,scr);
  return data;
}
