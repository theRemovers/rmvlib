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

	.include	"../jaguar.inc"
	.include	"screen_def.s"

	.68000
	.text
	
	.globl	_put_pixel
;;; void put_pixel(screen *scr, int x, int y, int color)
_put_pixel:
	move.l	4(sp),a0
	move.w	12+2(sp),d0	; Y
	blt.s	.skip
	cmp.w	SCREEN_H(a0),d0
	bge.s	.skip
	swap	d0
	move.w	8+2(sp),d0	; X
	blt.s	.skip
	cmp.w	SCREEN_W(a0),d0
	bge.s	.skip
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	SCREEN_FLAGS(a0),A2_FLAGS
	move.l	d0,A2_PIXEL
	move.l	#(1<<16)|1,B_COUNT
	move.l	16(sp),d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#DSTA2|PATDSEL,B_CMD
	wait_blitter	d0
.skip:
	rts
