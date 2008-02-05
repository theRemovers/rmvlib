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

	.if	^^defined	RISC_H
	.print	"risc.s already included"
	end
	.endif
RISC_H	equ	1

.macro	mulf
	;; \1, \2: fixp integers
	;; \3, \4, \5, \6, \7: temporary registers
	;; \?8:	if defined, register containing a return address
	;; result goes in \4
	moveq	#0,\7
	abs	\1
	jr	cc,.pos\~
	move	\1,\3
	abs	\2
	jr	cc,.oppsign\~
	move	\2,\4
	jr	.samesign\~
	nop
.pos\~:
	abs	\2
	jr	cc,.samesign\~
	move	\2,\4
.oppsign\~:
	moveq	#1,\7
.samesign\~:
	; fractionnal part 1 in \1 (lower word)
	; fractionnal part 2 in \2 (lower word)
	shrq	#16,\3		; integer part 1
	shrq	#16,\4		; integer part 2
	;; \7 is the sign of the result (0 = positive, 1 = negative)
	;; \3.\1 * \4.\2 = \3*\4.(\1*\4 + \2*\3 + (\1*\2 >> 16))
	move	\1,\5
	move	\2,\6
	mult	\4,\5		; \1*\4
	mult	\3,\6		; \2*\3
	add	\6,\5		; \1*\4+\2*\3
	mult	\3,\4
	mult	\1,\2
	shlq	#16,\4		; \3*\4
	shrq	#16,\2
	add	\5,\4
	cmpq	#0,\7
	.if	\?8
	jump	eq,(\8)
	.else
	jr	eq,.done\~
	.endif
	add	\2,\4		; instead of nop
	.if	\?8
	jump	(\8)
	.endif
	neg	\4		; instead of nop if \?8
	.if	!\?8
.done\~:
	.endif
.endm

.macro	imulf
	;; \1: 16 bit integer
	;; \2: fixp integer
	;; \3, \4: temporary register
	;; \?5:	if defined, register containing a return address
	;; result goes in \2
	moveq	#0,\4
	shlq	#16,\1
	move	\2,\3
	sharq	#16,\1		; ext.l
	sharq	#16,\2		; integer part
	abs	\1		; get absolute value
	jr	cc,.pos\~
	imult	\1,\2
	moveq	#1,\4
.pos\~:
	mult	\1,\3		; instead of nop
	shlq	#16,\2
	cmpq	#0,\4
	.if	\?5
	jump	eq,(\5)
	.else
	jr	eq,.done\~
	.endif
	add	\3,\2		; instead of nop
	.if	\?5
	jump	(\5)
	.endif
	neg	\2		; negate (instead of nop if \?5)
.done\~:	
.endm
	
.macro	fast_jsr
	;; \1: jump address
	;; \2: return address
	move	PC,\2
	jump	(\1)
	addqt	#6,\2
.endm

 	.extern	DSP_SUBROUT_ADDR
.macro	jsr_dsp
	;; \1: address of the subroutine
	move.l	\1,DSP_SUBROUT_ADDR
.endm

	.extern	GPU_SUBROUT_ADDR
.macro	jsr_gpu
	;; \1: address of the subroutine
	move.l	\1,GPU_SUBROUT_ADDR
.endm
