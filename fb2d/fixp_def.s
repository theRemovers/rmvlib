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

.macro	imulf
	;; \1 = 15 bits positive int
	;; \2 = 16.16 fixp int
	;; \3 = temporary data register
	;; result goes in \2	
	move.w	\2,\3
	mulu.w	\1,\3
	swap	\2
	muls.w	\1,\2
	swap	\2
	clr.w	\2
	add.l	\3,\2
.endm

.macro	mulf
	;; \1, \2 = 16.16 fixp int
	;; \3 = temporary data register
	;; result goes in \2
	;; \1 = a << 16 + b
	;; \2 = c << 16 + d
	tst.l	\1
	bge.s	.pos\~
	neg.l	\1
	tst.l	\2
	bge.s	.oppsign\~
	neg.l	\2
.samesign\~:
	move.w	\1,\3		; \3 = b
	move.w	\2,\1		; \1 = a | d
	swap	\2		; \2 = d | c
	mulu.w	\2,\3		; \3 = b*c
	swap	\1		; \1 = d | a
	mulu.w	\1,\2		; \2 = a * c
	swap	\2
	clr.w	\2		; \2 = a * c << 16
	add.l	\3,\2		; \2 = a * c << 16 + b * c
	move.w	\1,\3
	swap	\1
	mulu.w	\1,\3		; \3 = a * d
	add.l	\3,\2		; \2 = a * c << 16 + b * c + a * d
	bra.s	.done\~
.pos\~:	
	tst.l	\2
	bge.s	.samesign\~
	neg.l	\2
.oppsign\~:
	move.w	\1,\3		; \3 = b
	move.w	\2,\1		; \1 = a | d
	swap	\2		; \2 = d | c
	mulu.w	\2,\3		; \3 = b*c
	swap	\1		; \1 = d | a
	mulu.w	\1,\2		; \2 = a * c
	swap	\2
	clr.w	\2		; \2 = a * c << 16
	add.l	\3,\2		; \2 = a * c << 16 + b * c
	move.w	\1,\3
	swap	\1
	mulu.w	\1,\3		; \3 = a * d
	add.l	\3,\2		; \2 = a * c << 16 + b * c + a * d
	neg.l	\2
.done\~:
.endm

