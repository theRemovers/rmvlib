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

	include	"../jaguar.inc"
	include	"screen_def.s"

	.text
	.68000
	
;;; void clear_zbuffered_screen(screen *dst)
	.globl	_clear_zbuffered_screen
_clear_zbuffered_screen:
	move.l	4+0(sp),a0
	move.l	#0,B_PATD
	move.l	#0,B_PATD+4
	move.l	#0,B_DSTZ
	move.l	#0,B_DSTZ+4
	move.l	#0,B_Z0
	move.l	#0,B_Z1
	move.l	#0,B_Z2
	move.l	#0,B_Z3
	move.l	#0,B_ZINC
	move.l	SCREEN_FLAGS(a0),A2_FLAGS
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	SCREEN_H(a0),d0	; screen size w*h (H | W)
	move.l	#0,A2_PIXEL
	move.l	d0,B_COUNT
	swap	d0
	move.w	#1,d0
	swap	d0
	neg.w	d0
	move.l	d0,A2_STEP	; y++, x -= w
	move.l	#PATDSEL|DSTA2|UPDA2|DSTWRZ|ZBUFF,B_CMD
	wait_blitter	d0
	rts

