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

#include <memalign.h>

mblock *memalign(size_t boundary, size_t size) {
  size_t real_size = size + 2 * boundary + sizeof(mblock);
  mblock *result = malloc(real_size);
  long addr = (long)result;
  addr += sizeof(mblock);
  addr += boundary - 1;
  addr &= ~(boundary - 1);
  result->addr = (void *)addr;
  return result;
}
