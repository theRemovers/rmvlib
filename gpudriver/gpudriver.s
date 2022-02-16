; The Removers'Library
; Copyright (C) 2006-2017 Seb/The Removers
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

	include	"routine.inc"
	
	.extern	GPU_SUBROUT_ADDR

	.extern	_bcopy
	
	.text

	.68000
	
	.globl	_init_gpu_routine
;;; void *init_gpu_routine(routine *routine, void *gpu_addr)
_init_gpu_routine:
	move.l	4(sp),a0
	move.l	8(sp),a1
	move.l	ROUTINE_SIZE(a0),-(sp)
	move.l	a1,-(sp)
	move.l	ROUTINE_ADDRESS(a0),-(sp)
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),a0
	move.l	8(sp),a1
	add.l	ROUTINE_SIZE(a0),a1
	add.l	ROUTINE_EXTRA(a0),a1
	move.l	a1,d0
	addq.l	#7,d0
	and.l	#~7,d0		; phrase aligned
	rts

	.globl	_call_gpu_routine
;;; void call_gpu_routine(routine *routine, void *addr, ...)
_call_gpu_routine:
	move.l	a2,-(sp)
	move.l	4+4(sp),a0
	move.l	4+8(sp),a1
	add.l	ROUTINE_PARAMS_OFFSET(a0),a1
	move.w	ROUTINE_NUM_PARAMS(a0),d0
	subq.w	#1,d0
	bmi.s	.no_params
	lea	4+12(sp),a2
.copy_params:
	move.l	(a2)+,(a1)+
	dbf	d0,.copy_params
.no_params:
	move.l	#$80000000,(a1)	; mutex
	move.l	4+8(sp),a2
	add.l	ROUTINE_START_OFFSET(a0),a2
	move.l	a2,GPU_SUBROUT_ADDR
	move.l	(sp)+,a2
.wait:
	tst.l	(a1)
	bmi.s	.wait
	rts

	.globl	_async_call_gpu_routine
;;; void async_call_gpu_routine(routine *routine, void *addr, ...)
_async_call_gpu_routine:
	move.l	a2,-(sp)
	move.l	4+4(sp),a0
	move.l	4+8(sp),a1
	add.l	ROUTINE_PARAMS_OFFSET(a0),a1
	move.w	ROUTINE_NUM_PARAMS(a0),d0
	subq.w	#1,d0
	bmi.s	.no_params
	lea	4+12(sp),a2
.copy_params:
	move.l	(a2)+,(a1)+
	dbf	d0,.copy_params
.no_params:
	move.l	#$80000000,(a1)	; mutex
	move.l	4+8(sp),a2
	add.l	ROUTINE_START_OFFSET(a0),a2
	move.l	a2,GPU_SUBROUT_ADDR
	move.l	(sp)+,a2
	rts

	.globl	_wait_gpu_routine
;;; void wait_gpu_routine(routine *routine, void *addr)
_wait_gpu_routine:
	move.l	4(sp),a0
	move.l	8(sp),a1
	add.l	ROUTINE_PARAMS_OFFSET(a0),a1
	moveq	#0,d0
	move.w	ROUTINE_NUM_PARAMS(a0),d0
	add.l	d0,d0
	add.l	d0,d0
	add.l	d0,a1
.wait:
	tst.l	(a1)
	bmi.s	.wait
	rts
	
