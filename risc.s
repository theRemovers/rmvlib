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

	.if	^^defined	__RISC_H
	.print	"risc.s already included"
	end
	.endif
__RISC_H	equ	1

;; .macro	mulf
;; 	;; \1, \2: fixp integers
;; 	;; \3, \4, \5, \6, \7: temporary registers
;; 	;; \?8:	if defined, register containing a return address
;; 	;; result goes in \4
;; 	moveq	#0,\7
;; 	abs	\1
;; 	jr	cc,.pos\~
;; 	move	\1,\3
;; 	abs	\2
;; 	jr	cc,.oppsign\~
;; 	move	\2,\4
;; 	jr	.samesign\~
;; 	nop
;; .pos\~:
;; 	abs	\2
;; 	jr	cc,.samesign\~
;; 	move	\2,\4
;; .oppsign\~:
;; 	moveq	#1,\7
;; .samesign\~:
;; 	; fractionnal part 1 in \1 (lower word)
;; 	; fractionnal part 2 in \2 (lower word)
;; 	shrq	#16,\3		; integer part 1
;; 	shrq	#16,\4		; integer part 2
;; 	;; \7 is the sign of the result (0 = positive, 1 = negative)
;; 	;; \3.\1 * \4.\2 = \3*\4.(\1*\4 + \2*\3 + (\1*\2 >> 16))
;; 	move	\1,\5
;; 	move	\2,\6
;; 	mult	\4,\5		; \1*\4
;; 	mult	\3,\6		; \2*\3
;; 	add	\6,\5		; \1*\4+\2*\3
;; 	mult	\3,\4
;; 	mult	\1,\2
;; 	shlq	#16,\4		; \3*\4
;; 	shrq	#16,\2
;; 	add	\5,\4
;; 	cmpq	#0,\7
;; 	.if	\?8
;; 	jump	eq,(\8)
;; 	.else
;; 	jr	eq,.done\~
;; 	.endif
;; 	add	\2,\4		; instead of nop
;; 	.if	\?8
;; 	jump	(\8)
;; 	.endif
;; 	neg	\4		; instead of nop if \?8
;; 	.if	!\?8
;; .done\~:
;; 	.endif
;; .endm

.macro	mulf
	;; \1, \2: fixp integers
	;; \3, \4, \5, \6, \7: temporary registers
	;; \8: if defined, return address
	;; result goes in \4
	move	\1,\7
	abs	\1
	xor	\2,\7		; get sign of product in bit 31
	abs	\2
	move	\1,\3
	move	\2,\4
	; fractionnal part 1 in \1 (lower word)
	; fractionnal part 2 in \2 (lower word)
	shrq	#16,\3		; integer part 1
	shrq	#16,\4		; integer part 2
	;; parity of \7 is the sign of the result
	;; \3.\1 * \4.\2 = \3*\4.(\1*\4 + \2*\3 + (\1*\2 >> 16))
	move	\1,\5
	move	\2,\6
	mult	\4,\5		; \1*\4
	mult	\3,\6		; \2*\3
	mult	\3,\4
	add	\6,\5		; \1*\4+\2*\3
	mult	\1,\2
	shlq	#16,\4		; \3*\4
	shrq	#16,\2
	add	\5,\4
	btst	#31,\7
	.if	\?8
	jump	eq,(\8)
	.else
	jr	eq,.done\~
	.endif
	add	\2,\4
	.if	\?8
	jump	(\8)
	.else
	jr	.done\~
	.endif
	neg	\4
	.if	!\?8
.done\~:
	.endif
.endm

;; .macro	imulf
;; 	;; \1: 16 bit integer
;; 	;; \2: fixp integer
;; 	;; \3, \4: temporary register
;; 	;; \?5:	if defined, register containing a return address
;; 	;; result goes in \2
;; 	moveq	#0,\4
;; 	shlq	#16,\1
;; 	move	\2,\3
;; 	sharq	#16,\1		; ext.l
;; 	sharq	#16,\2		; integer part
;; 	abs	\1		; get absolute value
;; 	jr	cc,.pos\~
;; 	imult	\1,\2
;; 	moveq	#1,\4
;; .pos\~:
;; 	mult	\1,\3		; instead of nop
;; 	shlq	#16,\2
;; 	cmpq	#0,\4
;; 	.if	\?5
;; 	jump	eq,(\5)
;; 	.else
;; 	jr	eq,.done\~
;; 	.endif
;; 	add	\3,\2		; instead of nop
;; 	.if	\?5
;; 	jump	(\5)
;; 	.endif
;; 	neg	\2		; negate (instead of nop if \?5)
;; .done\~:	
;; .endm

.macro	imulf
	;; \1: 16 bit integer
	;; \2: fixp integer
	;; \3, \4: temporary register
	;; \5: if defined, return address
	;; result goes in \2
	shlq	#16,\1
	move	\2,\3
	sharq	#16,\1		; ext.l
	sharq	#16,\2		; integer part
	abs	\1		; get absolute value
	addc	\4,\4		; will be odd if \1 was negative
	imult	\1,\2
	mult	\1,\3		; instead of nop
	shlq	#16,\2
	btst	#0,\4
	.if	\?5
	jump	eq,(\5)
	.else
	jr	eq,.done\~
	.endif
	add	\3,\2
	.if	\?5
	jump	(\5)
	.else
	jr	.done\~
	.endif
	neg	\2
	.if	!\?5
.done\~:
	.endif
.endm
	
.macro	padding_nop
	.print	"adding ",\1/2," padding nop"
	.rept	(\1 / 2)
	nop
	.endr
.endm

.macro	push
	;; push \1 on stack
	subqt	#4,r31
	store	\1,(r31)
.endm

.macro	pop
	;; pop \1 from stack
	load	(r31),\1
	addqt	#4,r31
.endm

.macro	fast_jsr_cond
	;; \1: cc
	;; \2: jump address
	;; \3: return address
	move	PC,\3
	jump	\1,(\2)
	addqt	#6,\3
.endm

.macro	fast_jsr
	;; \1: jump address
	;; \2: return address
	move	PC,\2
	jump	(\1)
	addqt	#6,\2
.endm
