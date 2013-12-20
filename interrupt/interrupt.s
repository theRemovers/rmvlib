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

	.text
	.68000

VBL_QUEUE_SIZE	equ	8

	;; LOW_PRIORITY is still experimental
	;; for some unknown reasons it does not work properly yet
	;; the handlers are executed just after the interrupt
	;; occurs and not during the interrupt
	;; this allows to use the blitter in an interrupt handler for example
USE_LOW_PRIORITY	equ	0

	.globl	_init_interrupts
	.extern	_a_vde

_init_interrupts:
	or.w	#$0700,sr
	clr.w	_vblCounter
	move.l	#_vblQueue,a0
	moveq	#VBL_QUEUE_SIZE-1,d0
.clr_queue:
	clr.l	(a0)+
	dbf	d0,.clr_queue
	clr.l	timer_handler
	move.l	#InterruptHandler,LEVEL0
	move.w	_a_vde,d0
	or.w	#1,d0
	move.w	d0,VI
        move.w  d0,_VI_Reg
	moveq	#0,d0
	move.w	#C_VIDCLR|C_VIDENA,d0
	swap	d0
	move.l	d0,irq		; clear also mutex
	swap	d0
	and.w	#$ff,d0
	or.w	d0,INT1
	and.w	#$f8ff,sr
	rts

	.globl	_set_timer
_set_timer:
	or.w	#$0700,sr
	move.l	4(sp),d0
	swap	d0
	move.l	d0,PIT0
	move.l	4+4(sp),timer_handler
	or.w	#C_PITCLR|C_PITENA,irq
	or.w	#C_PITENA,INT1
	and.w	#$f8ff,sr
	rts

	.globl	_clear_timer
_clear_timer:
	or.w	#$0700,sr
	clr.l	timer_handler
	move.w	irq,d0
	and.w	#~(C_PITCLR|C_PITENA),d0
	move.w	d0,irq
	and.w	#$ff,d0
	move.w	d0,INT1
	and.w	#$f8ff,sr
	rts

InterruptHandler:
	.if	USE_LOW_PRIORITY
	movem.l	d0-d1,-(sp)
	move.w	INT1,d0
	and.w	#%11111,d0
	move.w	irq_mutex,d1	; get it currently processed
	not.w	d1
	and.w	d1,d0		; mask them
	or.w	d0,irq_mutex
	lsl.w	#2,d0
	move.l	.it_handler(pc,d0.w),.handler_to_call
	movem.l	(sp)+,d0-d1
	move.w	(sp),-4(sp)
	move.l	.handler_to_call,-2(sp)
	subq.w	#4,sp
	move.w	irq,INT1
	move.w	#0,INT2
	rte
	.else
	movem.l	d0-d2/a0-a2,-(sp)
	move.w	INT1,d2
	btst.l	#0,d2
	beq.s	.no_vblank
.vblank:
	swap	d2
	addq.w	#1,_vblCounter
	move.l	#_vblQueue,a2
	move.w	#VBL_QUEUE_SIZE-1,d2
.exec_vbl_queue:
	move.l	(a2)+,d0
	beq.s	.no_exec
.exec:
	move.l	d0,a0
	jsr	(a0)
.no_exec:
	dbf	d2,.exec_vbl_queue
	swap	d2
.no_vblank:
	btst.l	#3,d2
	beq.s	.no_timer
.timer:
	move.l	timer_handler,d0
	beq.s	.no_timer
	move.l	d0,a0
	jsr	(a0)
.no_timer:
	movem.l	(sp)+,d0-d2/a0-a2
	move.w	irq,INT1
	move.w	#0,INT2
	rte
	.endif
	.if	USE_LOW_PRIORITY
.handler_to_call:
	dc.l	.handler00000
.it_handler:
	dc.l	.handler00000
	dc.l	.handler00001
	dc.l	.handler00010
	dc.l	.handler00011
	dc.l	.handler00100
	dc.l	.handler00101
	dc.l	.handler00110
	dc.l	.handler00111
	dc.l	.handler01000
	dc.l	.handler01001
	dc.l	.handler01010
	dc.l	.handler01011
	dc.l	.handler01100
	dc.l	.handler01101
	dc.l	.handler01110
	dc.l	.handler01111
	dc.l	.handler10000
	dc.l	.handler10001
	dc.l	.handler10010
	dc.l	.handler10011
	dc.l	.handler10100
	dc.l	.handler10101
	dc.l	.handler10110
	dc.l	.handler10111
	dc.l	.handler11000
	dc.l	.handler11001
	dc.l	.handler11010
	dc.l	.handler11011
	dc.l	.handler11100
	dc.l	.handler11101
	dc.l	.handler11110
	dc.l	.handler11111
.handler00000:
	rts
;	movem.l	d0-d1/a0-a1,-(sp)
;	moveq	#%00000,d0
;	bra	.real_handler
.handler00001:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00001,d2
	bra	.real_handler
.handler00010:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00010,d2
	bra	.real_handler
.handler00011:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00011,d2
	bra	.real_handler
.handler00100:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00100,d2
	bra	.real_handler
.handler00101:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00101,d2
	bra	.real_handler
.handler00110:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00110,d2
	bra	.real_handler
.handler00111:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%00111,d2
	bra	.real_handler
.handler01000:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01000,d2
	bra	.real_handler
.handler01001:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01001,d2
	bra	.real_handler
.handler01010:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01010,d2
	bra	.real_handler
.handler01011:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01011,d2
	bra	.real_handler
.handler01100:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01100,d2
	bra	.real_handler
.handler01101:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01101,d2
	bra	.real_handler
.handler01110:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01110,d2
	bra	.real_handler
.handler01111:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%01111,d2
	bra.s	.real_handler
.handler10000:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10000,d2
	bra.s	.real_handler
.handler10001:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10001,d2
	bra.s	.real_handler
.handler10010:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10010,d2
	bra.s	.real_handler
.handler10011:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10011,d2
	bra.s	.real_handler
.handler10100:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10100,d2
	bra.s	.real_handler
.handler10101:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10101,d2
	bra.s	.real_handler
.handler10110:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10110,d2
	bra.s	.real_handler
.handler10111:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%10111,d2
	bra.s	.real_handler
.handler11000:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11000,d2
	bra.s	.real_handler
.handler11001:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11001,d2
	bra.s	.real_handler
.handler11010:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11010,d2
	bra.s	.real_handler
.handler11011:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11011,d2
	bra.s	.real_handler
.handler11100:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11100,d2
	bra.s	.real_handler
.handler11101:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11101,d2
	bra.s	.real_handler
.handler11110:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11110,d2
	bra.s	.real_handler
.handler11111:
	movem.l	d0-d2/a0-a2,-(sp)
	moveq	#%11111,d2
.real_handler:
	btst.l	#4,d2
	beq.s	.no_jerry_it
.jerry_it:
	bclr	#4,irq_mutex+1
.no_jerry_it:
	btst.l	#3,d2
	beq.s	.no_timer_it
.timer_it:
	move.l	timer_handler,d0
	beq.s	.skip_timer_it
	move.l	d0,a0
	jsr	(a0)
.skip_timer_it:
	bclr	#3,irq_mutex+1
.no_timer_it:
	btst.l	#2,d2
	beq.s	.no_op_it
.op_it:
	bclr	#2,irq_mutex+1
.no_op_it:
	btst.l	#1,d2
	beq.s	.no_gpu_it
.gpu_it:
	bclr	#1,irq_mutex+1
.no_gpu_it:
	btst.l	#0,d2
	beq.s	.no_vbl_it
.vbl_it:
	addq.w	#1,_vblCounter
	move.l	#_vblQueue,a2
	swap	d2
	move.w	#VBL_QUEUE_SIZE-1,d2
.exec_vbl_queue:
	move.l	(a2)+,d0
	beq.s	.no_exec
.exec:
	move.l	d0,a0
	jsr	(a0)
.no_exec:
	dbf	d2,.exec_vbl_queue
	swap	d2
	bclr	#0,irq_mutex+1
.no_vbl_it:
	movem.l	(sp)+,d0-d2/a0-a2
	rts
	.endif

	.globl	_vsync

_vsync:
	move.l	#_vblCounter,a0
	move.w	(a0),d0
.wait:
	cmp.w	(a0),d0
	beq.s	.wait
	rts

	.bss

	.globl	_vblCounter
	.globl	_vblQueue
        .globl  _VI_Reg

	.long
irq:		ds.w	1
irq_mutex:	ds.w	1
	.long
timer_handler:	ds.l	1
	.even
_vblCounter:	ds.w	1
        .even
_VI_Reg:        ds.w    1
	.long
_vblQueue:	ds.l	VBL_QUEUE_SIZE

