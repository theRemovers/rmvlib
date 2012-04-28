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
#include "sprite.h"

sprite *new_sprite(int width, int height, int x, int y, depth d, phrase *data) {
  sprite *s;
  s = malloc(sizeof(sprite));
  //  bzero(s,sizeof(sprite));
  s->h.previous = NULL;
  s->h.next = NULL;

  s->y = y;
  s->x = x;

  s->hy = 0;
  s->hx = 0;

  s->remainder = 1<<4;
  s->vscale = 1<<5;
  s->hscale = 1<<5;

  s->data = data;

  s->animation = NULL;

  switch(d) {
  case DEPTH1:
    // 1 bpp
    width = width/8;
    break;
  case DEPTH2:
    // 2 bpp
    width = width/4;
    break;
  case DEPTH4:
    // 4 bpp
    width = width/2;
    break;
  case DEPTH8:
    // 8 bpp
    break;
  case DEPTH16:
    // 16 bpp
    width = 2*width;
    break;
  case DEPTH32:
    // 32 bpp
    width = 4*width;
    break;
  }
  width = width/8;

  s->scaled = 0;
  s->animated = 0;
  s->invisible = 0;
  s->use_hotspot = 0;
  s->firstpix = 0;
  s->release = 0;
  s->trans = 1;
  s->rmw = 0;
  s->reflect = 0;
  s->index = 0;
  s->iwidth = width;
  s->dwidth = width;
  s->pitch = 1; /* O_NOGAP */
  s->depth = d;
  s->height = height;

  s->animation_data.counter = 1;
  s->animation_data.index = 0;
  s->animation_data.has_looped = 0;

  return s;
}
