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
	
	.include	"../routine.s"

	.include	"render_def.s"
	
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
	load	(r14+(POLY_FLAGS/4)),r2		; load flags and size
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
	add	r20,r4		; y_min+1/2-1/65536
	and	r22,r4		; r4 = ceil(y_min - 1/2)
				; = (y_min+1/2-1/65536) & 0xffff0000 
	move	r4,r7		; left_y
	move	r4,r8		; right_y
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
