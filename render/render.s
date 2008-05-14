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

XADDPIX_BIT	equ	16
XADDINC_BIT	equ	17
	
OPT_FLAT	equ	1
	
	.include	"../risc.s"
	
	.include	"../routine.s"

	.include	"render_def.s"

	.macro	wait_blitter_gpu
	;; beware, the instruction that will follow
	;; is executed after each loop
	;; \1: base register (r14 or r15) set to A1_BASE
	;; \2: temporary register
.gwait_\~:
	load	(\1+((B_CMD-A1_BASE)/4)),\2
	btst	#0,\2
	jr	eq,.gwait_\~
	.print	"beware of GPU pipeline after jr"
	.endm

	
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

	;; the following code assume that DIV_OFFSET is set
	;; (ie that divisions are operating in 16.16 mode)

	;; it should be loaded on a phrase boundary in GPU ram
	;; (the texture buffer should be correctly aligned)
	.phrase
renderer:
	.gpu
	.org	0
.renderer_begin:
.render_polygon:
	;; 
	;; register allocation for alternative bank
	;; 
	;; r0: left i
	;; r1: left di
	;; r2: right i
	;; r3: right di
	;; r4: left z
	;; r5: left dz
	;; r6: right z
	;; r7: right dz
	;; r8: left u
	;; r9: left du
	;; r10: left v
	;; r11: left dv
	;; r12: right u
	;; r13: right du
	;; r14: right v
	;; r15: right dv
	;; r16: render inner loop address
	;; r17: dest base address
	;; r18: dest blitter flags (phrase mode)
	;; r19: texture base address
	;; r20: texture blitter flags (increment mode)
	;; r21: texture clipping window (h|w)
	;; r24, r25, r26, r27: temporary registers
	;; 
	;; register allocation for current bank
	;; 
	;; r0: .render_polygon (to relocate)
	;; r1: temporary register
	;; r2: flags of current polygon
	;; r3: size of current polygon
	;; r4: y
	;; r5: left index
	;; r6: right index
	;; r7: left y
	;; r8: right y
	;; r9: left x
	;; r10: left dx
	;; r11: right x
	;; r12: right dx
	;; r13: temporary register
	;; r14: polygon
	;; r15: A1_BASE
	;; r16: temporary register & inner loop render routine address
	;; r17: .render_incrementalize
	;; r18: temporary register
	;; r19: temporary register
	;; r20: 1/2 (half_one)
	;; r21: 1 (one)
	;; r22: $ffff0000 (to compute ceil and floor, and mask values)
	;; r23-r30: used by .render_incrementalize or temporary registers
	move	PC,r0		; to relocate
	movei	#.renderer_params-.render_polygon,r1
	movei	#.render_incrementalize-.render_polygon,r17
	add	r0,r1		; relocate .renderer_params
	add	r0,r17		; relocate .render_incrementalize
	load	(r1),r15	; target screen
	addq	#4,r1
	load	(r1),r14	; polygon list (not null)
	load	(r15+(SCREEN_DATA/4)),r2 ; screen address
	load	(r15+(SCREEN_FLAGS/4)),r3 ; flags
	movei	#A1_BASE,r15
	moveta	r2,r17					; dest base address
	store	r2,(r15+((A2_BASE-A1_BASE)/4))	  	; A2_BASE
	moveta	r3,r18					; dest blitter flags (phrase mode)
	movei	#1<<15,r20	; 1/2
	movei	#1<<16,r21	; 1
	movei	#$ffff0000,r22	; mask to get integer part
.render_one_polygon:
	load	(r14+(POLY_FLAGS/4)),r2		; load flags and size
	moveq	#VERTEX_SIZEOF,r8
	movei	#.render_next_polygon-.render_polygon,r1
	mult	r2,r8
	add	r0,r1		; relocate .render_next_polygon
	shrq	#16,r2		; flags
	moveq	#$7,r3
	load	(r14+(POLY_PARAM/4)),r9 ; load poly param
	and	r3,r2			; mask flags
	movei	#.render_table-.render_polygon,r29
	move	r8,r3		; size of array in bytes
	add	r0,r29		; relocate .render_table
	shlq	#2,r2		; flags*4
	addq	#POLY_VERTICES,r14
	add	r2,r29
	shrq	#2,r2			; flags
	load	(r29),r29
	subq	#VERTEX_SIZEOF,r8	; i = n-1 (last index)
	add	r0,r29			; relocate
	moveq	#0,r10			; to check that polygon is not an horizontal line (otherwise, infinite loop afterwards!)
	moveta	r29,r16		; render inner loop
	jr	.update_ymin
.search_ymin:
	load	(r14+r8),r7	; y (initialise y_min at first step)
	cmp	r4,r7		; compare y to y_min
	jr	eq,.loop_ymin
	nop
	jr	pl,.loop_ymin
	moveq	#1,r10		; here, we are sure that polygon is not an horizontal line
.update_ymin:
	move	r8,r5		; i_min = i 
	move	r7,r4		; y_min = y 
.loop_ymin:
	subq	#VERTEX_SIZEOF,r8 ; previous vertex 
	jr	pl,.search_ymin	; finished?
	move	r5,r6
	cmpq	#0,r10		; is it an horizontal line?
	jump	eq,(r1)		; next_polygon
	;; r2 = flags
	;; r3 = size of array in bytes
	;; r4 = y_min
	;; r5 = i_min = left index
	;; r6 = i_min = right index
	subq	#1,r4		;
	move	r14,r13		; to read texture info
	add	r20,r4		; y_min+1/2-1/65536
	subq	#POLY_VERTICES-POLY_TEXTURE,r13	; pointer on texture param
	and	r22,r4		; r4 = ceil(y_min - 1/2)
				; = (y_min + 1/2 - 1/65536) & 0xffff0000
	movei	#.phrase_mode-.render_polygon,r10
	move	r4,r7		; left_y
	add	r0,r10		; relocate .phrase_mode
	wait_blitter_gpu	r15,r29
	btst	#TXTMAPPING,r2	; texture? (executed during wait loop)
	jump	eq,(r10)	; -> .phrase_mode
	move	r4,r8		; right_y
.pixel_mode:
	load	(r13),r13			; read texture screen address
	shlq	#8,r9				; clear color part
	load	(r13),r25			; get texture flags
	addq	#SCREEN_H,r13
	bset	#XADDPIX_BIT,r25		; set pixel mode
	load	(r13),r26			; clipping window
	addq	#SCREEN_DATA-SCREEN_H,r13
	bset	#XADDINC_BIT,r25		; set increment mode
	load	(r13),r27			; texture base address
	moveta	r25,r20				; save texture flags
	moveta	r27,r19				; save texture base address
	movei	#.renderer_buffer-.render_polygon,r10
	shrq	#8,r9				; intensity increment
	add	r0,r10				; relocate .render_buffer
	moveta	r26,r21				; save texture window
	store	r9,(r15+((B_IINC-A1_BASE)/4))	; flat source shading increment
	jr	.loop_render
	store	r10,(r15+((A2_BASE-A1_BASE)/4)) ; render buffer
.phrase_mode:
	shlq	#16,r9
	movefa	r17,r29				; dest base address
	move	r9,r10
	movefa	r18,r30				; dest blitter flags (phrase mode)
	shrq	#16,r9
	store	r29,(r15+((A2_BASE-A1_BASE)/4)) ; A2_BASE
	or	r10,r9				; color
	store	r30,(r15+((A2_FLAGS-A1_BASE)/4)) ; A2_FLAGS
	store	r9,(r15+((B_PATD-A1_BASE)/4))	; set color
	store	r9,(r15+((B_PATD+4-A1_BASE)/4))	; set color
	;; r7 = left_y
	;; r8 = right_y
.loop_render:
	movei	#.get_left_edge-.render_polygon,r18
	movei	#.ok_left_edge-.render_polygon,r19
	add	r0,r18		; relocate .get_left_edge
	add	r0,r19		; relocate .ok_left_edge
.get_left_edge:
	cmp	r7,r4		; left_y > y
	jump	mi,(r19)	; yes -> .ok_left_edge
	move	r5,r16		   ; save left index
	subq	#VERTEX_SIZEOF,r5  ; li--
	jr	pl,.ok_left_index  ; li >= 0 ?
	load	(r14+r16),r27	; y(old_li)
	add	r3,r5		; li < 0 (ie li = -1) -> li = n-1
.ok_left_index:
	load	(r14+r5),r28	; y(new_li)	
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
	fast_jsr	r17,r30	; jsr .render_incrementalize
	move	r25,r9		; left_x
	move	r26,r10		; left_dx
	;; 
	.if	OPT_FLAT
	cmpq	#0,r2
	subqt	#VERTEX_X-VERTEX_Y,r14
	jump	eq,(r18)	; -> .get_left_edge
	btst	#GRDSHADING,r2
	jr	eq,.left_skip_gouraud
	addq	#VERTEX_I-VERTEX_Y,r14
	.else
	btst	#GRDSHADING,r2
	jr	eq,.left_skip_gouraud
	addq	#VERTEX_I-VERTEX_X,r14
	.endif
	;; 
	load	(r14+r16),r25	; i(old_li)
	load	(r14+r5),r26	; i(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r0		; left_i
	moveta	r26,r1		; left_di
.left_skip_gouraud:
	btst	#ZBUFFERING,r2
	jr	eq,.left_skip_zbuffer
	addq	#VERTEX_Z-VERTEX_I,r14
	load	(r14+r16),r25	; z(old_li)
	load	(r14+r5),r26	; z(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r4		; left_z
	moveta	r26,r5		; left_dz
.left_skip_zbuffer:
	btst	#TXTMAPPING,r2
	jump	eq,(r18)	; -> .get_left_edge
	subq	#VERTEX_Z-VERTEX_Y,r14
	addq	#VERTEX_U-VERTEX_Y,r14
	load	(r14+r16),r25	; u(old_li)
	load	(r14+r5),r26	; u(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r8		; left_u
	addq	#VERTEX_V-VERTEX_U,r14
	moveta	r26,r9		; left_du
	load	(r14+r16),r25	; v(old_li)
	load	(r14+r5),r26	; v(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r10		; left_v
	moveta	r26,r11		; left_dv
	jump	(r18)		; -> .get_left_edge
	subq	#VERTEX_V-VERTEX_Y,r14
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
	load	(r14+r16),r27	; y(old_li)
	moveq	#0,r6		; ri = 0
.ok_right_index:
	load	(r14+r6),r28	; y(new_li)	
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
	fast_jsr	r17,r30	; jsr .render_incrementalize
	move	r25,r11		; right_x
	move	r26,r12		; right_dx
	;; 
	.if	OPT_FLAT
	cmpq	#0,r2
	subqt	#VERTEX_X-VERTEX_Y,r14
	jump	eq,(r18)	; -> .get_right_edge
	btst	#GRDSHADING,r2
	jr	eq,.right_skip_gouraud
	addq	#VERTEX_I-VERTEX_Y,r14
	.else
	btst	#GRDSHADING,r2
	jr	eq,.right_skip_gouraud
	addq	#VERTEX_I-VERTEX_X,r14
	.endif
	;; 
	load	(r14+r16),r25	; i(old_li)
	load	(r14+r6),r26	; i(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r2		; right_i
	moveta	r26,r3		; right_di
.right_skip_gouraud:
	btst	#ZBUFFERING,r2
	jr	eq,.right_skip_zbuffer
	addq	#VERTEX_Z-VERTEX_I,r14
	load	(r14+r16),r25	; z(old_li)
	load	(r14+r6),r26	; z(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r6		; right_z
	moveta	r26,r7		; right_dz
.right_skip_zbuffer:
	btst	#TXTMAPPING,r2
	jump	eq,(r18)	; -> .get_right_edge
	subq	#VERTEX_Z-VERTEX_Y,r14
	addq	#VERTEX_U-VERTEX_Y,r14
	load	(r14+r16),r25	; u(old_li)
	load	(r14+r6),r26	; u(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r12		; right_u
	addq	#VERTEX_V-VERTEX_U,r14
	moveta	r26,r13		; right_du
	load	(r14+r16),r25	; v(old_li)
	load	(r14+r6),r26	; v(new_li)
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r14		; right_v
	moveta	r26,r15		; right_dv
	jump	(r18)		; -> .get_right_edge
	subq	#VERTEX_V-VERTEX_Y,r14
	;; r11 = right_x
	;; r12 = right_dx
.ok_right_edge:
	movei	#.do_scanlines-.render_polygon,r18
	movei	#.loop_render-.render_polygon,r19
	add	r0,r18		; relocate .do_scanlines
	add	r0,r19		; relocate .loop_render
	movefa	r16,r16		; render inner loop
.do_scanlines:
	cmp	r7,r4		; y < left_y
	jump	pl,(r19)	; no -> .loop_render
	cmp	r8,r4		; y < right_y
	jump	pl,(r19)	; no -> .loop_render
	move	r9,r27		; lx
	move	r11,r28		; rx
	add	r20,r27		; lx+1/2
	sub	r20,r28		; rx-1/2
	subq	#1,r27		; lx+1/2-1/65536
	shrq	#16,r28		; x2 = floor(rx-1/2)
	shrq	#16,r27		; x1 = ceil(lx-1/2) = floor(lx+1/2-1/65536)
	sub	r27,r28		; x2-x1
	jr	pl,.go_hline	; x2-x1 < 0 -> .skip_hline
	addq	#1,r28		; w = x2-x1+1
.skip_hline:
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
.go_hline:
	cmpq	#0,r2		; check flags
	jump	eq,(r16)	; if flat rendering, then skip computation of 1/dx and frac
	or	r4,r27		; y|x1
	move	r11,r29		; rx
	move	r27,r24		; x1>>16
	sub	r9,r29		; dx = rx-lx
	jr	ne,.ok_dx
	shlq	#16,r24		; x1
	move	r21,r29		; 1
.ok_dx:
	add	r20,r24		; x1+1/2
	move	r21,r23		; 1
	sub	r9,r24		; frac = x1+1/2-lx = ceil(lx-1/2)-(lx-1/2)
	div	r29,r23		; 1/dx	
	;; adjust frac
	moveq	#3,r29
	moveq	#3,r30
	and	r27,r29		; x1%4
	sub	r29,r30		; (3-x1)%4
	shlq	#16,r30		; 16.16
	;;
	jump	(r16)		; render line
	add	r30,r24		; adjust frac
	;; next polygon
.render_next_polygon:
	subq	#POLY_VERTICES,r14
	movei	#.render_one_polygon-.render_polygon,r1
	load	(r14),r14
	add	r0,r1		; relocate .render_one_polygon
	cmpq	#0,r14
	jump	ne,(r1)
	nop
	;; done
	;; return from sub routine and clear mutex
	movei	#.renderer_params+8-.render_polygon,r1
	moveq	#0,r2
	add	r0,r1		; relocate .renderer_params+8
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
.flat_rendering:
	;; r27: y|x1 (start of blit)
	;; r28: w (almost width)
	wait_blitter_gpu	r15,r29
	or	r21,r28					; 1|w	(executed during wait loop)
 	movei	#DSTA2|PATDSEL,r29
	store	r27,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
.gouraud_rendering:
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; 
	movefa	r0,r25		; i1
	movefa	r2,r26		; i2
	sat24	r25
	sat24	r26
	movefa	r1,r27		; di1
	movefa	r3,r28		; di2
	add	r25,r27
	add	r26,r28
	moveta	r27,r0		; i1'
	moveta	r28,r2		; i2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	;; 
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set intensities
	moveq	#3,r29
	move	r25,r30
.gouraud_set_intensities:
	sat24	r25
	sub	r26,r30
	subq	#1,r29
	store	r25,(r15+((B_I3-A1_BASE)/4)) ; B_Ix with 1 <= x <= 3
	addqt	#4,r15
	jr	ne,.gouraud_set_intensities
	move	r30,r25
	shlq	#10,r26		; 4 * di
	sat24	r25
	shrq	#8,r26		; clear high bits
	store	r25,(r15+((B_I3-A1_BASE)/4)) ; B_I0
	subq	#12,r15
	;; 
	movei	#DSTA2|PATDSEL|GOURD,r29
	store	r26,(r15+((B_IINC-A1_BASE)/4))		; IINC
	store	r27,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
.texture_mapping:
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;;
	movefa	r8,r25		; u1
	movefa	r12,r26		; u2
	movefa	r9,r27		; du1
	movefa	r13,r28		; du2
	add	r25,r27
	add	r26,r28
	moveta	r27,r8		; u1'
	moveta	r28,r12		; u2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	sub	r26,r25		; u -= du
	sub	r26,r25		; u -= du
	sub	r26,r25		; u -= du
	moveta	r25,r24		; save u
	moveta	r26,r25		; save du
	movefa	r10,r25		; v1
	movefa	r14,r26		; v2
	movefa	r11,r27		; dv1
	movefa	r15,r28		; dv2
	add	r25,r27
	add	r26,r28
	moveta	r27,r10		; v1'
	moveta	r28,r14		; v2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	;; compute A1_PIXEL, A1_FPIXEL, A1_INC, A1_FINC
	sub	r26,r25		; v -= dv
	sub	r26,r25		; v -= dv
	sub	r26,r25		; v -= dv
	move	r25,r27		; save Y
	shlq	#16,r25		; A1_FPIXEL(y)
	and	r22,r27		; A1_PIXEL(y)
	move	r26,r28		; save dY
	shlq	#16,r26		; A1_FINC(y)
	and	r22,r28		; A1_INC(y)
	movefa	r24,r29		; X
	movefa	r25,r30		; dX
	shrq	#16,r29		; A1_PIXEL(x)
	shrq	#16,r30		; A1_INC(x)
	or	r29,r27		; A1_PIXEL
	or	r30,r28		; A1_INC
	movefa	r24,r29		; X
	movefa	r25,r30		; dX
	shlq	#16,r29
	shlq	#16,r30
	shrq	#16,r29		; A1_FPIXEL(x)
	shrq	#16,r30		; A1_FINC(x)
	or	r29,r25		; A1_FPIXEL
	or	r30,r26		; A1_FINC
	;; 
	movefa	r27,r30		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r30		; 1|w (executed during wait loop)
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	store	r25,(r15+((A1_FPIXEL-A1_BASE)/4))	; A1_FPIXEL
	store	r28,(r15+((A1_INC-A1_BASE)/4))		; A1_INC
	store	r26,(r15+((A1_FINC-A1_BASE)/4))		; A1_FINC
	movefa	r19,r25					; texture base address
	movefa	r20,r26					; texture blitter flags
	movefa	r21,r27					; texture clipping window
	store	r25,(r15+((A1_BASE-A1_BASE)/4))		; A1_BASE
	store	r26,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	store	r27,(r15+((A1_CLIP-A1_BASE)/4))		; A1_CLIP
	movefa	r26,r29		; restore y|x1
	moveq	#3,r28
	addq	#1,r30		; w should be even
	and	r29,r28		; x1 % 4 (will be A2_PIXEL next blit)
	moveq	#0,r27		; A2_PIXEL
	add	r28,r30		; 1 | (w + x1 % 4)
	store	r27,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	bclr	#0,r30		; 1 | (w + x1 % 4) [even width]
	movei	#XADDPIX|WID384|PIXEL16|PITCH1,r27	; GPU buffer flags
 	movei	#SRCEN|CLIP_A1|LFU_REPLACE|DSTA2|SRCSHADE|ZBUFF,r26
 	store	r30,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
 	store	r26,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;;
	movefa	r27,r25		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r25		; 1|w (executed during wait loop)
	movefa	r26,r29		; restore y|x1
	bclr	#XADDPIX_BIT,r27			; turn to phrase mode
	store	r28,(r15+((A2_PIXEL-A1_BASE)/4)) 	; A2_PIXEL
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
	store	r25,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r29,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	movefa	r17,r27					; destination base address
	movefa	r18,r28					; destination blitter flags
	moveq	#0,r29
	movei	#SRCEN|LFU_REPLACE,r26
	store	r29,(r15+((A1_CLIP-A1_BASE)/4))		; A1_CLIP workaround
	store	r27,(r15+((A1_BASE-A1_BASE)/4))		; A1_BASE
	store	r28,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	store	r26,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
.flat_zbuffer:
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; 
	movefa	r4,r25		; z1
	movefa	r6,r26		; z2
	movefa	r5,r27		; dz1
	movefa	r7,r28		; dz2
	add	r25,r27
	add	r26,r28
	moveta	r27,r4		; z1'
	moveta	r28,r6		; z2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set z
	addq	#32,r15
	store	r25,(r15+((B_Z3-(A1_BASE+32))/4)) ; Z3
	sub	r26,r25
	store	r25,(r15+((B_Z2-(A1_BASE+32))/4)) ; Z2
	sub	r26,r25
	store	r25,(r15+((B_Z1-(A1_BASE+32))/4)) ; Z1
	sub	r26,r25
	store	r25,(r15+((B_Z0-(A1_BASE+32))/4)) ; Z0
	subq	#32,r15
	shlq	#2,r26		; dz * 4
 	movei	#DSTA2|PATDSEL|ZBUFF|DSTEN|DSTENZ|DSTWRZ|ZMODELT|ZMODEEQ,r29
	store	r26,(r15+((B_ZINC-A1_BASE)/4))		; ZINC
	store	r27,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
.gouraud_zbuffer:
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; compute z
	movefa	r4,r25		; z1
	movefa	r6,r26		; z2
	movefa	r5,r27		; dz1
	movefa	r7,r28		; dz2
	add	r25,r27
	add	r26,r28
	moveta	r27,r4		; z1'
	moveta	r28,r6		; z2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	moveta	r25,r24		; save z
	moveta	r26,r25		; save dz
	;; compute i
	movefa	r0,r25		; i1
	movefa	r2,r26		; i2
	sat24	r25
	sat24	r26
	movefa	r1,r27		; di1
	movefa	r3,r28		; di2
	add	r25,r27
	add	r26,r28
	moveta	r27,r0		; i1'
	moveta	r28,r2		; i2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	;; 
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set intensities
	moveq	#3,r29
	move	r25,r30
.gouraud_zbuffer_set_intensities:
	sat24	r25
	sub	r26,r30
	subq	#1,r29
	store	r25,(r15+((B_I3-A1_BASE)/4)) ; B_Ix with 1 <= x <= 3
	addqt	#4,r15
	jr	ne,.gouraud_zbuffer_set_intensities
	move	r30,r25
	shlq	#10,r26		; 4 * di
	sat24	r25
	shrq	#8,r26		; clear high bits
	store	r25,(r15+((B_I3-A1_BASE)/4)) ; B_I0
	addq	#32-12,r15
	;; set z
	movefa	r24,r25		; restore z
	store	r26,(r15+((B_IINC-(A1_BASE+32))/4))	; IINC
	movefa	r25,r26		; restore dz
	store	r25,(r15+((B_Z3-(A1_BASE+32))/4))
	sub	r26,r25
	store	r25,(r15+((B_Z2-(A1_BASE+32))/4))
	sub	r26,r25
	store	r25,(r15+((B_Z1-(A1_BASE+32))/4))
	sub	r26,r25
	store	r25,(r15+((B_Z0-(A1_BASE+32))/4))
	subq	#32,r15
	shlq	#2,r26		; dz * 4
	;; 
 	movei	#DSTA2|PATDSEL|GOURD|ZBUFF|DSTEN|DSTENZ|DSTWRZ|ZMODELT|ZMODEEQ,r29
	store	r26,(r15+((B_ZINC-A1_BASE)/4))		; ZINC
	store	r27,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
	add	r10,r9		; lx += ldx
	add	r12,r11		; rx += rdx
	jump	(r18)		; -> .do_scanlines
	add	r21,r4		; y++
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
.render_table:
	;; flat
	dc.l	.flat_rendering-.render_polygon
	;; gouraud
	dc.l	.gouraud_rendering-.render_polygon
	;; texture
	dc.l	.texture_mapping-.render_polygon
	;; texture + gouraud (invalid mode)
	dc.l	.texture_mapping-.render_polygon
	;; flat + z
	dc.l	.flat_zbuffer-.render_polygon
	;; gouraud + z
	dc.l	.gouraud_zbuffer-.render_polygon
	;; texture + z
	dc.l	.skip_hline-.render_polygon
	;; texture + gouraud + z (invalid mode)
	dc.l	.skip_hline-.render_polygon
	.long
.renderer_params:
	.rept	NB_PARAMS
	dc.l	0
	.endr
	.phrase
.renderer_buffer:
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
	move.l	4+4(sp),d0	; gpu_addr
	addq.l	#7,d0
	and.w	#$fffc,d0	; align on phrase boundary
	move.l	d0,-(sp)
	move.l	d0,renderer_gpu_address
	pea	renderer
	jsr	_bcopy
	lea	12(sp),sp
	move.l	renderer_gpu_address,d0
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
	wait_blitter	d0
	rts
	
	.data
	.phrase
	dc.b	'Software Renderer by Seb/The Removers'
	.phrase

	.bss
	.long
renderer_gpu_address:
	ds.l	1

