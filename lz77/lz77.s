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

	.include	"jaguar.inc"

	.include	"../routine.s"

	.macro	movei_label
	movei	#\2-\1,\3
	.endm

NB_PARAMS	equ	2

.macro	read_byte
	;; \1: source address (may be modified)
	;; \2: cached data
	;; \3: number of bytes in cache
	;; \4: next byte read
	subq	#1,\3
	jr	pl,.not_empty\~
	move	\2,\4
	load	(\1),\2
	addqt	#4,\1
	moveq	#4-1,\3		; just read 4 bytes but will consume 1
	move	\2,\4
.not_empty\~:
	shrq	#24,\4
	shlq	#8,\2
.endm

	.data

	.phrase
depacker:
	.gpu
	.org	0
.depacker_begin:
	move	PC,r0
	movei_label	.depacker_begin,.depacker_params,r20
	movei_label	.depacker_begin,.depacker_literal,r21
	movei_label	.depacker_begin,.depacker_loadtag,r22
	movei_label	.depacker_begin,.depacker_search,r23
 	;; movei_label	.depacker_begin,.depacker_compressed,r24
	movei_label	.depacker_begin,.depacker_break,r25
	add	r0,r20		; relocate
	add	r0,r21		; relocate
	add	r0,r22		; relocate
	add	r0,r23		; relocate
 	;; add	r0,r24		; relocate
	add	r0,r25		; relocate
	;; set source (r1-r3)
	load	(r20),r1	; source data (must be long aligned)
	moveq	#0,r3		; size of read cache (initially empty)
	addqt	#4,r20
	addqt	#4,r1		; skip original length
	;; set target (r4)
	load	(r20),r4	; target buffer
	jr	.depacker_loadtag
	addqt	#4,r20
	;;
.depacker_literal:
	;; r9 is set to 8 by caller!
	read_byte	r1,r2,r3,r6 ; copy literal
	subq	#1,r9
	storeb	r6,(r4)		    ; write it
	jr	ne,.depacker_literal
	addqt	#1,r4
.depacker_loadtag:
	read_byte	r1,r2,r3,r5 ; load tag in r5
	shlq	#24,r5
	jump	eq,(r21)	; -> literal
	moveq	#8,r9
.depacker_search:
	read_byte	r1,r2,r3,r6 ; load literal or compression specifier
	shlq	#1,r5
	jr	cs,.depacker_compressed	; -> compressed
	move	r6,r7		; copy compression specifier
	subq	#1,r9
	storeb	r6,(r4)		    ; write it
	jr	ne,.depacker_search
	addqt	#1,r4
	jump	(r22)		; -> loadtag
	nop
.depacker_compressed:
	cmpq	#0,r7
	jump	eq,(r25)	; -> break
	move	r7,r6
	shlq	#28,r6
	shrq	#4,r7		; offset to string location (upper bits)
	shrq	#28,r6		; string length (0-15)
	shlq	#8,r7
	read_byte	r1,r2,r3,r8 ; lower bits of offset
	or	r8,r7		    ; offset to string location
	move	r4,r8
	sub	r7,r8		; address of string
	addqt	#1,r6		; copy between 2 and 17 bytes
.copy:
	loadb	(r8),r7		; read byte
	subq	#1,r6
	storeb	r7,(r4)		; copy it
	addqt	#1,r8
	jr	pl,.copy
	addqt	#1,r4
	subq	#1,r9
	jump	ne,(r23)	; -> search
	nop
	jump	(r22)		; -> loadtag
	nop
.depacker_break:
	moveq	#0,r2
        load    (r31),r0        ; return address
        addq    #4,r31
        jump    (r0)
	store	r2,(r20)	; clear mutex
	.long
.depacker_params:
	.rept	NB_PARAMS
	dc.l	0
	.endr
	dc.l	0
	.long
.depacker_end:

DEPACKER_SIZE	equ	.depacker_end-.depacker_begin
DEPACKER_PARAMS	equ	.depacker_params-.depacker_begin
DEPACKER_DEPACK	equ	.depacker_begin-.depacker_begin

	.print	"Depacker size = ",DEPACKER_SIZE," bytes"

	.68000
	.text

	.extern	_bcopy

	.globl	_init_lz77
;;; void *init_lz77(void *gpu_addr);
_init_lz77:
	pea	DEPACKER_SIZE
	move.l	4+4(sp),-(sp)
	pea	depacker
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),d0
	move.l	d0,depacker_addr
	add.l	#DEPACKER_SIZE,d0
	rts

	.globl	_lz77_unpack
;;; int lz77_unpack(uint8_t *in, uint8_t *out);
_lz77_unpack:
	move.l	depacker_addr,a0
	lea	DEPACKER_PARAMS(a0),a1
	move.l	4(sp),(a1)+	; source data
	move.l	8(sp),(a1)+	; target buffer
	move.l	#$80000000,(a1)	; mutex
	lea	DEPACKER_DEPACK(a0),a0
        jsr_gpu a0
	move.l	4(sp),a0
	move.l	(a0),d0
.wait:
	tst.l	(a1)
	bmi.s	.wait
	rts

	.globl	_lz77_unpack_async
;;; int lz77_unpack_async(uint8_t *in, uint8_t *out);
_lz77_unpack_async:
	move.l	depacker_addr,a0
	lea	DEPACKER_PARAMS(a0),a1
	move.l	4(sp),(a1)+	; source data
	move.l	8(sp),(a1)+	; target buffer
	move.l	#$80000000,(a1)	; mutex
	lea	DEPACKER_DEPACK(a0),a0
        jsr_gpu a0
	move.l	4(sp),a0
	move.l	(a0),d0
	rts

	.globl	_lz77_unpack_wait
;;; int lz77_unpack_wait:
_lz77_unpack_wait:
	move.l	depacker_addr,a0
	lea	DEPACKER_PARAMS+8(a0),a1
.wait:
	tst.l	(a1)
	bmi.s	.wait
	rts

        .data
        .phrase
        dc.b    'LZ77 Depacker by Seb/The Removers'
        .phrase

	.bss
	.long
depacker_addr:
	ds.l	1
