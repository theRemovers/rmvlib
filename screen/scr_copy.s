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
	
	.globl	_screen_copy_straight
;;; void fb2d_copy_straight(screen *src, screen *dst, int w, int h, int mode, ...);
_screen_copy_straight:
	movem.l	d2-d4,-(sp)
	move.w	3*4+16+2(sp),d0	; h
	ble	.done
	swap	d0
	move.w	3*4+12+2(sp),d0	; w
	ble	.done
	movem.l	3*4+4(sp),a0-a1	; src/dst
	move.l	SCREEN_Y(a0),d1	; y1|x1
	move.l	SCREEN_Y(a1),d2	; y2|x2
	move.l	SCREEN_H(a0),d3	; h1|w1
	move.l	SCREEN_H(a1),d4	; h2|w2
	;; fix x coordinates
	tst.w	d1
	bge.s	.x1_pos		; x1 >= 0 ?
	add.w	d1,d0		; w -= |x1|
	sub.w	d1,d2		; x2 += |x1|
	clr.w	d1
.x1_pos:
	tst.w	d2
	bge.s	.x2_pos		; x2 >= 0 ?
	add.w	d2,d0		; w -= |x2|
	sub.w	d2,d1		; x1 += |x2|
	clr.w	d2
.x2_pos:
	sub.w	d1,d3		; max width (screen1) is w1 - x1
	ble	.done
	sub.w	d2,d4		; max width (screen2) is w2 - x2
	ble	.done
	cmp.w	d0,d3
	bge.s	.w1_clipped
	move.w	d3,d0
.w1_clipped:
	cmp.w	d0,d4
	bge.s	.w2_clipped
	move.w	d4,d0
.w2_clipped:
	;; fix y coordinates
	swap	d0
	swap	d1
	swap	d2
	swap	d3
	swap	d4
	tst.w	d1
	bge.s	.y1_pos		; y1 >= 0 ?
	add.w	d1,d0		; h -= |y1|
	sub.w	d1,d2		; y2 += |y1|
	clr.w	d1
.y1_pos:
	tst.w	d2
	bge.s	.y2_pos		; y2 >= 0 ?
	add.w	d2,d0		; h -= |y2|
	sub.w	d2,d1		; y1 += |y2|
	clr.w	d2
.y2_pos:
	sub.w	d1,d3		; max height (screen1) is h1 - y1
	ble	.done
	sub.w	d2,d4		; max height (screen2) is h2 - y2
	ble	.done
	cmp.w	d0,d3
	bge.s	.h1_clipped
	move.w	d3,d0
.h1_clipped:
	cmp.w	d0,d4
	bge.s	.h2_clipped
	move.w	d4,d0
.h2_clipped:
	move.l	d0,d3
	swap	d0		; h|w
	swap	d1		; y1|x1
	swap	d2		; y2|x2
	move.w	#1,d3
	swap	d3
	neg.w	d3		; 1|-w
	;; source screen
	move.l	SCREEN_FLAGS(a0),d4
	or.l	#XADDPIX,d4
	move.l	d4,A1_FLAGS
	move.l	#0,A1_CLIP	; no clipping (bug work around)
	move.l	SCREEN_DATA(a0),A1_BASE
	move.l	d1,A1_PIXEL
	move.l	d3,A1_STEP
	;; dest screen
	move.l	SCREEN_DATA(a1),A2_BASE
	move.l	d2,A2_PIXEL
	move.l	d3,A2_STEP
	;;
	move.l	d0,B_COUNT
	;; A2_FLAGS (destination)
	move.l	SCREEN_FLAGS(a1),d4
	or.l	#XADDPIX,d4
	move.l	d4,A2_FLAGS
	;; d4 is A2_FLAGS
	move.l	#UPDA1|UPDA2|DSTA2,d3
	or.l	3*4+20(sp),d3
	;; if DEPTH < 2^3 then DSTEN unless BKGWREN
;; 	btst.l	#28,d3		; bkgwren ?
;; 	bne.s	.depth_ge_8
	lsr.w	#3,d4
	and.w	#%111,d4
	cmp.w	#3,d4
	bhs.s	.depth_ge_8
	or.l	#DSTEN,d3
.depth_ge_8:	
	btst.l	#27,d3		; data comparator?
	beq.s	.no_dcompen
	move.l	#0,B_PATD
	move.l	#0,B_PATD+4
.no_dcompen:
	btst.l	#26,d3		; bit comparator?
	beq.s	.no_bcompen
	move.l	3*4+24(sp),d0	; color when bit on
	move.l	d0,B_PATD	;
	move.l	d0,B_PATD+4
	moveq	#0,d0
	btst.l	#28,d3		; BKGWREN
	beq.s	.transparent
	move.l	3*4+28(sp),d0	  ; color when bit off
.transparent:
	move.l	d0,B_DSTD
	move.l	d0,B_DSTD+4
.no_bcompen:
	move.l	d3,B_CMD
	movem.l	(sp)+,d2-d4
	wait_blitter	d0
	rts
.done:	
	movem.l	(sp)+,d2-d4
	rts
