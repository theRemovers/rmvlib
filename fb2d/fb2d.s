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
	include	"screen_def.s"

SINE_PREC	equ	4	; 128<<4 = 2048
NB_PARAMS	equ	3

	.include	"routine.s"
	
	.include	"risc.s"

.macro	read_rom_table
	;; \1: integer which represent the precision (128 << \1)
	;; \2: register containing the index wanted
	;; \3: r14 or r15 containing the base address of the table (ROM_SINE for example)
	;; \4, \5: temporary register
	;; \?6: if defined, register containing a return address
	;; result goes in \4
	move	\2,\5		; save real index
	shrq	#\1,\2		; map on [0;127]
	shlq	#32-\1,\5	; to take remainder
	move	\2,\4
	shlq	#32-7,\2
	subq	#1,\4		; previous index
	shrq	#32-(7+2),\2	; (index modulo 128) * 4
	shlq	#32-7,\4
	shrq	#32-\1,\5	; remainder
	shrq	#32-(7+2),\4	; ((index-1) modulo 128) * 4
	load	(\3+\2),\2	; table[index]
	load	(\3+\4),\4	; table[index-1]
	sub	\4,\2		; slope
	imult	\5,\2		; remainder * slope
	sharq	#\1,\2		; remainder * slope >> \1
	add	\2,\4
	.if	\?6
	jump	(\6)
	.endif
	shlq	#1,\4		; make 16.16 value (instead of nop if \?6)
.endm	
	
	.text

	.phrase
fb2d_manager:
	.dsp
	.org	0
.fb2d_begin:
.fb2d_set_rotation:
	move	PC,r0
	movei	#.fb2d_params-.fb2d_set_rotation,r1
	movei	#.read_table-.fb2d_set_rotation,r10
	add	r0,r1
	add	r0,r10
	load	(r1),r14	; matrix address
	addq	#4,r1
	load	(r1),r3		; angle
	addq	#4,r1
	moveq	#1,r4
	movei	#ROM_SINE,r15
	shlq	#(7+SINE_PREC-2),r4	; pi/2
	move	r3,r24
	add	r4,r3
	fast_jsr	r10,r27
	move	r3,r24
	move	r25,r3		; sinus
	fast_jsr	r10,r27
	store	r25,(r14)	; cosinus
	store	r3,(r14+1)	; sinus
	neg	r3
	store	r25,(r14+3)	; cosinus
	store	r3,(r14+2)	; -sinus
	;; done
	;; return from sub routine and clear mutex
	moveq	#0,r2
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
.fb2d_mult_matrix:
	move	PC,r0
	movei	#.fb2d_params-.fb2d_mult_matrix,r1
	movei	#.mulf-.fb2d_mult_matrix,r10
	add	r0,r1		; relocate
	add	r0,r10		; relocate
	load	(r1),r14	; m
	addq	#4,r1
	load	(r1),r15	; n
	addq	#4,r1
	;; read matrix m (a,b) (c,d)
	load	(r14),r2	; a
	load	(r14+1),r3	; b
	load	(r14+2),r4	; c
	load	(r14+3),r5	; d
	;; read matrix m (a',b') (c',d')
	load	(r15),r6	; a'
	load	(r15+1),r7	; b'
	load	(r15+2),r8	; c'
	load	(r15+3),r9	; d'
	move	r2,r20
	move	r6,r21
	fast_jsr	r10,r27
	move	r23,r11		; a*a'
	move	r3,r20
	move	r8,r21
	fast_jsr	r10,r27
	add	r23,r11		; a*a' + b*c'
	move	r2,r20
	move	r7,r21
	fast_jsr	r10,r27
	move	r23,r12		; a*b'
	move	r3,r20
	move	r9,r21
	fast_jsr	r10,r27
	add	r23,r12		; a*b' + b*d'
	move	r4,r20
	move	r6,r21
	fast_jsr	r10,r27
	move	r23,r13		; c*a'
	move	r5,r20
	move	r8,r21
	fast_jsr	r10,r27
	add	r23,r13		; c*a' + d*c'
	move	r4,r20
	move	r7,r21
	fast_jsr	r10,r27
	move	r23,r16		; c*b'
	move	r5,r20
	move	r9,r21
	fast_jsr	r10,r27
	add	r23,r16		; c*b' + d*d'
	store	r11,(r15)
	store	r12,(r15+1)
	store	r13,(r15+2)
	store	r16,(r15+3)
	;; done
	;; return from sub routine and clear mutex
	moveq	#0,r2
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
.fb2d_mult_matrix_vector:
	move	PC,r0
	movei	#.fb2d_params-.fb2d_mult_matrix_vector,r1
	movei	#.imulf-.fb2d_mult_matrix_vector,r10
	add	r0,r1		; relocate
	add	r0,r10		; relocate
	load	(r1),r14	; matrix
	addq	#4,r1
	load	(r1),r2		; y|x
	subq	#4,r1
	move	r2,r3
	shlq	#16,r2
	shrq	#16,r3		; y
	shrq	#16,r2		; x
	load	(r14),r24	; a
	move	r2,r23		; x
	fast_jsr	r10,r27
	move	r24,r4		; a*x
	move	r3,r23		; y
	load	(r14+1),r24	; b
	fast_jsr	r10,r27
	add	r24,r4		; a*x + b*y
	move	r2,r23		; x
	load	(r14+2),r24	; c
	fast_jsr	r10,r27
	move	r24,r5		; c*x
	move	r3,r23		; y
	load	(r14+3),r24	; d
	fast_jsr	r10,r27
	add	r24,r5		; c*x + d*y
	store	r4,(r1)
	addq	#4,r1
	store	r5,(r1)
	addq	#4,r1
	;; done
	;; return from sub routine and clear mutex
	moveq	#0,r2
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
.mulf:
	;; multiply r20 by r21 (as 16.16 fixpoint integers)
	;; result goes in r23
	;; return address in r27
	mulf	r20,r21,r22,r23,r24,r25,r26,r27
.imulf:
	;; multiply r24 by r25 (as a positive integer by a 16.16 fixpoint integer)
	;; result goes in r25
	;; return address in r27
	imulf	r23,r24,r25,r26,r27
.read_table:
	;; get value in Jerry rom table
	;; value are on 0-2048 ( = 127<<4)
	;; return address in r27
	;; base table address in r15
	;; index in r24
	;; result goes in r25
	read_rom_table	SINE_PREC,r24,r15,r25,r26,r27
	.long
.fb2d_params:
	.rept	NB_PARAMS
	dc.l	0
	.endr
	.long
.fb2d_end:	

FB2D_MANAGER_SIZE	equ	.fb2d_end-.fb2d_begin
FB2D_SET_ROTATION	equ	.fb2d_set_rotation-.fb2d_begin
FB2D_MULT_MATRIX	equ	.fb2d_mult_matrix-.fb2d_begin
FB2D_MULT_MATRIX_VECTOR	equ	.fb2d_mult_matrix_vector-.fb2d_begin
FB2D_PARAMS	equ	.fb2d_params-.fb2d_begin
	
	.print	"Frame Buffer manager routine size: ",FB2D_MANAGER_SIZE
	.print	"Set Rotation: ",FB2D_SET_ROTATION
	.print	"Mult Matrix: ", FB2D_MULT_MATRIX
	.print	"Mult Matrix Vector: ", FB2D_MULT_MATRIX_VECTOR
	
	.68000
	.text

	.extern	_bcopy
	.globl	_init_fb2d_manager

;;; void *init_fb2d_manager(void *dsp_addr);
_init_fb2d_manager:
	pea	FB2D_MANAGER_SIZE
	move.l	4+4(sp),-(sp)
	pea	fb2d_manager
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),d0
	move.l	d0,fb2d_dsp_address
	add.l	#FB2D_MANAGER_SIZE,d0
	rts

	.globl	_fb2d_compose_linear_transform
;;; void fb2d_compose_linear_transform(linear_transform *m1, linear_transform *m2)
_fb2d_compose_linear_transform:
	move.l	fb2d_dsp_address,a0
	lea	FB2D_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),(a1)+
	move.l	#$80000000,(a1)
	lea	FB2D_MULT_MATRIX(a0),a1
	jsr_dsp	a1
	lea	FB2D_PARAMS+8(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	rts

	.globl	_fb2d_set_rotation
;;; void fb2d_set_rotation(linear_transform *m, int angle)
_fb2d_set_rotation:
	move.l	fb2d_dsp_address,a0
	lea	FB2D_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),(a1)+
	move.l	#$80000000,(a1)
	lea	FB2D_SET_ROTATION(a0),a1
	jsr_dsp	a1
	lea	FB2D_PARAMS+8(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	rts

	.globl	_fb2d_set_matching_points
;;; void fb2d_set_matching_points(affine_transform *m, int x1, int y1, int x2, int y2)
_fb2d_set_matching_points:
	move.l	fb2d_dsp_address,a0
	lea	FB2D_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.w	20+2(sp),d0	; y2
	swap	d0
	move.w	16+2(sp),d0	; x2
	move.l	d0,(a1)+	; y2|x2
	move.l	#$80000000,(a1)
	lea	FB2D_MULT_MATRIX_VECTOR(a0),a1
	jsr_dsp	a1
	move.l	4(sp),a1
	moveq	#0,d0
	move.w	8+2(sp),d0
	swap	d0		; x1 (16.16)
	moveq	#0,d1
	move.w	12+2(sp),d1
	swap	d1		; y1 (16.16)
	lea	FB2D_PARAMS+8(a0),a0
	lea	16(a1),a1
.wait:
	tst.l	(a0)
	bmi.s	.wait
	subq.w	#8,a0
	sub.l	(a0)+,d0	; x1 - (a * x2 + b * y2)
	sub.l	(a0)+,d1	; y1 - (c * x2 + d * y2)
	move.l	d0,(a1)+
	move.l	d1,(a1)+
	rts

	.globl	_fb2d_copy_straight
;;; void fb2d_copy_straight(screen *src, screen *dst, int w, int h, int mode, ...);
_fb2d_copy_straight:
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
.no_dcompen:
	btst.l	#26,d3		; bit comparator?
	beq.s	.no_bcompen
	move.l	3*4+24(sp),B_PATD ; color when bit on
	move.l	#0,B_DSTD	  ; color when bit off (not used)
.no_bcompen:
	move.l	d3,B_CMD
	movem.l	(sp)+,d2-d4
	wait_blitter	d0
	rts
.done:	
	movem.l	(sp)+,d2-d4
	rts
	
	.globl	_fb2d_compute_bounding_box
;;; fb2d_compute_bounding_box(linear_transform *m, int w1, int h1, int *w2, int *h2);
_fb2d_compute_bounding_box:	
	movem.l	d2-d4,-(sp)
	move.l	fb2d_dsp_address,a0
	move.l	#private_matrix,a1
	;; initialise matrix
	;; A = (w 0)
	;; B = (0 h)
	;; C = (w h)
	move.w	3*4+8+2(sp),(a1)+ 	; w
	clr.w	(a1)+
	clr.l	(a1)+		; 0
	clr.l	(a1)+		; 0
	move.w	3*4+12+2(sp),(a1)+	; h
	clr.w	(a1)+
	lea	-16(a1),a1
	lea	FB2D_PARAMS(a0),a0
	move.l	3*4+4(sp),(a0)+
	move.l	a1,(a0)+
	move.l	#$80000000,(a0)
	lea	FB2D_MULT_MATRIX-(FB2D_PARAMS+8)(a0),a0
	jsr_dsp	a0
	lea	FB2D_PARAMS+8-FB2D_MULT_MATRIX(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	;; here we get A' and B'
	movem.l	(a1),d0-d3	; read A' = (d0,d2) and B' = (d1,d3)
	move.l	d0,d4
	add.l	d1,d4		; xC' = xA' + xB'
	bge.s	.dx1_pos
	neg.l	d4
.dx1_pos:
	sub.l	d1,d0		; xA' - xB'
	bge.s	.dx2_pos
	neg.l	d0
.dx2_pos:
	cmp.l	d0,d4
	ble.s	.dx_ok
	move.l	d4,d0
.dx_ok:
	move.l	d2,d4
	add.l	d3,d4		; yC' = yA' + yB'
	bge.s	.dy1_pos
	neg.l	d4
.dy1_pos:
	sub.l	d3,d2		; yA' - yB'
	bge.s	.dy2_pos
	neg.l	d2
.dy2_pos:
	cmp.l	d2,d4
	ble.s	.dy_ok
	move.l	d4,d2
.dy_ok:
	;; d0 = w2 (16.16 value)
	;; d2 = h2 (16.16 value)
	add.l	#$ffff,d0	; round
	add.l	#$ffff,d2	; round
	clr.w	d0
	clr.w	d2
	swap	d0
	swap	d2
	movem.l	3*4+16(sp),a0-a1
	move.l	d0,(a0)
	move.l	d2,(a1)
	movem.l	(sp)+,d2-d4	
	rts
	
	.globl	_fb2d_copy_transformed
;;; void fb2d_copy_transformed(screen *src, screen *dst, affine_transform *t, int w, int h, int mode, ...);
_fb2d_copy_transformed:
	movem.l	d2-d7,-(sp)
	move.w	6*4+20+2(sp),d3	; h
	ble	.done
	swap	d3
	move.w	6*4+16+2(sp),d3	; w
	ble	.done
	movem.l	6*4+4(sp),d0-d2	; src/dst/transform
	;; at this point
	;; d0 = source screen
	;; d1 = destination screen
	;; d2 = transformation
	;; d3 = h|w 
	;; a0 = private matrix
	;; a1 = FB2D_PARAMS+8
	move.l	d1,a0
	move.l	SCREEN_Y(a0),d4
	move.l	SCREEN_H(a0),d6	; h2|w2
	move.l	d4,d7		; y2|x2
	moveq	#0,d5
	move.w	d4,d5
	swap	d5		; x2
	clr.w	d4		; y2
	;; fill matrix
	move.l	#private_matrix,a0
	move.l	d5,(a0)+	; x2
	clr.l	(a0)+		; 0
	clr.l	(a0)+		; 0
	move.l	d4,(a0)+	; y2
	lea	-16(a0),a0
	;; mult matrix (for clipping)
	move.l	fb2d_dsp_address,a1
	lea	FB2D_PARAMS(a1),a1
	move.l	d2,(a1)+	; transformation
	move.l	a0,(a1)+	; private matrix
	move.l	#$80000000,(a1)
	lea	FB2D_MULT_MATRIX-(FB2D_PARAMS+8)(a1),a1
	jsr_dsp	a1
	lea	FB2D_PARAMS+8-FB2D_MULT_MATRIX(a1),a1
	lea	-16(a0),a0
.wait1:	
	tst.l	(a1)
	bmi.s	.wait1
	moveq	#0,d4		; offset x1
	moveq	#0,d5		; offset y1
	tst.w	d7
	bge.s	.x2_pos
	sub.l	(a0),d4
	sub.l	8(a0),d5
	add.w	d7,d3		; w -= |x2|
	clr.w	d7
.x2_pos:
	sub.w	d7,d6		; max width = w2 - x2
	ble	.done
	cmp.w	d3,d6
	bgt.s	.clipped_w2
	move.w	d6,d3
.clipped_w2:	
	swap	d3		; w|h
	swap	d6		; w2|h2
	swap	d7		; x2|y2
	tst.w	d7
	bge.s	.y2_pos
	sub.l	4(a0),d4
	sub.l	12(a0),d5
	add.w	d7,d3		; h -= |y2|
	clr.w	d7
.y2_pos:
	sub.w	d7,d6		; max height = h2 - x2
	ble	.done
	cmp.w	d3,d6
	bgt.s	.clipped_h2
	move.w	d6,d3
.clipped_h2:	
	;; here we have
	;; d4 = 16.16 value to be added to x1
	;; d5 = 16.16 value to be added to y1
	;; d7 = x2|y2 (clipped)
	;; d3 = w|h (clipped)
	swap	d3		; h|w
	swap	d7		; y2|x2
	exg	d1,a0		; d1 = private matrix, a0 = dest screen
	move.l	d7,A2_PIXEL	
	move.l	SCREEN_FLAGS(a0),d7
	or.l	#XADDPIX,d7
	move.l	d7,A2_FLAGS
	move.l	SCREEN_DATA(a0),A2_BASE
	moveq	#1,d6
	swap	d6
	move.w	d3,d6
	neg.w	d6
	move.l	d6,A2_STEP
	move.l	d3,B_COUNT
	move.l	d0,a0		; source screen
	move.l	SCREEN_FLAGS(a0),d1
	or.l	#XADDINC,d1
	move.l	d1,A1_FLAGS
	move.l	SCREEN_DATA(a0),A1_BASE
	move.l	SCREEN_H(a0),A1_CLIP
	;; address of transformation is preserved
	subq.w	#4,a1
	move.l	d6,(a1)+	; 1|-w
	move.l	#$80000000,(a1)
	lea	FB2D_MULT_MATRIX_VECTOR-(FB2D_PARAMS+8)(a1),a1
	jsr_dsp	a1
	lea	FB2D_PARAMS+8-FB2D_MULT_MATRIX_VECTOR(a1),a1
	move.l	SCREEN_Y(a0),d1
	move.l	d2,a0		; transformation
	move.l	(a0)+,d0	; a
	addq.w	#4,a0		; skip b
	move.l	(a0)+,d2	; c
	addq.w	#4,a0		; skip d
	moveq	#0,d3
	move.w	d1,d3
	swap	d3
	add.l	d3,d4
	add.l	(a0)+,d4	; e
	clr.w	d1
	add.l	d1,d5
	add.l	(a0)+,d5	; f
	move.w	d5,d6
	swap	d6
	move.w	d4,d6
	move.l	d6,A1_FPIXEL
	swap	d4
	move.w	d4,d5
	move.l	d5,A1_PIXEL
	;; A1_INC(x) = a, A1_INC(y) = c
	move.w	d2,d6
	swap	d6
	move.w	d0,d6
	move.l	d6,A1_FINC
	swap	d0
	move.w	d0,d2
	move.l	d2,A1_INC
.wait2:
	tst.l	(a1)
	bmi.s	.wait2
	subq.w	#8,a1
	move.l	(a1)+,d1	; -a*w + b = A1_STEP(x)
	move.l	(a1)+,d3	; -c*w + d = A1_STEP(y)
	move.w	d3,d6
	swap	d6
	move.w	d1,d6
	move.l	d6,A1_FSTEP
	swap	d1
	move.w	d1,d3
	move.l	d3,A1_STEP
	;; d7 is A2_FLAGS
 	move.l	#UPDA1|UPDA1F|UPDA2|DSTA2|CLIP_A1,d3
 	or.l	6*4+24(sp),d3
	;; if DEPTH < 2^3 then DSTEN unless BKGWREN
;; 	btst.l	#28,d3		; bkgwren ?
;; 	bne.s	.depth_ge_8
	lsr.w	#3,d7
	and.w	#%111,d7
	cmp.w	#3,d7
	bhs.s	.depth_ge_8
	or.l	#DSTEN,d3
.depth_ge_8:	
	btst.l	#27,d3		; data comparator?
	beq.s	.no_dcompen
	move.l	#0,B_PATD
.no_dcompen:
	btst.l	#26,d3		; bit comparator?
	beq.s	.no_bcompen
	move.l	6*4+28(sp),B_PATD 	; color when bit on
	move.l	#0,B_DSTD	  	; color when bit off (not used)
.no_bcompen:
	move.l	d3,B_CMD
	movem.l	(sp)+,d2-d7
	wait_blitter	d0
	rts
.done:	
	movem.l	(sp)+,d2-d7
	rts
		
	.data
	.globl	_fb2d_routine_info
	.long
_fb2d_routine_info:
	dc.l	DSP_ROUTINE
	dc.l	fb2d_manager
	dc.l	FB2D_MANAGER_SIZE
	dc.l	FB2D_PARAMS
	dc.l	3
	dc.l	FB2D_SET_ROTATION
	dc.l	FB2D_MULT_MATRIX
	dc.l	FB2D_MULT_MATRIX_VECTOR
	
	.phrase
	dc.b	'Frame Buffer manager by Seb/The Removers'
	.phrase

	.bss
	.long
fb2d_dsp_address:
	ds.l	1

	.long
private_matrix:
	ds.l	4

