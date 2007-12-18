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

static inline void set_exponent_mantissa(int width,screen *scr) {
  int nb = 31;
  while(!(width & 0x80000000)) {
    width <<= 1;
    nb--;
  }
  width <<= 1;
  scr->exponent = nb;
  scr->mantissa = (width >> 30);
}

static inline int get_iwidth(depth d,int width) {
  switch(d) {
  case DEPTH1:
    width /= 8;
    break;
  case DEPTH2:
    width /= 4;
    break;
  case DEPTH4:
    width /= 2;
    break;
  case DEPTH8:
    break;
  case DEPTH16:
    width *= 2;
    break;
  case DEPTH32:
    width *= 4;
    break;
  }
  return (width/8);
}
