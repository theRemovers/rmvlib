; The Removers'Library 
; Copyright (C) 2006-2008 Seb/The Removers
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
	include	"../screen/screen_def.s"

NB_PARAMS	equ	3
	
	.include	"../risc.s"
	
	.include	"../routine.s"

	.include	"render_def.s"

	.macro	compute_values
	;; input
	;; \1 = inv_dw (>= 0)
	;; \2 = frac (>= 0)
	;; \3 = v1
	;; \4 = v2
	;; \5, \6, \7 = temporary registers
	;; \8 = return address (31 bits)
	;; output
	;; \1, \2 unchanged
	;; \3 = v1 + dv * frac
	;; \4 = dv = (v2 - v1) * inv_dw
	sub	\3,\4		; v2-v1
	move	\1,\5
	abs	\4		; |v2-v1|
	addc	\8,\8		; bit 0 is sign of (v2-v1)
	move	\4,\6
	shrq	#16,\5		; int(inv_dw)
	move	\4,\7
	shrq	#16,\6		; int(|v2-v1|)
	mult	\5,\7		; int(inv_dw)*frac(|v2-v1|)
	move	\4,\5
	mult	\1,\6		; frac(inv_dw)*int(|v2-v1|)
	mult	\1,\5		; frac(inv_dw)*frac(|v2-v1|)
	rorq	#16,\1
	rorq	#16,\4
	shrq	#16,\5		; frac(inv_dw)*frac(|v2-v1|)>>16
	mult	\1,\4		; int(inv_dw)*int(|v2-v1|)<<16
	add	\7,\6		; int(inv_dw)*frac(|v2-v1|)+frac(inv_dw)*int(|v2-v1|)
	shlq	#16,\4
	rorq	#16,\1		; restore inv_dw
	add	\6,\4		; int(inv_dw)*int(|v2-v1|)<<16+int(inv_dw)*frac(|v2-v1|)+frac(inv_dw)*int(|v2-v1|)
	move	\2,\6
	add	\5,\4		; |v2-v1|*inv_dw = |dv|
	move	\2,\5
	mult	\4,\6		; frac(|dv|)*frac(frac)
	shrq	#16,\5		; int(frac)
	move	\2,\7
	mult	\4,\5		; frac(|dv|)*int(frac)
	rorq	#16,\4
	mult	\4,\7		; int(|dv|)*frac(frac)
	rorq	#16,\2
	add	\7,\5		; int(|dv|)*frac(frac)+frac(|dv|)*int(frac)
	move	\2,\7
	rorq	#16,\2		; restore frac
	mult	\4,\7		; int(|dv|)*int(frac)
	rorq	#16,\4		; restore |dv|
	shlq	#16,\7
	shrq	#16,\6		; frac(|dv|)*frac(frac)>>16
	add	\5,\7		; int(|dv|)*frac(frac)+frac(|dv|)*int(frac)+int(|dv|)*int(frac)
	shrq	#1,\8		; test sign and restore return address
	jr	cc,.pos\~
	add	\7,\6		; |dv|*frac
	neg	\4		; dv = -|dv|
	neg	\6		; dv*frac = -|dv|*frac
.pos\~:
	jump	(\8)		; return
	add	\6,\3		; v1+dv*frac
	.endm
	
	.text

	.phrase
renderer:
	.gpu
	.org	0
.renderer_begin:
.render_polygon:
	move	PC,r0		; to relocate
	movei	#.renderer_params+4-.render_polygon,r1
	add	r0,r1		; relocate
	load	(r1),r14	; polygon list (not null)
	subq	#4,r1
	load	(r1),r15	; target screen
	movei	#A2_BASE,r1
	load	(r15+(SCREEN_DATA/4)),r2 ; screen address
	load	(r15+(SCREEN_FLAGS/4)),r3 ; flags
	store	r2,(r1)			  ; A2_BASE
	addq	#A2_FLAGS-A2_BASE,r1
	store	r3,(r1)
	movei	#1<<15,r20	; 1/2
	movei	#1<<16,r21	; 1
	movei	#$ffff0000,r22	; mask to get integer part
.render_one_polygon:
	movei	#.render_next_polygon-.render_polygon,r1
	load	(r14+(POLY_FLAGS/4)),r2		; load flags and size
	add	r0,r1
	moveq	#VERTEX_SIZEOF,r8
	addq	#POLY_VERTICES,r14
	mult	r2,r8		
	shrq	#16,r2		; flags
	move	r8,r3		; size of array in bytes
	subq	#VERTEX_SIZEOF,r8 ; i = n-1 (last index)
	jr	.update_ymin
.search_ymin:
	load	(r14+r8),r7	; y (initialise y_min at first step)
	cmp	r4,r7		; compare y to y_min
	jr	pl,.loop_ymin
	nop
.update_ymin:
	move	r8,r5		; i_min = i 
	move	r7,r4		; y_min = y 
.loop_ymin:
	subq	#VERTEX_SIZEOF,r8 ; previous vertex 
	jr	pl,.search_ymin	; finished?
	move	r5,r6
	;; r2 = flags
	;; r3 = size of array in bytes
	;; r4 = y_min
	;; r5 = i_min = left index
	;; r6 = i_min = right index
	subq	#1,r4		;
	movei	#.render_incrementalize-.render_polygon,r17
	movei	#.get_left_edge-.render_polygon,r18
	movei	#.ok_left_edge-.render_polygon,r19
	add	r0,r17		; relocate .render_incrementalize
	add	r20,r4		; y_min+1/2-1/65536
	add	r0,r18		; relocate .get_left_edge
	and	r22,r4		; r4 = ceil(y_min - 1/2)
				; = (y_min+1/2-1/65536) & 0xffff0000
	add	r0,r19		; relocate .ok_left_edge
	move	r4,r7		; left_y
	move	r4,r8		; right_y
	;; r7 = left_y
	;; r8 = right_y
.get_left_edge:
	cmp	r7,r4		; left_y > y
	jump	mi,(r19)	; yes -> .ok_left_edge
	move	r5,r16		   ; save left index
	subq	#VERTEX_SIZEOF,r5  ; li--
	jr	pl,.ok_left_index  ; li >= 0 ?
	nop
	add	r3,r5		; li < 0 (ie li = -1) -> li = n-1
.ok_left_index:
	load	(r14+r5),r28	; y(new_li)	
	load	(r14+r16),r27	; y(old_li)
	move	r28,r7		; left_y = y(new_li)
	sub	r27,r28		; y(new_li)-y(old_li)
	jump	mi,(r1)		; -> .render_next_polygon
	move	r4,r24		; y
	jr	ne,.ok_left_dy
	add	r20,r24		; y+1/2
	move	r21,r28		; dy = 1
.ok_left_dy:
	move	r21,r23		; 1
	sub	r27,r24		; frac = y+1/2-y(old_li)
	div	r28,r23		; 1/dy
	add	r20,r7		; left_y = y(new_li) + 1/2
	addq	#VERTEX_X-VERTEX_Y,r14
	and	r22,r7		; left_y = floor(y(new_li)+1/2)
	load	(r14+r16),r25	; x(old_li)
	load	(r14+r5),r26	; x(new_li)
	subq	#VERTEX_X-VERTEX_Y,r14
	fast_jsr	r17,r30	; jsr .render_incrementalize
	move	r25,r9		; left_x
	jump	(r18)		; -> .get_left_edge
	move	r26,r10		; left_dx
	;; r9 = left_x
	;; r10 = left_dx
.ok_left_edge:
	movei	#.get_right_edge-.render_polygon,r18
	movei	#.ok_right_edge-.render_polygon,r19
	add	r0,r18		; relocate .get_right_edge
	add	r0,r19		; relocate .ok_right_edge
.get_right_edge:
	cmp	r8,r4		; right_y > y
	jump	mi,(r19)	; yes -> .ok_right_edge
	move	r6,r16		   ; save right index
	addq	#VERTEX_SIZEOF,r6  ; ri++
	cmp	r3,r6
	jr	ne,.ok_right_index  ; ri >= n ?
	nop
	moveq	#0,r6		; ri = 0
.ok_right_index:
	load	(r14+r6),r28	; y(new_li)	
	load	(r14+r16),r27	; y(old_li)
	move	r28,r8		; right_y = y(new_li)
	sub	r27,r28		; y(new_li)-y(old_li)
	jump	mi,(r1)		; -> .render_next_polygon
	move	r4,r24		; y
	jr	ne,.ok_right_dy
	add	r20,r24		; y+1/2
	move	r21,r28		; dy = 1
.ok_right_dy:
	move	r21,r23		; 1
	sub	r27,r24		; frac = y+1/2-y(old_li)
	div	r28,r23		; 1/dy
	add	r20,r8		; right_y = y(new_li) + 1/2
	addq	#VERTEX_X-VERTEX_Y,r14
	and	r22,r8		; right_y = floor(y(new_li)+1/2)
	load	(r14+r16),r25	; x(old_li)
	load	(r14+r6),r26	; x(new_li)
	subq	#VERTEX_X-VERTEX_Y,r14
	fast_jsr	r17,r30	; jsr .render_incrementalize
	move	r25,r11		; right_x
	jump	(r18)		; -> .get_left_edge
	move	r26,r12		; right_dx
	;; r11 = right_x
	;; r12 = right_dx
.ok_right_edge:
	movei	#_render_trace,r15
	store	r4,(r15)	; y
	store	r7,(r15+1)	; left_y
	store	r9,(r15+2)	; left_x
	store	r10,(r15+3)	; left_dx
	store	r8,(r15+4)	; right_y
	store	r11,(r15+5)	; right_x
	store	r12,(r15+6)	; right_dx
	;; next polygon
.render_next_polygon:
	subq	#POLY_VERTICES,r14
	movei	#.render_one_polygon-.render_polygon,r1
	load	(r14),r14
	add	r0,r1
	cmpq	#0,r14
	jump	ne,(r1)
	nop
	;; done
	;; return from sub routine and clear mutex
	movei	#.renderer_params+8-.renderer_begin,r1	
	moveq	#0,r2
	add	r0,r1
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
.render_incrementalize:
	;; input
	;; r23 = 1/dw
	;; r24 = frac
	;; r25 = v1
	;; r26 = v2
	;; r30 = return address (31 bits)
	;; output
	;; r23, r24, r30 unchanged
	;; r25 = v1 + frac*dv
	;; r26 = dv = (v2-v1)*1/dw
	compute_values	r23,r24,r25,r26,r27,r28,r29,r30
	.long
.renderer_params:
	.rept	NB_PARAMS
	dc.l	0
	.endr
	.long
.renderer_end:	

RENDERER_SIZE	equ	.renderer_end-.renderer_begin
RENDERER_RENDER	equ	.render_polygon-.renderer_begin	
RENDERER_PARAMS equ	.renderer_params-.renderer_begin
	
	.print	"Renderer routine size: ", RENDERER_SIZE
	.print	"Render: ",RENDERER_RENDER

	.68000
	.text
	
	.extern _bcopy
	.globl  _init_renderer

;;; void *init_renderer(void *gpu_addr);
_init_renderer:
	pea	RENDERER_SIZE
	move.l	4+4(sp),-(sp)
	pea	renderer
	jsr	_bcopy
	lea	12(sp),sp
	move.l	4(sp),d0
	move.l	d0,renderer_gpu_address
	add.l	#RENDERER_SIZE,d0
	rts

	.globl	_render_polygon
;;; void render_polygon(screen *target, polygon *p)
_render_polygon:
	move.l	renderer_gpu_address,a0
	lea	RENDERER_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),(a1)+
	move.l	#$80000000,(a1)
	lea	RENDERER_RENDER(a0),a1
	jsr_gpu	a1
	lea	RENDERER_PARAMS+8(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	rts
	
	.data
	.phrase
	dc.b	'Software Renderer by Seb/The Removers'
	.phrase

	.bss
	.long
renderer_gpu_address:
	ds.l	1

	.long
	.globl	_render_trace
_render_trace:
	ds.l	7
