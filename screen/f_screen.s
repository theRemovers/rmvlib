; The Removers'Library
; Copyright (C) 2006 Seb/The Removers
; http://removers.atari.org/

; This library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.

; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.

; You should have received a copy of the GNU Lesser General Public
; License along with this library; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

	include	"jaguar.inc"
	include	"screen_def.inc"

	.text
	.68000

;;; void fill_screen(screen *dst, int color)
	.globl	_fill_screen
_fill_screen:
	move.l	4+0(sp),a0
	move.l	#0,A1_CLIP
	move.l	4+4(sp),d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	SCREEN_FLAGS(a0),d0
	move.w	d0,d1
	lsr.w	#3,d1
	and.w	#%111,d1
	cmp.w	#3,d1
	bhs.s	.depth_ge_8
.depth_lt_8:
	or.l	#XADDPIX,d0
	move.l	#DSTEN|PATDSEL|UPDA1,d1
	bra.s	.depth_ok
.depth_ge_8:
	or.l	#XADDPHR,d0
	move.l	#PATDSEL|UPDA1,d1
.depth_ok:
	move.l	d0,A1_FLAGS
	move.l	SCREEN_DATA(a0),A1_BASE
	move.l	SCREEN_H(a0),d0	; screen size w*h (H | W)
	move.l	#0,A1_PIXEL
	move.l	d0,B_COUNT
	swap	d0
	move.w	#1,d0
	swap	d0
	neg.w	d0
	move.l	d0,A1_STEP	; y++, x -= w
	move.l	d1,B_CMD
	wait_blitter	d0
	rts
