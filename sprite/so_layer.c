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

#include <sprite.h>

static inline sprite_header *mergesort(sprite_header *list, int (*compare)(sprite *s1, sprite *s2)) {
  if(list == NULL) {
    return list;
  }
  int insize, nmerges, psize, qsize, i;
  sprite_header *p, *q, *e, *tail;
  insize = 1;
  for(;;) {
    p = list;
    list = NULL;
    tail = NULL;
    nmerges = 0;
    while(p != NULL) {
      nmerges++;
      q = p;
      psize = 0;
      for(i = 0; i < insize; i++) {
	psize++;
	q = q->next;
	if(q == NULL) break;
      }
      qsize = insize;
      while(psize > 0 || ((qsize > 0) && (q != NULL))) {
	if(psize == 0) {
	  e = q;
	  q = q->next;
	  qsize--;
	} else if ((qsize == 0) || (q == NULL)) {
	  e = p;
	  p = p->next;
	  psize--;
	} else if (compare((sprite *)p,(sprite *)q) <= 0) {
	  e = p;
	  p = p->next;
	  psize--;
	} else {
	  e = q;
	  q = q->next;
	  qsize--;
	}
	if(tail != NULL) {
	  e->next = NULL; /* to avoid cycles */
	  tail->next = e;
	} else {
	  list = e;
	}
	e->previous = tail;
	tail = e;
      }
      p = q;
    }
    //    tail->next = NULL;
    if(nmerges <= 1) {
      return list;
    }
    insize *= 2;
  }
}

void sort_display_layer(display *d, int layer, int (*compare)(sprite *s1, sprite *s2)) {
  layer = layer & ((1 << DISPLAY_NB_LAYER) - 1);
  sprite_header *list = d->layer[layer].sprites.next;
  if(list != NULL) {
    list->previous = NULL;
    sprite_header *sorted = mergesort(list,compare);
    d->layer[layer].sprites.next = sorted;
    sorted->previous = &(d->layer[layer].sprites);
  }
}
