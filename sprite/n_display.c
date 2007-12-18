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
#include <stdlib.h>
#include <memalign.h>

void build_display_list_header(display *d,display_list_header *h, qphrase *list) {
  h->ob1.type = BRANCHOBJ;
  h->ob1.ypos = a_vde;
  h->ob1.cc = O_BRLT;
  h->ob1.link = (unsigned long)(&(h->ob7)) >> 3;
  //
  h->ob2.type = BRANCHOBJ;
  h->ob2.ypos = a_vdb;
  h->ob2.cc = O_BRGT;
  h->ob2.link = (unsigned long)(&(h->ob7)) >> 3;
  //
  h->ob3.type = BRANCHOBJ;
  h->ob3.ypos = (a_vdb + 1) & 0xfffe;
  h->ob3.cc = O_BREQ;
  h->ob3.link = (unsigned long)(&(h->ob5)) >> 3;
  //
  h->ob4.type = BRANCHOBJ;
  h->ob4.ypos = 0x7ff;
  h->ob4.cc = O_BREQ;
  h->ob4.link = (unsigned long)list >> 3;
  //
#if DISPLAY_USE_OP_IT
  h->ob5.data1 = (unsigned long)d;;
  h->ob5.type = GPUOBJ;
#else
  h->ob5.type = BRANCHOBJ;
  h->ob5.ypos = 0x7ff;
  h->ob5.cc = O_BREQ;
  h->ob5.link = (unsigned long)(&(h->ob4)) >> 3;
#endif
  //
  h->ob6.type = BRANCHOBJ;
  h->ob6.ypos = 0x7ff;
  h->ob6.cc = O_BREQ;
  h->ob6.link = (unsigned long)(&(h->ob4)) >> 3;
  //
  h->ob7.type = STOPOBJ;
  h->ob7.int_flag = 0;
  //
  op_stop_object *stop;
  stop = (void *)list;
  stop->type = STOPOBJ;
  stop->int_flag = 0;
}

mblock *new_display(unsigned int max_nb_sprites) {
  display *d;
  if(max_nb_sprites == 0) {
    max_nb_sprites = DISPLAY_DFLT_MAX_SPRITE;
  }
  max_nb_sprites++; // for stop object
#if !DISPLAY_SWAP_METHOD
    max_nb_sprites += (sizeof(display_list_header)+sizeof(qphrase)-1) / sizeof(qphrase);
#endif
  mblock *result = memalign(sizeof(qphrase),sizeof(display)+2*max_nb_sprites*sizeof(qphrase));
  d = (display *)result->addr;
  //  d = malloc(sizeof(display)+2*max_nb_sprites*sizeof(qphrase));
  d->phys = d->op_list;
  d->log = d->op_list + max_nb_sprites;
  d->x = 0;
  d->y = 0;
  int i;
  for(i = 0; i < 1<<DISPLAY_NB_LAYER; i++) {
    d->layer[i].y = 0;
    d->layer[i].x = 0;
    d->layer[i].attribute.visible = 1;
    d->layer[i].attribute.reserved = 0;
    d->layer[i].sprites.previous = NULL;
    d->layer[i].sprites.next = NULL;
  }
#if DISPLAY_SWAP_METHOD
  build_display_list_header(d,&d->h,d->phys);
  op_stop_object *stop;
  stop = (void *)d->log;
  stop->type = STOPOBJ;
  stop->int_flag = 0;
#else
  build_display_list_header(d,(void *)d->phys,d->phys + (sizeof(display_list_header)+sizeof(qphrase)-1) / sizeof(qphrase));
  build_display_list_header(d,(void *)d->log,d->log + (sizeof(display_list_header)+sizeof(qphrase)-1) / sizeof(qphrase));
#endif
  return result;
}
