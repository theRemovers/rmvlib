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

/** \file fb2d.h
 * \brief 2D Frame Buffer operations
 */
#ifndef _FB2D_H
#define _FB2D_H

#include <jagdefs.h>
#include <screen.h>

#ifdef __cplusplus
extern "C" {
#endif

/** A linear transform is defined by four coefficients, thus defining a 2x2 matrix */
typedef struct {
  /** 0,0 */
  fixp a;
  /** 1,0 */
  fixp b;
  /** 0,1 */
  fixp c;
  /** 1,1 */
  fixp d;
} linear_transform;

/** An affine transform is a linear transform plus a translation */
typedef struct {
  /** Defined as an union to ease cast of ::affine_transform in ::linear_transform */
  union {
    /** Linear transform part */
    linear_transform m;
    /** Or directly the coefficients */
    struct {
      /** 0,0 */
      fixp a;
      /** 1,0 */
      fixp b;
      /** 0,1 */
      fixp c;
      /** 1,1 */
      fixp d;
      /** X translation */
      fixp e;
      /** Y translation */
      fixp f;
    };
  };
} affine_transform;

/** Initialise the DSP 2D Frame Buffer manager. 
 *
 * The given address must be an address in DSP ram where to load the
 * DSP routine.
 *
 * It returns the address of the end of the Frame Buffer manager in
 * DSP ram (which is long aligned).
 */
void *init_fb2d_manager(/** Address where to load the DSP routine. It
			 * should be long aligned. */
			void *addr);

/** Composition of two ::linear_transform.
 * The result of the composition is written back in the second ::linear_transform.
 */
void fb2d_compose_linear_transform(/** Address of the first
				    * ::linear_transform. It should be
				    * long aligned. */
				   linear_transform *src,
				   /** Address of the second
				    * ::linear_transform. It should be
				    * long aligned. */
				   linear_transform *dst);

/** Set the given ::linear_transform to a rotation.
    The rotation angle is modulo 2048. This gives a precision of 360/2048 degree.
 */
void fb2d_set_rotation(/** Address of ::linear_transform. It should be
			* long aligned. */
		       linear_transform *dst,
		       /** Angle */
		       int angle);

/** Compute the translation part of the given ::affine_transform so that
 * the two points given coincides before and after transformation.
 */
void fb2d_set_matching_points(/** Address of ::affine_transform. It
			       * should be long aligned. */
			      affine_transform *t, 
			      /** X coordinate before transformation */
			      int x1, 
			      /** Y coordinate before transformation */
			      int y1, 
			      /** X coordinate after transformation */
			      int x2, 
			      /** Y coordinate after transformation */
			      int y2);

/** Compute the bounding box after transformation. */
void fb2d_compute_bounding_box(/** Address of ::linear_transform. It
				* should be long aligned. */
			       linear_transform *m, 
			       /** Width of bounding box before transformation */
			       int w1, 
			       /** Height of bounding box before transformation */
			       int h1, 
			       /** Width of bounding box after transformation (written back) */
			       int *w2, 
			       /** Height of bounding box after transformation (written back) */
			       int *h2);

#define fb2d_copy_straight screen_copy_straight

/** Copy a transformed box of the source ::screen in the target ::screen 
 *
 * You can specify from and where it copies with fields screen::x and screen::y.
 *
 * The width and height are to be understood in the target
 * screen. Thus, it may be convenient to compute the good values with
 * help of function ::compute_bounding_box_2d.
 */
void fb2d_copy_transformed(/** Source ::screen */
			   screen *src, 
			   /** Target ::screen */
			   screen *dst, 
			   /** Address of ::affine_transform. It should
			    * be long aligned */
			   affine_transform *t, 
			   /** Width of box */
			   int w, 
			   /** Height of box */
			   int h, 
			   /** Mode of copy */
			   mode m,
			   /** Depends on mode */
			   ...);

#ifdef __cplusplus
}
#endif

#endif
