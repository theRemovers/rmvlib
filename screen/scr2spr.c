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

sprite *sprite_of_screen(int x, int y, screen *scr) {
  sprite *s;
  s = malloc(sizeof(sprite));
  s->h.previous = NULL;
  s->h.next = NULL;

  s->y = y;
  s->x = x;

  s->hy = 0;
  s->hx = 0;

  s->remainder = 1<<4;
  s->vscale = 1<<5;
  s->hscale = 1<<5;

  s->data = scr->data;

  s->animation = NULL;
  
  s->scaled = 0;
  s->animated = 0;
  s->invisible = 0;
  s->use_hotspot = 0;
  s->firstpix = 0;
  s->release = 0;
  s->trans = 1;
  s->rmw = 0;
  s->reflect = 0;

  if(scr->clut != NULL) {
    s->index = scr->clut_index;
  } else {
    s->index = 0;
  }

  s->iwidth = scr->iwidth;
  s->dwidth = scr->dwidth;
  switch(scr->pitch) {
  case 0:
    s->pitch = 1;
    break;
  case 1:
    s->pitch = 2;
    break;
  case 2:
    s->pitch = 4;
    break;
  case 3:
    s->pitch = 3;
    break;
  }
  s->depth = scr->depth;
  s->height = scr->height;

  s->animation_data.counter = 1;
  s->animation_data.index = 0;
  s->animation_data.has_looped = 0;

  return s;
}
