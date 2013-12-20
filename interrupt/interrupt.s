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

