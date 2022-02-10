; The Removers'Library 
; Copyright (C) 2006-2008 Seb/The Removers
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

	.include	"jaguar.inc"
	.include	"screen_def.inc"

	.68000
	.text

	.globl	_hline
;;; void hline(screen *scr, int xmin, int y, int xmax, int color)
_hline:
	move.w	12+2(sp),d0	; Y
	blt	.skip
	move.l	4(sp),a0	; scr
	cmp.w	SCREEN_H(a0),d0
	bge	.skip
	swap	d0
	move.w	8+2(sp),d0	; Xmin
	bge.s	.clip_xmin
	clr.w	d0
.clip_xmin:
	moveq	#1,d1
	swap	d1
	move.w	16+2(sp),d1	; Xmax
	addq.w	#1,d1
	cmp.w	SCREEN_W(a0),d1
	blt.s	.clip_xmax
	move.w	SCREEN_W(a0),d1
.clip_xmax:
	sub.w	d0,d1		; W
	ble.s	.skip
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	d0,A2_PIXEL
	move.l	d1,B_COUNT
	move.l	20(sp),d0
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
	move.l	#DSTA2|DSTEN|PATDSEL,d1
	bra.s	.depth_ok
.depth_ge_8:
	or.l	#XADDPHR,d0
	move.l	#DSTA2|PATDSEL,d1
.depth_ok:
	move.l	d0,A2_FLAGS
	move.l	d1,B_CMD
	wait_blitter	d0
.skip:
	rts

