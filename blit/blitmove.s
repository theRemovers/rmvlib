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

.macro  wait_blitter
.wait_\~:
	move.l  B_CMD,\1
	btst    #0,\1
	beq.s   .wait_\~
.endm
	
	.globl	_blitmove

	.text
	.68000
	
;;; void *blitmove(void *src, void *dst, size_t n)
_blitmove:
	movem.l	d2/a2,-(sp)
	move.l	12+8(sp),d0
	beq	.move_end
	move.l	#0,A1_CLIP	; **work around**
	movem.l	12+0(sp),a0-a1	; a0=src, a1=dst
	cmp.l	a0,a1
	beq	.move_end
	blo	.fwd_move
.dst_hi_src:
	lea	(a0,d0.l),a2	; end src
	cmp.l	a2,a1
	bhi	.fwd_move	; forward PHRASE mode
.bwd_move:
	lea	(a1,d0.l),a1	; end dest
	move.l	a2,a0		; end src
	;; backward copy: slow since it uses PIXEL mode
	move.w	a0,d1
	lsr.w	#1,d1
	bcc	.bwd_src_even
.bwd_src_odd:
	move.w	a1,d1
	lsr.w	#1,d1
	bcs	.bwd_same_parity
.bwd_opposite_parity:
	move.w	a1,d1
	and.w	#%111,d1
	beq.s	.bwd_opp_dst_padded
	subq.w	#1,d1
.bwd_opp_pad_dst:
	move.b	-(a0),-(a1)
	subq.l	#1,d0
	dbeq	d1,.bwd_opp_pad_dst
	beq	.move_end
.bwd_opp_dst_padded:
;;; a0 is end of source address and is odd
;;; a1 is end of dest address and is aligned on a phrase boundary
;;; d0 is size to be moved
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
	moveq	#0,d1
	move.w	a0,d1
	and.w	#%111,d1	; we know it is odd
	sub.w	d1,a0
;;; first 16k blocks
	lsl.l	#2,d0
	swap	d0
	tst.w	d0
	beq.s	.bwd_opp_less_16k
	subq.w	#1,d0
.bwd_opp_x_16k:
.bwd_opp_fill_loop:
	move.l	#$4000,d2
	sub.l	d2,a0
	sub.l	d2,a1
	move.l	a0,A2_BASE
	move.l	a1,A1_BASE
	subq.w	#1,d2
	move.l	d2,A1_PIXEL
	add.w	d1,d2
	move.l	d2,A2_PIXEL
	move.l	#$14000,B_COUNT
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	dbf	d0,.bwd_opp_fill_loop
.bwd_opp_less_16k:
	move.w	#1,d0
	swap	d0
	lsr.w	#2,d0
	beq	.move_end
	moveq	#0,d2
	move.w	d0,d2
	addq.l	#7,d2
	and.w	#~%111,d2	; d2 <= $4000
	sub.l	d2,a0
	sub.l	d2,a1
	subq.w	#1,d2
	move.l	a1,A1_BASE
	move.l	d2,A1_PIXEL
	add.w	d1,d2		; here, we know that 0 <= d2 < 32767 !!
	move.l	d2,A2_PIXEL
	move.l	a0,A2_BASE
	move.l	d0,B_COUNT
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	bra	.move_end
.bwd_src_even:
	move.w	a1,d1
	lsr.w	#1,d1
	bcs	.bwd_opposite_parity
.bwd_same_parity:
;;; we first pad dest to a phrase boundary
	moveq	#0,d1		; because long op with d0
	move.w	a1,d1
	and.w	#%111,d1
	beq.s	.bwd_same_dst_padded
	sub.l	d1,d0
	blo.s	.bwd_same_slow_padding
.bwd_same_fast_padding:
	subq.w	#1,d1
	lsl.w	#2,d1
	move.l	.bwd_same_padrout(pc,d1.w),a2
	jmp	(a2)
.bwd_same_padrout:
	dc.l	.bwd_same_pad1
	dc.l	.bwd_same_pad2
	dc.l	.bwd_same_pad3
	dc.l	.bwd_same_pad4
	dc.l	.bwd_same_pad5
	dc.l	.bwd_same_pad6
	dc.l	.bwd_same_pad7
.bwd_same_pad7:
	move.b	-(a0),-(a1)
.bwd_same_pad6:
	move.w	-(a0),-(a1)
.bwd_same_pad4:
	move.l	-(a0),-(a1)
	bra.s	.bwd_same_dst_padded
.bwd_same_pad5:
	move.b	-(a0),-(a1)
	move.l	-(a0),-(a1)
	bra.s	.bwd_same_dst_padded
.bwd_same_pad3:
	move.b	-(a0),-(a1)
.bwd_same_pad2:
	move.w	-(a0),-(a1)
	bra.s	.bwd_same_dst_padded
.bwd_same_pad1:
	move.b	-(a0),-(a1)
	bra.s	.bwd_same_dst_padded
.bwd_same_slow_padding:
	add.l	d1,d0
	subq.w	#1,d1
.bwd_same_pad_dst:
	move.b	-(a0),-(a1)
	subq.l	#1,d0
	dbeq	d1,.bwd_same_pad_dst
	beq	.move_end
.bwd_same_dst_padded:
;;; a0 is end of source address and is even
;;; a1 is end of dest address and is aligned on a phrase boundary
;;; d0 is size to be moved
	moveq	#0,d1
	move.w	a0,d1
	and.w	#%111,d1
	sub.w	d1,a0
	lsr.w	#2,d1
	bcc	.bwd_same_long
.bwd_same_word:
	roxl.w	#1,d1		; offset
;;; here we work in 16 bits
	lsl.l	#1,d0
	swap	d0
	tst.w	d0
	beq.s	.bwd_same_word_lt_32k
.bwd_same_word_move_x_32k:
	subq.w	#1,d0
	move.l	#PIXEL16|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL16|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
.bwd_same_word_fill_loop:
	move.l	#$8000,d2
	sub.l	d2,a0
	sub.l	d2,a1
	move.l	a0,A2_BASE
	move.l	a1,A1_BASE
	lsr.l	#1,d2		; $4000
	subq.w	#1,d2
	move.l	d2,A1_PIXEL
	add.w	d1,d2
	move.l	d2,A2_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 2 = $8000
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	dbf	d0,.bwd_same_word_fill_loop
.bwd_same_word_lt_32k:
	move.w	#1,d0
	swap	d0
	lsl.w	#1,d0
	bcc.s	.bwd_same_word_lt_16k
	move.l	#PIXEL16|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL16|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
	move.l	#$4000,d2
	sub.l	d2,a0
	sub.l	d2,a1
	move.l	a0,A2_BASE
	move.l	a1,A1_BASE
	lsr.l	#1,d2		; $2000
	subq.w	#1,d2
	move.l	d2,A1_PIXEL
	add.w	d1,d2
	move.l	d2,A2_PIXEL
	move.l	#$12000,B_COUNT	; $2000 * 2 = $4000
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
.bwd_same_word_lt_16k:
	lsr.w	#2,d0
	beq	.move_end
	add.w	d1,d1		; offset *= 2
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
	moveq	#0,d2
	move.w	d0,d2
	addq.l	#7,d2
	and.w	#~%111,d2	; d2 <= $4000
	sub.l	d2,a0
	sub.l	d2,a1
	subq.w	#1,d2
	move.l	a1,A1_BASE
	move.l	d2,A1_PIXEL
	add.w	d1,d2		; here, we know that 0 <= d2 < 32767 !!
	move.l	d2,A2_PIXEL
	move.l	a0,A2_BASE
	move.l	d0,B_COUNT
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	bra	.move_end
.bwd_same_long:
;;; here we work in 32 bits
	swap	d0
	tst.w	d0
	beq.s	.bwd_same_long_move_lt_64k
.bwd_same_long_move_x_64k:
	subq.w	#1,d0
	move.l	#PIXEL32|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL32|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
.bwd_same_long_fill_loop:
	move.l	#$10000,d2
	sub.l	d2,a0
	sub.l	d2,a1
	move.l	a0,A2_BASE
	move.l	a1,A1_BASE
	lsr.l	#2,d2		; $4000 
	subq.w	#1,d2
	move.l	d2,A1_PIXEL
	add.w	d1,d2
	move.l	d2,A2_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 4 = $10000
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	dbf	d0,.bwd_same_long_fill_loop
.bwd_same_long_move_lt_64k:
;;; because offset might be > 0,
;;; the last block should be < 16k
;;; here, we make a 16k, 32k or 48k block
	move.w	#1,d0
	swap	d0
	moveq	#0,d2
	move.w	d0,d2
	rol.w	#2,d2
	and.w	#%11,d2
	beq.s	.bwd_same_long_move_lt_16k
	move.l	#PIXEL32|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL32|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
	swap	d2
	lsr.l	#2,d2
	sub.l	d2,a0
	sub.l	d2,a1
	move.l	a0,A2_BASE
	move.l	a1,A1_BASE
	lsr.l	#2,d2		
	swap	d2
	move.w	#1,d2
	swap	d2
	move.l	d2,B_COUNT
	swap	d2
	clr.w	d2
	swap	d2
	subq.w	#1,d2
	move.l	d2,A1_PIXEL
	add.w	d1,d2
	move.l	d2,A2_PIXEL
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
.bwd_same_long_move_lt_16k:
	lsl.w	#2,d0
	lsr.w	#2,d0
	beq	.move_end
	lsl.w	#2,d1		; offset *= 4
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A2_FLAGS
	move.l	#PIXEL8|XADDPIX|PITCH1|XSIGNSUB,A1_FLAGS
	moveq	#0,d2
	move.w	d0,d2
	addq.l	#7,d2
	and.w	#~%111,d2	; d2 <= $4000
	sub.l	d2,a0
	sub.l	d2,a1
	subq.w	#1,d2
	move.l	a1,A1_BASE
	move.l	d2,A1_PIXEL
	add.w	d1,d2		; here, we know that 0 <= d2 < 32767 !!
	move.l	d2,A2_PIXEL
	move.l	a0,A2_BASE
	move.l	d0,B_COUNT
	move.l	#LFU_REPLACE|SRCEN,B_CMD
	wait_blitter	d2
	bra	.move_end
.fwd_move:
	;; forward copy: fast since it uses PHRASE mode
	;; a0 = source address
	;; a1 = dest address
	;; d0 = size
	move.w	a0,d1
	lsr.w	#1,d1
	bcc	.fwd_src_even
.fwd_src_odd:
	move.w	a1,d1
	lsr.w	#1,d1
	bcs	.fwd_same_parity
.fwd_opposite_parity:
;;; here, the best we can do is moving 1 byte at a time
	moveq	#8,d1
	sub.w	a1,d1
	and.w	#%111,d1
	beq.s	.fwd_opp_dst_padded
	subq.w	#1,d1
.fwd_opp_pad_dst:
	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	dbeq	d1,.fwd_opp_pad_dst
	beq	.move_end
.fwd_opp_dst_padded:
	move.l	#LFU_REPLACE|SRCEN|SRCENX,a2 ; we have to realign source data (since it is odd)
	move.l	#PIXEL8|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL8|XADDPHR|PITCH1,A1_FLAGS
	moveq	#0,d1
	move.w	a0,d1
	and.w	#%111,d1	; we know it is not null
	sub.w	d1,a0
;;; first 16k blocks
	lsl.l	#2,d0
	swap	d0
	tst.w	d0
	beq.s	.fwd_opp_less_16k
	subq.w	#1,d0
.fwd_opp_x_16k:
.fwd_opp_fill_loop:
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 1 = $4000
	move.l	a2,B_CMD
	moveq	#1,d2
	swap	d2
	lsr.l	#2,d2
	add.l	d2,a0
	add.l	d2,a1
	wait_blitter	d2
	dbf	d0,.fwd_opp_fill_loop
.fwd_opp_less_16k:
	move.w	#1,d0
	swap	d0
	lsr.w	#2,d0
	beq	.move_end
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	d0,B_COUNT
	move.l	a2,B_CMD
	wait_blitter	d2
	bra	.move_end
.fwd_src_even:
	move.w	a1,d1
	lsr.w	#1,d1
	bcs	.fwd_opposite_parity
.fwd_same_parity:
;;; here, we can at least move 2 bytes at a time after dst padding
	moveq	#8,d1
	sub.w	a1,d1
	and.w	#%111,d1
	beq.s	.fwd_same_dst_padded
	sub.l	d1,d0
	blo.s	.fwd_same_slow_padding
.fwd_same_fast_padding:
	subq.w	#1,d1
	lsl.w	#2,d1
	move.l	.fwd_same_padrout(pc,d1.w),a2
	jmp	(a2)
.fwd_same_padrout:
	dc.l	.fwd_same_pad1
	dc.l	.fwd_same_pad2
	dc.l	.fwd_same_pad3
	dc.l	.fwd_same_pad4
	dc.l	.fwd_same_pad5
	dc.l	.fwd_same_pad6
	dc.l	.fwd_same_pad7
.fwd_same_pad7:	
	move.b	(a0)+,(a1)+
.fwd_same_pad6:	
	move.w	(a0)+,(a1)+
.fwd_same_pad4:	
	move.l	(a0)+,(a1)+
	bra.s	.fwd_same_dst_padded
.fwd_same_pad5:	
	move.b	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	bra.s	.fwd_same_dst_padded
.fwd_same_pad3:
	move.b	(a0)+,(a1)+
.fwd_same_pad2:
	move.w	(a0)+,(a1)+
	bra.s	.fwd_same_dst_padded
.fwd_same_pad1:
	move.b	(a0)+,(a1)+
	bra.s	.fwd_same_dst_padded
.fwd_same_slow_padding:
	add.l	d1,d0
	subq.w	#1,d1
.fwd_same_pad_dst:
	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	dbeq	d1,.fwd_same_pad_dst
	beq	.move_end
.fwd_same_dst_padded:
;;; the dest address is aligned on a phrase boundary
;;; and we know that the source address is even
;;; depending on src is long aligned or not, we transfer longs or words
	move.l	#LFU_REPLACE|SRCEN|SRCENX,a2 ; we realign source data unless it is phrase aligned (see below)
	moveq	#0,d1
	move.w	a0,d1
	and.w	#%111,d1
	sub.w	d1,a0
	lsr.w	#2,d1
	bcc	.fwd_same_long
.fwd_same_word:
	roxl.w	#1,d1		; offset
;;; here we transfer words until it remains less than 32k of data
;;; then we transfer bytes
;;; first 32k blocks
	lsl.l	#1,d0
	swap	d0
	tst.w	d0
	beq.s	.fwd_same_word_move_lt_32k
.fwd_same_word_move_x_32k:
	subq.w	#1,d0
	move.l	#PIXEL16|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL16|XADDPHR|PITCH1,A1_FLAGS
.fwd_same_word_fill_loop:
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 2 = $8000
	move.l	a2,B_CMD
	moveq	#1,d2
	swap	d2
	lsr.l	#1,d2
	add.l	d2,a0
	add.l	d2,a1
	wait_blitter	d2
	dbf	d0,.fwd_same_word_fill_loop
.fwd_same_word_move_lt_32k:
	move.w	#1,d0
	swap	d0
	lsr.w	#1,d0
	beq	.move_end
	add.w	d1,d1		; offset *= 2
	move.l	#PIXEL8|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL8|XADDPHR|PITCH1,A1_FLAGS
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	d0,B_COUNT
	move.l	a2,B_CMD
	wait_blitter	d2
	bra	.move_end
.fwd_same_long:
;;; here we transfer long words until it remains less than 32k of data
;;; then we transfer bytes
	bne.s	.fwd_same_long_go
	move.l	#LFU_REPLACE|SRCEN,a2 ; no need to realign source
.fwd_same_long_go:
;;; we first transfer 64k blocks
	swap	d0
	tst.w	d0
	beq.s	.fwd_same_long_move_lt_64k
.fwd_same_long_move_x_64k:
	subq.w	#1,d0
	move.l	#PIXEL32|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL32|XADDPHR|PITCH1,A1_FLAGS
.fwd_same_long_fill_loop:
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	#$14000,B_COUNT	; $4000 * 4 = $10000
	move.l	a2,B_CMD
	moveq	#1,d2
	swap	d2
	add.l	d2,a0
	add.l	d2,a1
	wait_blitter	d2
	dbf	d0,.fwd_same_long_fill_loop
.fwd_same_long_move_lt_64k:
;;; then possibly one 32k block
	move.w	#1,d0
	swap	d0
	lsl.w	#1,d0
	bcc.s	.fwd_same_long_move_lt_32k
.fwd_same_long_move_32k:
	move.l	#PIXEL32|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL32|XADDPHR|PITCH1,A1_FLAGS
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	#$12000,B_COUNT	; $2000 * 4 = $8000
	move.l	a2,B_CMD
	moveq	#1,d2
	swap	d2
	lsr.l	#1,d2
	add.l	d2,a0
	add.l	d2,a1
	wait_blitter	d2
.fwd_same_long_move_lt_32k:
	lsr.w	#1,d0
	beq.s	.move_end
	lsl.w	#2,d1		; offset *= 4
	move.l	#PIXEL8|XADDPHR|PITCH1,A2_FLAGS
	move.l	#PIXEL8|XADDPHR|PITCH1,A1_FLAGS
	move.l	a0,A2_BASE
	move.l	d1,A2_PIXEL
	move.l	a1,A1_BASE
	move.l	#0,A1_PIXEL
	move.l	d0,B_COUNT
	move.l	a2,B_CMD
	wait_blitter	d2
.move_end:	
	movem.l	(sp)+,d2/a2
	move.l	8(sp),d0	; return address
	rts
