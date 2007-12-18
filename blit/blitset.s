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

.macro  wait_blitter
.wait_\~:
	move.l  B_CMD,\1
	btst    #0,\1
	beq.s   .wait_\~
.endm
	
	.globl	_blitset

	.text
	.68000
	
;;; void *blitset(void *dst, int c, size_t n);
_blitset:
	move.l	d2,-(sp)
	move.l	8+8(sp),d1	; size
	beq	.end_fill	; if size is null then do nothing
	move.l	8+4(sp),d0	; fill pattern
	move.w	d0,d2
	lsl.w	#8,d0
	move.b	d2,d0
	move.w	d0,d2
	swap	d2
	move.w	d0,d2		; 4 times the same byte
	move.l	8+0(sp),a0
	moveq	#8,d0
	sub.w	a0,d0
	and.w	#%111,d0
	beq.s	.dst_padded
;;; we first align dst address on a phrase boundary
;;; note that if dst is long aligned and size is a multiple of 4
;;; then all memory access are in long words (or phrases)
	sub.l	d0,d1
	blo.s	.slow_padding
.fast_padding:
	subq.w	#1,d0
	lsl.w	#2,d0
	move.l	.padrout(pc,d0.w),a1
	jmp	(a1)
.padrout:
	dc.l	.pad1
	dc.l	.pad2
	dc.l	.pad3
	dc.l	.pad4
	dc.l	.pad5
	dc.l	.pad6
	dc.l	.pad7
.pad7:
	move.b	d2,(a0)+
.pad6:
	move.w	d2,(a0)+
.pad4:
	move.l	d2,(a0)+
	bra.s	.dst_padded
.pad5:
	move.b	d2,(a0)+
	move.l	d2,(a0)+
	bra.s	.dst_padded
.pad3:
	move.b	d2,(a0)+
.pad2:
	move.w	d2,(a0)+
	bra.s	.dst_padded
.pad1:
	move.b	d2,(a0)+
	bra.s	.dst_padded
.slow_padding:
	add.l	d0,d1
	subq.w	#1,d0
.pad_dst:
	move.b	d2,(a0)+
	subq.l	#1,d1
	dbeq	d0,.pad_dst
	beq	.end_fill
.dst_padded:
	;; here, dest address is on a phrase boundary
	;; a0 = dst
	;; d1 = size
	;; d2 = fill pattern
	move.l	d2,B_PATD
	move.l	d2,B_PATD+4
	move.l	#0,A1_CLIP	; **work around**
	swap	d1
	tst.w	d1
	beq.s	.fill_lt_64k
.fill_x_64k:
	;; here we fill 64k by 64k
	subq.w	#1,d1
	move.l	#PIXEL32|XADDPHR|PITCH1,A1_FLAGS
.fill_loop:
	move.l	a0,A1_BASE	
	move.l	#0,A1_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 4 = $10000 = 64 ko
	move.l	#PATDSEL,B_CMD
	moveq	#1,d2
	swap	d2
	add.l	d2,a0
	wait_blitter	d2
	dbf	d1,.fill_loop
.fill_lt_64k:
	move.w	#1,d1
	swap	d1
	;; here d1 < 64k
	lsl.w	#1,d1
	bcc.s	.fill_lt_32k
.fill_32k:
	;; here we fill 32k
	move.l	#PIXEL32|XADDPHR|PITCH1,A1_FLAGS
	move.l	a0,A1_BASE	
	move.l	#0,A1_PIXEL
	move.l	#$12000,B_COUNT	; $2000 * 4 = $8000 = 32 ko
	move.l	#PATDSEL,B_CMD
	moveq	#1,d2
	swap	d2
	lsr.l	#1,d2
	add.l	d2,a0
	wait_blitter	d2
.fill_lt_32k:
	;; here d1 < 32k
	lsr.w	#1,d1
	beq.s	.end_fill
	move.l	#PIXEL8|XADDPHR|PITCH1,A1_FLAGS
	move.l	a0,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	d1,B_COUNT
	move.l	#PATDSEL,B_CMD
	wait_blitter	d2
.end_fill:
	move.l	(sp)+,d2
	move.l	4(sp),d0	; return address
	rts
