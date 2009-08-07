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

	include	"../display/display_def.s"

	include	"../routine.s"
	
	.text	
	.68000
			
;;; GPU collision sub-routine
;;; this sub-routine works only on non-scaled 
;;; 16 bpp transparent sprites (animation is taken into account)
;;; the field FIRSTPIX, REFLECT are ignored
;;; this sub-routine is self-relocatable
;;; it computes the intersection box and the collision flag
COLLISION_COLLIDE		equ	15
COLLISION_Y1_LE_Y2		equ	0
COLLISION_X1_LE_X2		equ	1
COLLISION_INTERSECT		equ	7
		
	.phrase
display_collision_routine:
	.gpu
	.org	0
.gpu_collision_begin:
	move	PC,r16	; to relocate the sub routine
	movei	#.gpu_collision_params+8-.gpu_collision_begin,r0
	moveq	#1,r1
	add	r16,r0		; relocate
	shlq	#31,r1
	store	r1,(r0)		; not yet tested (most significant bit is a mutex)
	subq	#8,r0
	load	(r0),r14	; SPRITE1
	addq	#4,r0
	load	(r0),r15	; SPRITE2
	addq	#4,r0
	;; r14 is SPRITE1 address
	;; r15 is SPRITE2 address
	;; r0 is subrout result address
	load	(r14+SPRITE_SND_PHRASE/4),r1
	load	(r14+(SPRITE_SND_PHRASE+4)/4),r2
  	load	(r14+SPRITE_Y/4),r4 ; !! get Y|X 
	load	(r15+SPRITE_SND_PHRASE/4),r21
	load	(r15+(SPRITE_SND_PHRASE+4)/4),r22
  	load	(r15+SPRITE_Y/4),r24 ; !! get Y|X
	move	r1,r9		     ; copy high bits of snd phrase
	move	r21,r10		     ; copy high bits of snd phrase
	;; the base DATA address will be fetched only if needed
	moveq	#0,r3		     ; DATA1
	moveq	#0,r23		     ; DATA2
;; 	btst	#SPRITE_ANIM_ON_OFF,r1
;; 	jr	eq,.no_sprite1_anim
;; 	load	(r14+(SPRITE_SND_PHRASE+4)/4),r2
;; .sprite1_anim:
;; 	load	(r14+SPRITE_ANIM_DATA/4),r3
;; 	load	(r14+SPRITE_ANIM_ARRAY/4),r11
;; 	shlq	#17,r3		; get INDEX
;; 	shrq	#14,r3		; INDEX<<3
;; 	add	r3,r11
;; 	load	(r11),r3	; get DATA
;; 	jr	.ok_sprite1_data
;; .no_sprite1_anim:
;;  	load	(r14+SPRITE_Y/4),r4 ; !! get Y|X !! **instead of nop**
;; 	load	(r14+SPRITE_DATA/4),r3 ; get DATA
;; .ok_sprite1_data:
;; 	btst	#SPRITE_ANIM_ON_OFF,r21
;; 	jr	eq,.no_sprite2_anim
;; 	load	(r15+(SPRITE_SND_PHRASE+4)/4),r22
;; .sprite2_anim:
;; 	load	(r15+SPRITE_ANIM_DATA/4),r23
;; 	load	(r15+SPRITE_ANIM_ARRAY/4),r11
;; 	shlq	#17,r23		; get INDEX
;; 	shrq	#14,r23		; INDEX<<3
;; 	add	r23,r11
;; 	load	(r11),r23	; get DATA
;; 	jr	.ok_sprite2_data
;; .no_sprite2_anim:
;;  	load	(r15+SPRITE_Y/4),r24 ; !! get Y|X !! **instead of nop**
;; 	load	(r15+SPRITE_DATA/4),r23 ; get DATA
;; .ok_sprite2_data:
	move	r4,r5
	shlq	#16,r4
	sharq	#16,r5		; Y1
	sharq	#16,r4		; X1
	move	r24,r25
	shlq	#16,r24
	sharq	#16,r25		; Y2
	sharq	#16,r24		; X2
	;; here we have to adjust coordinates wrt hotpot
	;; remember that we treat NEITHER scaled sprites NOR reflected ones !!
	;; (this explains why this part is simplified)
	btst	#SPRITE_USE_HOTSPOT,r1
	jr	eq,.ok_sprite1_coords
	nop
	load	(r14+SPRITE_HY/4),r6 ; load HY|HX
	move	r6,r7
	sharq	#16,r6		; HY
	shlq	#16,r7		; to get HX
	sub	r6,r5		; Y -= HY
	sharq	#16,r7		; HX
	sub	r7,r4		; X -= HX
.ok_sprite1_coords:
	btst	#SPRITE_USE_HOTSPOT,r21
	jr	eq,.ok_sprite2_coords
	nop
	load	(r15+SPRITE_HY/4),r26 ; load HY|HX
	move	r26,r27
	shlq	#16,r27		; to get HX
	sharq	#16,r26		; HY
	sharq	#16,r27		; HX
	sub	r26,r25		; Y -= HY
	sub	r27,r24		; X -= HX
.ok_sprite2_coords:	
	;; r1, r2 is snd phrase of SPRITE1
	;; r3 is DATA1
	;; r4,r5 is X1,Y1
	;; r21, r22 is snd phrase of SPRITE2
	;; r23 is DATA2
	;; r24,r25 is X2,Y2
	shlq	#26,r1
	shlq	#26,r21
	move	r2,r6
	move	r22,r26
	shrq	#18,r2
	shrq	#18,r22
	shlq	#22,r6
	shlq	#22,r26
	shrq	#22,r1
	shrq	#22,r21
	shrq	#22,r6		; HEIGHT1
	shrq	#22,r26		; HEIGHT2
	move	r2,r11
	move	r22,r12
	shrq	#10,r2
	shrq	#10,r22
	shlq	#22,r11		; DWIDTH1 << 22
	shlq	#22,r12		; DWIDTH2 << 22
	shrq	#22,r11		; DWIDTH1
	shrq	#22,r12		; DWIDTH2
	or	r2,r1		; IWIDTH1
	or	r22,r21		; IWIDTH2
	shlq	#2,r1		; IWIDTH1 in words = pixels
	shlq	#2,r21		; IWIDTH2 in words = pixels
	;; r1 is IWIDTH1 (16 bit pixels) hence is W1
	;; r21 is IWIDTH2 (16 bit pixels) hence is W2
	;; r11 is DWIDTH1
	;; r12 is DWIDTH2
	;; r6 is HEIGHT1
	;; r26 is HEIGHT2
	movei	#.gpu_collision_return-.gpu_collision_begin,r19
	moveq	#0,r20		; no collision
	add	r16,r19		; relocate
	move	r6,r7		; save H1
	move	r26,r27		; save H2
	add	r5,r7		; Y1+H1
	add	r25,r27		; Y2+H2
	sub	r5,r27		; if Y2+H2 - Y1 < 0 then no collision
	jump	mi,(r19)
	sub	r25,r7		; if Y1+H1 - Y2 < 0 then no collision
	jump	mi,(r19)
	sub	r5,r25		; Y2-Y1
	jr	pl,.y1_le_y2
	move	r1,r8		; save W1
.y1_gt_y2:
	;; Y2 - Y1 < 0
	abs	r25
	move	r25,r17
	mult	r12,r25		; |Y2-Y1| * DWIDTH2
	shlq	#16,r17
	shlq	#3,r25		; offset Y
	cmp	r6,r27		; get min(h1,y2+h2-y1)
	jr	mi,.min_h1_done
	add	r25,r23		; add offset Y to DATA2
	move	r6,r27		; height of intersection
.min_h1_done:
	subq	#1,r27
	jump	mi,(r19)	; if HEIGHT = 0 then no collision
	or	r27,r17
	jr	.y_done
	move	r21,r28		; save W2
.y1_le_y2:
	;; Y2 - Y1 >= 0
	bset	#COLLISION_Y1_LE_Y2,r20
	move	r25,r17
	mult	r2,r25		; |Y2-Y1| * DWIDTH1
	shlq	#16,r17
	shlq	#3,r25		; offset Y
	cmp	r26,r7		; get min(h2,y1+h1-y2)
	jr	mi,.min_h2_done
	add	r25,r3		; add offset Y to DATA1
	move	r26,r7
.min_h2_done:
	subq	#1,r7
	jump	mi,(r19)	; if HEIGHT = 0 then no collision
	or	r7,r17
	move	r21,r28
.y_done:
	;; 
	add	r4,r8		; X1+W1
	add	r24,r28		; X2+W2
	sub	r4,r28
	jump	mi,(r19)	; if X2+W2 - X1 < 0 then no collision
	sub	r24,r8
	jump	mi,(r19)	; if X1+W1 - X2 < 0 then no collision
	sub	r4,r24		; X2-X1
	jr	pl,.x1_le_x2
	nop
.x1_gt_x2:
	;; X2 - X1 < 0
	abs	r24
	move	r24,r18
	shlq	#1,r24		; offset X
	shlq	#16,r18
	cmp	r1,r28		; get min(w1,x2+w2-x1)
	jr	mi,.min_w1_done
	add	r24,r23		; add offset X to DATA2
	move	r1,r28		; width of the intersection
.min_w1_done:
	subq	#1,r28
	jump	mi,(r19)	; if WIDTH = 0 then no collision
	or	r28,r18
	jr	.x_done
	nop
.x1_le_x2:
	;; X2 - X1 >= 0
	bset	#COLLISION_X1_LE_X2,r20
	move	r24,r18
	shlq	#1,r24		; offset X
	shlq	#16,r18
	cmp	r21,r8		; get min(w2,x1+w1-x2)
	jr	mi,.min_w2_done
	add	r24,r3		; add offset X to DATA1
	move	r21,r8
.min_w2_done:
	subq	#1,r8
	jump	mi,(r19)	; if WIDTH = 0 then no collision
	or	r8,r18
.x_done:
	;; write Y coords
	subq	#8,r0		; to write Y|H coords
	bset	#COLLISION_INTERSECT,r20
	store	r17,(r0)
	addq	#4,r0		; to write X|W coords
	;; write X coords
	store	r18,(r0)
	addq	#4,r0
	;; 
	;; lower word of r17 contains height-1
	;; lower word of r18 contains width-1
	;; r3 is DATA1 address offset
	;; r23 is DATA2 address offset
	;; at this point, we need to compute DATA base address
	btst	#SPRITE_ANIM_ON_OFF,r9
	jr	eq,.no_sprite1_anim
	shlq	#16,r18		; instead of nop
.sprite1_anim:
	load	(r14+SPRITE_ANIM_DATA/4),r8
	load	(r14+SPRITE_ANIM_ARRAY/4),r9
	shlq	#17,r8		; INDEX<<17
	shrq	#14,r8		; INDEX<<3 (one phrase per anim chunck)
	add	r8,r9
	jr	.ok_sprite1_data
	load	(r9),r9		; DATA
.no_sprite1_anim:
	load	(r14+SPRITE_DATA/4),r9
.ok_sprite1_data:
	btst	#SPRITE_ANIM_ON_OFF,r10
	jr	eq,.no_sprite2_anim
	shlq	#16,r17		; instead of nop
.sprite2_anim:
	load	(r15+SPRITE_ANIM_DATA/4),r8
	load	(r15+SPRITE_ANIM_ARRAY/4),r10
	shlq	#17,r8		; INDEX<<17
	shrq	#14,r8		; INDEX<<3 (one phrase per anim chunck)
	add	r8,r10
	jr	.ok_sprite1_data
	load	(r10),r10	; DATA
.no_sprite2_anim:
	load	(r15+SPRITE_DATA/4),r10
.ok_sprite2_data:
	add	r9,r3		; DATA1
	add	r10,r23		; DATA2
	;; DATA computed now
;; 	shlq	#16,r18		; done above instead of nop
;; 	shlq	#16,r17		; done above instead of nop
	shrq	#16,r18
	shrq	#16,r17
	addq	#1,r18
	shlq	#3,r11		; DWIDTH1 in bytes
	shlq	#1,r18		; bytes per line
	shlq	#3,r12		; DWIDTH2 in bytes
	sub	r18,r11		; offset1 (to reach next line)
	sub	r18,r12		; offset2 (to reach next line)
.gpu_collision_test:
	move	r18,r19		; width (in bytes)
.gpu_collision_test_line:
	loadw	(r3),r10
	cmpq	#0,r10		; is it transparent?
	jr	eq,.gpu_collision_test_skip
	addq	#2,r3		; instead of a nop
	loadw	(r23),r10
	cmpq	#0,r10
	jr	ne,.gpu_collision_collide
.gpu_collision_test_skip:
	addq	#2,r23		; instead of nop
	subq	#2,r19
	jr	ne,.gpu_collision_test_line
	nop
	add	r11,r3
	add	r12,r23
	subq	#1,r17
	jr	pl,.gpu_collision_test
	nop
	jr	.gpu_collision_return
	nop
.gpu_collision_collide:
	bset	#COLLISION_COLLIDE,r20
.gpu_collision_return:
	store	r20,(r0)
	;; return from sub routine
	load	(r31),r0
	jump	(r0)
	addq	#4,r31
	.long
.gpu_collision_params:
	dc.l	0
	dc.l	0
	dc.l	0
	.long
.gpu_collision_end:

COLLISION_ROUTINE_SIZE	equ	.gpu_collision_end-.gpu_collision_begin
COLLISION_PARAMS	equ	.gpu_collision_params-.gpu_collision_begin

; GPU_COLLISION_SPRITE1		equ	.gpu_collision_params-.gpu_collision_begin
; GPU_COLLISION_SPRITE2		equ	.gpu_collision_params+4-.gpu_collision_begin
; GPU_COLLISION_RESULT		equ	.gpu_collision_params+8-.gpu_collision_begin
; GPU_COLLISION_COORDS		equ	.gpu_collision_params-.gpu_collision_begin
	
	.print	"Collision routine code size: ",COLLISION_ROUTINE_SIZE

	.68000
	.text

	.globl	_launch_collision_test
;;; void launch_collision_test(sprite *s1, sprite *s2);
_launch_collision_test:
	move.l	collision_address,a0
	lea	COLLISION_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),(a1)+
	move.l	#$80000000,(a1)+
	jsr_gpu	a0
	rts

	.globl	_is_collision_done
;;; long is_collision_done();
_is_collision_done:
	move.l	collision_address,a0
	move.l	COLLISION_PARAMS+8(a0),d0
	rts

	.globl	_get_collision_result
;;; long get_collision_result(short int *y, short int *h, short int *x, short int *w)
_get_collision_result:
	move.l	a2,-(sp)
	move.l	collision_address,a0
	movem.l	4+4(sp),a1-a2
	lea	COLLISION_PARAMS+8(a0),a0
.wait:
	move.l	(a0),d0
	bmi.s	.wait
	subq.w	#8,a0
	move.l	(a0)+,d1
	move.w	d1,(a2)		; H
	swap	d1
	move.w	d1,(a1)		; Y
	move.l	(a0),d1
	movem.l	4+12(sp),a1-a2
	move.w	d1,(a2)		; W
	swap	d1
	move.w	d1,(a1)		; X
	move.l	(sp)+,a2
	rts

	.extern	_bcopy
	.globl	_init_collision_routine
;;; void *init_collision_routine(void *addr)
_init_collision_routine:
	pea	COLLISION_ROUTINE_SIZE
	move.l	4+4(sp),-(sp)
	pea	display_collision_routine	
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),d0
	move.l	d0,collision_address
	add.l	#COLLISION_ROUTINE_SIZE,d0
	rts

	.data
	.even
	dc.b	"Collision Routine by Seb/The Removers"
	.even

	.bss
	.long
collision_address:
	ds.l	1


