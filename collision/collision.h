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

/** \file collision.h
 * \brief Pixel precise collision routine.
 */
#ifndef _COLLISION_H
#define _COLLISION_H

#include <sprite.h>
#include <routine.h>

#define COLLISION_DONE 0x80000000
/** The two sprites collide.
 */
#define COLLISION_COLLIDE 0x8000
/** The bounding boxes of the two sprites intersect.
 */
#define COLLISION_INTERSECT 0x80
/** The first ::sprite is above the second one. */
#define COLLISION_Y1_LE_Y2 0x1
/** The first ::sprite is on the left of the second one. */
#define COLLISION_X1_LE_X2 0x2

/** Initialise the GPU collision routine.  
 *
 * The given address must be an address in GPU ram where to load the
 * GPU routine.
 *
 * It returns the address of the end of the collision routine in GPU
 * ram (which is long aligned).
 */
void *init_collision_routine(/** Address where to load the GPU
			      * routine. It should be long aligned. */
			     void *addr);

/** Run the collision test between the two given sprites.  
 *
 * The collision routine works only with 16 bit sprites that are not
 * scaled and not reflected.
 *
 * The result of the test can be read with ::get_collision_result.
 */
void launch_collision_test(/** Address of the first sprite. It should
			    * be long aligned. */
			   sprite *s1, 
			   /** Address of the second sprite sprite. It
			    * should be long aligned. */
			   sprite *s2);

/** Checks whether the collision test launched with
 * ::launch_collision_test has finished.
 */
long is_collision_done();

/** Returns the result of the collision test.
 *
 * If COLLISION_INTERSECT then the two bounding boxes intersect. In
 * this case, it returns the coordinates of the intersection box.
 *
 * If COLLISION_Y1_LE_Y2 then y is relative to first sprite, otherwise
 * relative to the second sprite.
 *
 * If COLLISION_X1_LE_X2 then xis relative to first sprite, otherwise
 * relative to the second sprite.
 */
long get_collision_result(/** Y coordinate of the intersection box */
			  short int *y, 
			  /** Height of the intersection box */
			  short int *h, 
			  /** X coordinate of the intersection box */
			  short int *x, 
			  /** Width of the intersection box */
			  short int *w);

extern routine collision_routine_info;

#endif
