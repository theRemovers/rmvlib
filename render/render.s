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

	include	"jaguar.inc"
	include	"screen_def.inc"

NB_PARAMS	equ	3

DSTWRZ_BIT	equ	5
ZBUFF_BIT	equ	13
SRCSHADE_BIT	equ	30

XADDPIX_BIT	equ	16
XADDINC_BIT	equ	17

OPT_FLAT	equ	1

	;; 1/z condition
ZCOND	equ	ZMODELT|ZMODEEQ	

	;; size of buffer in GPU ram
WIDBUFFER	equ	WID320

	;; clear screen
ENABLE_CLR_SCREEN	equ	1
	
	;; inefficient clipping
TRIVIAL_CLIPPING	equ	1

	.include	"../risc.s"
	
	.include	"../routine.s"

	.include	"render_def.s"

	.macro	wait_blitter_gpu
	;; beware, the instruction that follows
	;; is executed after each loop (GPU pipeline)
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
	move	\1,\5		; copy inv_dw
	abs	\4		; |v2-v1|
	move	\1,\6		; copy inv_dw
	addc	\8,\8		; bit 0 is sign of (v2-v1)
	rorq	#16,\1		; get inv_dw.i
	mult	\4,\5		; |v2-v1|.f * inv_dw.f
	move	\4,\7		; copy |v2-v1|
	mult	\1,\4		; inv_dw.i * |v2-v1|.f
	rorq	#16,\7		; get |v2-v1|.i
	shrq	#16,\5		; |v2-v1|.f * inv_dw.f >> 16
	mult	\7,\6		; |v2-v1|.i * inv_dw.f
	mult	\1,\7		; inv_dw.i * |v2-v1|.i
	add	\6,\4		; |v2-v1|.i * inv_dw.f + inv_dw.i * |v2-v1|.f
	shlq	#16,\7		; inv_dw.i * |v2-v1|.i << 16
	rorq	#16,\1		; restore inv_dw
	add	\5,\7		; inv_dw.i * |v2-v1|.i << 16 + |v2-v1|.f * inv_dw.f >> 16
	move	\2,\5		; copy frac
	add	\7,\4		; |v2-v1| * inv_dw = |dv|
	move	\2,\6		; copy frac
	rorq	#16,\2		; get frac.i
	mult	\4,\5		; |dv|.f * frac.f
	move	\4,\7		; copy |dv|
	rorq	#16,\4		; get |dv|.i
	mult	\2,\7		; frac.i * |dv|.f
	mult	\4,\6		; |dv|.i * frac.f
	shrq	#16,\5		; |dv|.f * frac.f >> 16
	add	\7,\6		; frac.i * |dv|.f + |dv|.i * frac.f
	move	\2,\7		; frac.i
	rorq	#16,\2		; restore frac
	mult	\4,\7		; |dv|.i * frac.i
	rorq	#16,\4		; restore |dv|
	shlq	#16,\7		; |dv|.i * frac.i << 16
	add	\7,\5		; |dv|.i * frac.i << 16 + |dv|.f * frac.f >> 16
	shrq	#1,\8		; check sign of |dv| and restore return address
	jr	cc,.pos\~
	add	\6,\5		; |dv| * frac
	neg	\4		; dv = -|dv|
	jump	(\8)
	sub	\5,\3		; v1 + dv * frac = v1 - |dv| * frac
.pos\~:
	jump	(\8)
	add	\5,\3		; v1 + dv * frac
	.endm
	
	.macro	compute_i
	movefa	r0,r25		; i1
	movefa	r2,r26		; i2
	movefa	r1,r27		; di1
	movefa	r3,r28		; di2
	sat24	r25
	sat24	r26
	add	r25,r27
	add	r26,r28
	moveta	r27,r0		; i1'
	moveta	r28,r2		; i2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	.endm

	.macro	compute_z
	movefa	r4,r25		; z1
	movefa	r6,r26		; z2
	movefa	r5,r27		; dz1
	movefa	r7,r28		; dz2
	add	r25,r27
	add	r26,r28
	moveta	r27,r4		; z1'
	moveta	r28,r6		; z2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	.endm

	.macro	compute_u
	movefa	r8,r25		; u1
	movefa	r12,r26		; u2
	movefa	r9,r27		; du1
	movefa	r13,r28		; du2
	add	r25,r27
	add	r26,r28
	moveta	r27,r8		; u1'
	moveta	r28,r12		; u2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	.endm

	.macro	compute_v
	movefa	r10,r25		; v1
	movefa	r14,r26		; v2
	movefa	r11,r27		; dv1
	movefa	r15,r28		; dv2
	add	r25,r27
	add	r26,r28
	moveta	r27,r10		; v1'
	moveta	r28,r14		; v2'
	fast_jsr	r17,r30	; jsr .render_incrementalize
	.endm

	.macro	fix_gouraud_mode
	;; check whether 4*IINC fits in 24 bits
	;; and whether sat24 is needed or not
	;; \1 is blitter dest flags register (phrase mode)
	;; if \2 then fix according to x1 else assume 0
	;; \3, \4, \5: temporary registers
	move	r26,\3		; copy IINC
	move	r25,\4		; copy I3
	shlq	#10,\3		; check overflow of 4*IINC
	add	r26,\4		; I3+IINC
	shlq	#2,r26		; 4*IINC (theoretical value)
	sharq	#8,\3		; 4*IINC (practical value)
	sub	r26,\4		; I3-3*IINC
	sub	r26,\3		; compare theoretical and practical value of 4*IINC
	or	r25,\4		; (I3-3*IINC) | I3
	shrq	#24,\4		; check overflow in top 8 bits
	sharq	#2,r26		; restore IINC
	or	\4,\3
	movefa	r26,\4		; get y|x1
	jr	eq,.phrase_mode\~
	moveq	#3,\5
.pixel_mode\~:
	.if	\2
	move	PC,\3
	bset	#XADDPIX_BIT,\1	; set pixel mode
	addq	#.fix_mode\~-.pixel_mode\~,\3
	and	\5,\4		; x1 % 4
	add	\4,\3
	sub	\4,\5		; (3 - x1) % 4
	add	\4,\3
	shlq	#16,\5
	jump	(\3)
	sub	\5,r24		; fix frac
	.else
	bset	#XADDPIX_BIT,\1	; set pixel mode
	.endif
.fix_mode\~:
	sub	r26,r25		; x1 % 4 = 0
	sub	r26,r25		; x1 % 4 = 1
	sub	r26,r25		; x1 % 4 = 2
	sat24	r25		; x1 % 4 = 3
.phrase_mode\~:	
	.endm
	
	.macro	set_z_phrase
	;; r15 is A1_BASE+32
	store	r25,(r15+((B_Z3-(A1_BASE+32))/4)) 	; B_Z3
	sub	r26,r25
	store	r25,(r15+((B_Z2-(A1_BASE+32))/4)) 	; B_Z2
	sub	r26,r25
	store	r25,(r15+((B_Z1-(A1_BASE+32))/4)) 	; B_Z1
	sub	r26,r25
	store	r25,(r15+((B_Z0-(A1_BASE+32))/4)) 	; B_Z0
	shlq	#2,r26					; dz * 4	
	store	r26,(r15+((B_ZINC-(A1_BASE+32))/4))	; B_ZINC
	.endm

	.text

	;; the following code assume that DIV_OFFSET is set
	;; (ie that divisions are operating in 16.16 mode)
	;; this code is self-relocatable!
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
	;; r22: texture mapping finish routine
	;; r23: dest clipping window (h|w) (if TRIVIAL_CLIPPING)
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
	;;
	move	PC,r0		; to relocate
	movei	#.renderer_params-.render_polygon,r1
	movei	#.renderer_buffer+7-.render_polygon,r10
	movei	#.render_incrementalize-.render_polygon,r17
	add	r0,r10		; relocate .renderer_buffer+7
	add	r0,r1		; relocate .renderer_params
	shrq	#3,r10
	add	r0,r17		; relocate .render_incrementalize
	shlq	#3,r10		; align on phrase boundary
	load	(r1),r15	; target screen
	addq	#4,r1
	load	(r1),r14	; polygon list (not null)
	load	(r15+(SCREEN_DATA/4)),r2	; screen address
	load	(r15+(SCREEN_FLAGS/4)),r3 	; flags
	.if	TRIVIAL_CLIPPING|ENABLE_CLR_SCREEN
	load	(r15+(SCREEN_H/4)),r4	  	; size of screen 
	.endif
	.if	TRIVIAL_CLIPPING
	moveta	r4,r23				; save size for trivial clipping
	.endif
	movei	#A1_BASE,r15
	moveta	r2,r17				; dest base address
	store	r10,(r15+((A2_BASE-A1_BASE)/4)) ; .renderer_buffer is A2_BASE
	moveta	r3,r18				; dest blitter flags (phrase mode)
	.if	ENABLE_CLR_SCREEN
.chk_clr:
	moveq	#0,r6				; to clear B_PATD, ...
	shrq	#1,r14				; test bit 0
	store	r6,(r15+((A1_CLIP-A1_BASE)/4))	; A1_CLIP workaround
	movei	#PATDSEL|UPDA1,r7
	jr	cs,.clr_screen			; if bit 0 set then clear
	shrq	#1,r14				; test bit 1
	jr	cc,.clr_done			; if bit 1 clear then nothing
	bset	#DSTWRZ_BIT,r7			; else clear also Z
.clr_z_screen:
	;; clear Z-buffered screen
	store	r6,(r15+((B_SRCZ1-A1_BASE)/4)) 		; clear SRCZ1
	store	r6,(r15+((B_SRCZ1+4-A1_BASE)/4))	; clear SRCZ1
.clr_screen:
	;; clear screen
	store	r4,(r15+((B_COUNT-A1_BASE)/4))	; B_COUNT
	shlq	#16,r4				; W<<16
	store	r6,(r15+((B_PATD-A1_BASE)/4))	; clear B_PATD
	neg	r4				; -(W<<16) 
	store	r6,(r15+((B_PATD+4-A1_BASE)/4)) ; clear B_PATD
	shrq	#16,r4				; -W
	store	r6,(r15+((A1_PIXEL-A1_BASE)/4)) ; A1_PIXEL
	bset	#16,r4				; 1|-W
	store	r3,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	store	r2,(r15+((A1_BASE-A1_BASE)/4))	; A1_BASE
	store	r4,(r15+((A1_STEP-A1_BASE)/4)) 	; A1_STEP
	store	r7,(r15+((B_CMD-A1_BASE)/4))   	; B_CMD
.clr_done:
	shlq	#2,r14				; on a long boundary
	.endif
	moveq	#1,r20
	moveq	#1,r21
	moveq	#1,r22
	shlq	#15,r20		; 1<<15 = 1/2 (half_one)
	rorq	#1,r22		; $80000000 (we will copy sign)
	shlq	#16,r21		; 1<<16 = 1 (one)
	sharq	#15,r22		; $ffff0000 (mask to get integer part)
.render_one_polygon:
	load	(r14+(POLY_FLAGS/4)),r2		; load flags and size
	moveq	#VERTEX_SIZEOF,r8
	movei	#.render_next_polygon-.render_polygon,r1
	mult	r2,r8
	add	r0,r1		; relocate .render_next_polygon
	shrq	#16,r2		; flags
	moveq	#$7,r10
	load	(r14+(POLY_PARAM/4)),r9 ; load poly param
	and	r2,r10			; mask flags
	movei	#.render_table-.render_polygon,r29
	shlq	#2,r10		; flags*4
	add	r0,r29		; relocate .render_table
	move	r8,r3		; size of array in bytes
	add	r10,r29
	addq	#POLY_VERTICES,r14
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
	;; r13 will be blit_cmd 
	movefa	r16,r10				; texture mapping finish routine
	movei	#.texture_mapping-.render_polygon,r11
	load	(r13),r13			; read texture screen address
	add	r0,r11				; relocate .texture_mapping
	moveta	r10,r22				; save texture mapping finish routine
	moveta	r11,r16				; texture mapping common routine
	shlq	#8,r9				; clear color part
	load	(r13),r25			; get texture flags
	addq	#SCREEN_H,r13
	bset	#XADDPIX_BIT,r25		; set pixel mode
	load	(r13),r26			; clipping window
	addq	#SCREEN_DATA-SCREEN_H,r13
	bset	#XADDINC_BIT,r25		; set increment mode
	load	(r13),r27			; texture base address
	btst	#GRDSHADING,r2
	movei	#SRCEN|LFU_REPLACE|DSTA2,r13
	jr	ne,.set_cmd_gouraud
	moveta	r25,r20				; save texture flags
.set_cmd_flat:
	btst	#FLTMAPPING,r2
	jr	eq,.set_cmd_ok
	nop
	bset	#SRCSHADE_BIT,r13
	jr	.set_cmd_ok
	bset	#ZBUFF_BIT,r13
.set_cmd_gouraud:
	movei	#SRCEN|DSTA2|DSTEN|ADDDSEL,r13
.set_cmd_ok:
	moveta	r27,r19				; save texture base address
	shrq	#8,r9				; intensity increment
	moveta	r26,r21				; save texture window
	moveq	#0,r10				; no color
	store	r9,(r15+((B_IINC-A1_BASE)/4))	; flat source shading increment
	store	r10,(r15+((B_PATD-A1_BASE)/4))	; set color for gouraud shading
	jr	.loop_render
	store	r10,(r15+((B_PATD+4-A1_BASE)/4)); set color for gouraud shading
.phrase_mode:
	shlq	#16,r9
	movefa	r17,r29				; dest base address
	move	r9,r10
	store	r29,(r15+((A1_BASE-A1_BASE)/4)) ; A1_BASE
	shrq	#16,r9
	movefa	r18,r30				; dest blitter flags (phrase mode)
	or	r10,r9				; color
	store	r30,(r15+((A1_FLAGS-A1_BASE)/4)) ; A1_FLAGS
	moveq	#0,r10
	store	r9,(r15+((B_PATD-A1_BASE)/4))	; set color
	store	r9,(r15+((B_PATD+4-A1_BASE)/4))	; set color
	store	r10,(r15+((A1_CLIP-A1_BASE)/4)) ; A1_CLIP workaround
	;; r7 = left_y
	;; r8 = right_y
.loop_render:
	move	PC,r18
	movei	#.ok_left_edge-.render_polygon,r19
	addq	#.get_left_edge-.loop_render,r18 ; .get_left_edge
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
	sat24	r25
	sat24	r26
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
	move	PC,r18
	movei	#.ok_right_edge-.render_polygon,r19
	addq	#.get_right_edge-.ok_left_edge,r18 ; .get_right_edge
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
	sat24	r25
	sat24	r26
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
	move	PC,r18
	movei	#.loop_render-.render_polygon,r19
	addq	#.next_scanline-.ok_right_edge,r18 ; .next_scanline
	add	r0,r19		; relocate .loop_render
	jr	.do_scanline
	movefa	r16,r16		; render inner loop
.next_scanline:
	add	r10,r9		; lx += ldx
	add	r21,r4		; y++
	add	r12,r11		; rx += rdx
.do_scanline:
	cmp	r7,r4		; y < left_y
	move	r9,r27		; lx
	jump	pl,(r19)	; no -> .loop_render
	cmp	r8,r4		; y < right_y
	move	r11,r28		; rx
	jump	pl,(r19)	; no -> .loop_render
	add	r20,r27		; lx+1/2
	sub	r20,r28		; rx-1/2
	subq	#1,r27		; lx+1/2-1/65536
	sharq	#16,r28		; x2 = floor(rx-1/2)
	sharq	#16,r27		; x1 = ceil(lx-1/2) = floor(lx+1/2-1/65536)
	.if	TRIVIAL_CLIPPING
	jr	pl,.ok_x1
	movefa	r23,r29		; get screen size
	moveq	#0,r27		; x1 = 0
.ok_x1:
	move	r29,r30
	shlq	#16,r29
	shrq	#16,r30		; height
	shrq	#16,r29		; width
	shlq	#16,r30		; height << 16
	cmp	r29,r28		; compare x2 to width
	jr	mi,.ok_x2
	cmpq	#0,r4		; check y
	move	r29,r28
	subq	#1,r28		; x2 = width-1
.ok_x2:
	jr	mi,.skip_hline	; y < 0
	cmp	r30,r4		; compare y to height
	jump	pl,(r1)		; if y >= h -> .render_next_polygon
	.endif
	sub	r27,r28		; x2-x1
	addqt	#1,r28		; w = x2-x1+1	
	.if	!TRIVIAL_CLIPPING
	jump	mi,(r18)	; x2-x1 < 0 -> .next_scanline
	cmpq	#0,r2		; check flags (instead of nop)
	.else
	jr	pl,.go_hline	; x2-x1 < 0 -> .skip_hline
	cmpq	#0,r2		; check flags (instead of nop)
.skip_hline:
	;; very inefficient clipping when y < 0
	;; update i
	movei	#.skip_hline_clipping-.render_polygon,r30
	movefa	r0,r25		; i1
	add	r0,r30
	movefa	r2,r26		; i2
	sat24	r25
	sat24	r26
	movefa	r1,r27		; di1
	jump	(r30)
	movefa	r3,r28		; di2
	.endif
.go_hline:
*	cmpq	#0,r2		; check flags (done above)
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
	.if	TRIVIAL_CLIPPING
.skip_hline_clipping:
	;; very inefficient clipping when y < 0
	;; finish to update i 
	add	r25,r27
	add	r26,r28
	moveta	r27,r0		; i1'
	moveta	r28,r2		; i2'
	;; update z
	movefa	r4,r25		; z1
	movefa	r6,r26		; z2
	movefa	r5,r27		; dz1
	movefa	r7,r28		; dz2
	add	r25,r27
	add	r26,r28
	moveta	r27,r4		; z1'
	moveta	r28,r6		; z2'
	;; update u
	movefa	r8,r25		; u1
	movefa	r12,r26		; u2
	movefa	r9,r27		; du1
	movefa	r13,r28		; du2
	add	r25,r27
	add	r26,r28
	moveta	r27,r8		; u1'
	moveta	r28,r12		; u2'
	;; update v
	movefa	r10,r25		; v1
	movefa	r14,r26		; v2
	movefa	r11,r27		; dv1
	movefa	r15,r28		; dv2
	add	r25,r27
	add	r26,r28
	moveta	r27,r10		; v1'
	jump	(r18)		; -> .next_scanline
	moveta	r28,r14		; v2'
	.endif
	;; 
.flat_shading:
	;; Flat
	;; r27: y|x1 (start of blit)
	;; r28: w (almost width)
	wait_blitter_gpu	r15,r29
	or	r21,r28					; 1|w	(executed during wait loop)
* 	movei	#PATDSEL,r29
	moveq	#PATDSEL>>16,r29
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	shlq	#16,r29
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.gouraud_shading:
	;; Gouraud
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; compute i
	compute_i
	;;
	movefa	r18,r13		; get blitter flags
	fix_gouraud_mode	r13,1,r27,r28,r29 ; fix according to x1
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	;; 
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set intensities
	btst	#XADDPIX_BIT,r13 ; pixel mode or phrase mode?
	addqt	#32,r15
	jr	eq,.gouraud_phrase_mode
	store	r25,(r15+((B_I3-(A1_BASE+32))/4)) ; B_I3
.gouraud_pixel_mode:
	jr	.gouraud_go_blit
	shlq	#8,r26
.gouraud_phrase_mode:
	sub	r26,r25
	store	r25,(r15+((B_I2-(A1_BASE+32))/4)) ; B_I2
	sub	r26,r25	
	store	r25,(r15+((B_I1-(A1_BASE+32))/4)) ; B_I1
	sub	r26,r25
	shlq	#10,r26
	store	r25,(r15+((B_I0-(A1_BASE+32))/4)) ; B_I0
.gouraud_go_blit:
	shrq	#8,r26
	subq	#32,r15
	store	r26,(r15+((B_IINC-A1_BASE)/4)) 		; B_IINC
	;; 
*	movei	#PATDSEL|GOURD,r29
	moveq	#(PATDSEL|GOURD)>>12,r29
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	shlq	#12,r29
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r13,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.flat_zbuffer:
	;; Flat with Z-buffer
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; compute z
	compute_z
	;; 
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set z
	addq	#32,r15
	set_z_phrase
	subq	#32,r15
	;; 
 	movei	#PATDSEL|ZBUFF|DSTEN|DSTENZ|DSTWRZ|ZCOND,r29
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.gouraud_zbuffer:
	;; Gouraud with Z-buffer
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; compute i
	compute_i
	;;
	movefa	r18,r13		; get blitter flags
	fix_gouraud_mode	r13,1,r27,r28,r29 	; fix according to x1
	;;
	moveta	r25,r24		; save i
	moveta	r26,r25		; save di
	;; compute z
	compute_z
	;; 
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set i & z
	btst	#XADDPIX_BIT,r13
	addqt	#32,r15
	jr	eq,.gouraud_zbuffer_phrase_mode
	store	r25,(r15+((B_Z3-(A1_BASE+32))/4)) 	; B_Z3
.gouraud_zbuffer_pixel_mode:
	move	PC,r30
	store	r26,(r15+((B_ZINC-(A1_BASE+32))/4)) 	; B_ZINC
	addq	#(.gouraud_zbuffer_go_blit-.gouraud_zbuffer_pixel_mode)/2,r30
	movefa	r24,r25				    	; restore i
	addq	#(.gouraud_zbuffer_go_blit-.gouraud_zbuffer_pixel_mode)/2,r30
	movefa	r25,r26				    	; restore di
	store	r25,(r15+((B_I3-(A1_BASE+32))/4))   	; B_I3
	jump	(r30)
	shlq	#8,r26
.gouraud_zbuffer_phrase_mode:
	sub	r26,r25
	store	r25,(r15+((B_Z2-(A1_BASE+32))/4)) 	; B_Z2
	sub	r26,r25
	store	r25,(r15+((B_Z1-(A1_BASE+32))/4)) 	; B_Z1
	sub	r26,r25
	store	r25,(r15+((B_Z0-(A1_BASE+32))/4)) 	; B_Z0
	shlq	#2,r26					; 4*z_inc
	store	r26,(r15+((B_ZINC-(A1_BASE+32))/4))	; B_ZINC
	movefa	r24,r25				    	; restore i
	store	r25,(r15+((B_I3-(A1_BASE+32))/4))	; B_I3
	movefa	r25,r26				    	; restore di
	sub	r26,r25
	store	r25,(r15+((B_I2-(A1_BASE+32))/4))	; B_I2
	sub	r26,r25
	store	r25,(r15+((B_I1-(A1_BASE+32))/4))	; B_I1
	sub	r26,r25
	shlq	#10,r26					; 4*i_inc
	store	r25,(r15+((B_I0-(A1_BASE+32))/4))	; B_I0
.gouraud_zbuffer_go_blit:
	shrq	#8,r26
	subq	#32,r15
	store	r26,(r15+((B_IINC-A1_BASE)/4))		; B_IINC	
	;;
 	movei	#PATDSEL|GOURD|ZBUFF|DSTEN|DSTENZ|DSTWRZ|ZCOND,r29
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	store	r13,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.texture_mapping:
	;; Texture mapping
	moveta	r28,r27		; save w
	moveta	r27,r26		; save y|x1
	;; compute u & v
	compute_u
	sub	r26,r25		; u -= du
	sub	r26,r25		; u -= du
	sub	r26,r25		; u -= du
	moveta	r25,r24		; save u
	moveta	r26,r25		; save du
	compute_v
	sub	r26,r25		; v -= dv
	sub	r26,r25		; v -= dv
	sub	r26,r25		; v -= dv
	;; compute A1_PIXEL, A1_FPIXEL, A1_INC, A1_FINC
	move	r25,r27		; save Y
	move	r26,r28		; save dY
	and	r22,r28		; A1_INC(y)
	and	r22,r27		; A1_PIXEL(y)
	movefa	r25,r30		; dX
	shrq	#16,r30		; A1_INC(x)
	movefa	r24,r29		; X
	shrq	#16,r29		; A1_PIXEL(x)
	or	r30,r28		; A1_INC
	or	r29,r27		; A1_PIXEL
	movefa	r25,r30		; dX
	shlq	#16,r30
	movefa	r24,r29		; X
	shlq	#16,r29
	shlq	#16,r25		; A1_FPIXEL(y)
	shlq	#16,r26		; A1_FINC(y)
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
	btst	#GRDSHADING,r2
 	store	r30,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	jr	ne,.texture_gouraud_shading
	bclr	#0,r30		; 1 | (w + x1 % 4) [even width]
.texture_flat_shading:
	;; Texture flat shading
	movefa	r22,r29					; get finish routine
	movei	#XADDPIX|WIDBUFFER|PIXEL16|PITCH1,r27	; GPU buffer flags
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
	jump	(r29)
 	store	r13,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.texture_gouraud_shading:
	;; Texture Gouraud shading
	moveta	r30,r25					; save (modified) B_COUNT
	;; compute i
	compute_i
	;; 
	movei	#XADDPHR|WIDBUFFER|PIXEL16|PITCH1,r27	; GPU buffer flags
	fix_gouraud_mode	r27,0,r28,r29,r30	; do not use x1 to fix value
	;; set intensities
	btst	#XADDPIX_BIT,r27
	addqt	#32,r15
	jr	eq,.texture_gouraud_phrase_mode
	store	r25,(r15+((B_I3-(A1_BASE+32))/4)) ; B_I3
.texture_gouraud_pixel_mode:
	jr	.texture_gouraud_go_blit
	shlq	#8,r26
.texture_gouraud_phrase_mode:
	sub	r26,r25
	store	r25,(r15+((B_I2-(A1_BASE+32))/4)) ; B_I2
	sub	r26,r25	
	store	r25,(r15+((B_I1-(A1_BASE+32))/4)) ; B_I1
	sub	r26,r25
	shlq	#10,r26
	store	r25,(r15+((B_I0-(A1_BASE+32))/4)) ; B_I0
.texture_gouraud_go_blit:
	shrq	#8,r26
	subq	#32,r15
	store	r26,(r15+((B_IINC-A1_BASE)/4)) 		; B_IINC
	;; 
	movei	#PATDSEL|DSTA2|GOURD,r28
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
 	store	r28,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;;
	moveq	#0,r28
	bset	#XADDPIX_BIT,r27
	wait_blitter_gpu	r15,r29
	movefa	r25,r30					; restore B_COUNT (executed during wait loop)
	movefa	r22,r29					; get finish routine
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
	store	r28,(r15+((A2_PIXEL-A1_BASE)/4)) 	; A2_PIXEL
	store	r30,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	jump	(r29)
	store	r13,(r15+((B_CMD-A1_BASE)/4)) 		; B_CMD
	;; 
.texture_nozbuffer:
	;; Texture without Z-buffer
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;;
 	movei	#SRCENX|SRCEN|LFU_REPLACE,r29 			; ** SRCENX **
	moveq	#3,r25
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	and	r27,r25
	moveq	#0,r27
	subq	#4,r25						; ** stupid workaround **
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	shlq	#16,r25						; ** to force the blitter **
	movefa	r17,r28					; destination base address
	shrq	#16,r25						; ** read the previous phrase **
	store	r27,(r15+((A1_CLIP-A1_BASE)/4))		; A1_CLIP workaround
	store	r25,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	movefa	r18,r25					; destination blitter flags
	movei	#XADDPHR|WIDBUFFER|PIXEL16|PITCH1,r27	; GPU buffer flags
	store	r28,(r15+((A1_BASE-A1_BASE)/4))		; A1_BASE
	store	r25,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
.texture_zbuffer:
	;; Texture with Z-buffer
	;; compute z
	compute_z
	;;
	movefa	r26,r27		; restore y|x1
	movefa	r27,r28		; restore w
	wait_blitter_gpu	r15,r29
 	or	r21,r28		; 1|w (executed during wait loop)
	;; set z
	addq	#32,r15
	set_z_phrase	
	subq	#32,r15
	;;
 	movei	#SRCENX|SRCEN|LFU_REPLACE|ZBUFF|DSTEN|DSTENZ|DSTWRZ|ZCOND,r29	; ** SRCENX **
	moveq	#3,r25
	store	r27,(r15+((A1_PIXEL-A1_BASE)/4))	; A1_PIXEL
	and	r27,r25
	moveq	#0,r27
	subq	#4,r25						; ** stupid workaround **
	store	r28,(r15+((B_COUNT-A1_BASE)/4))		; B_COUNT
	shlq	#16,r25						; ** to force the blitter **
	movefa	r17,r28					; destination base address
	shrq	#16,r25						; ** read the previous phrase **
	store	r27,(r15+((A1_CLIP-A1_BASE)/4))		; A1_CLIP workaround
	store	r25,(r15+((A2_PIXEL-A1_BASE)/4))	; A2_PIXEL
	movefa	r18,r25					; destination blitter flags
	movei	#XADDPHR|WIDBUFFER|PIXEL16|PITCH1,r27	; GPU buffer flags
	store	r28,(r15+((A1_BASE-A1_BASE)/4))		; A1_BASE
	store	r25,(r15+((A1_FLAGS-A1_BASE)/4))	; A1_FLAGS
	store	r27,(r15+((A2_FLAGS-A1_BASE)/4))	; A2_FLAGS
	jump	(r18)					; -> .next_scanline
	store	r29,(r15+((B_CMD-A1_BASE)/4))		; B_CMD
	;; 
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
	dc.l	.flat_shading-.render_polygon
	;; gouraud
	dc.l	.gouraud_shading-.render_polygon
	;; flat + z
	dc.l	.flat_zbuffer-.render_polygon
	;; gouraud + z
	dc.l	.gouraud_zbuffer-.render_polygon
	;; texture + flat
	dc.l	.texture_nozbuffer-.render_polygon
	;; texture + gouraud 
	dc.l	.texture_nozbuffer-.render_polygon
	;; texture + z
	dc.l	.texture_zbuffer-.render_polygon
	;; texture + gouraud + z
	dc.l	.texture_zbuffer-.render_polygon
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
.renderer_return:
	move	PC,r1
	moveq	#0,r2
	addq	#.renderer_params+8-.renderer_return,r1 ; .renderer_params+8
	load	(r31),r0	; return address
	addq	#4,r31		; restore stack
	jump	(r0)		; return
	store	r2,(r1)		; clear mutex
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
MANTISSA	equ	$4|((WIDBUFFER>>9) & $3)
EXPONENT	equ	(WIDBUFFER>>11) & $f
BUFFER_WIDTH	equ	(MANTISSA*(1<<EXPONENT))>>2
	.print	"Renderer buffer size: ", 2*BUFFER_WIDTH
	.print	"Renderer total size: ", RENDERER_SIZE+(2*BUFFER_WIDTH)
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
	add.l	#RENDERER_SIZE+(2*BUFFER_WIDTH),d0
	addq.l	#7,d0
	and.l	#~7,d0
	rts

	.globl	_render_polygon_list_and_wait
;;; void render_polygon_list_and_wait(screen *target, polygon *p, int clear_flags)
_render_polygon_list_and_wait:
	move.l	renderer_gpu_address,a0
	lea	RENDERER_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),d0
	move.l	12(sp),d1
	and.b	#%11,d1
	or.b	d1,d0
	move.l	d0,(a1)+
	move.l	#$80000000,(a1)
	lea	RENDERER_RENDER(a0),a1
	jsr_gpu	a1
	lea	RENDERER_PARAMS+8(a0),a0
.wait:
	tst.l	(a0)
	bmi.s	.wait
	wait_blitter	d0
	rts
	
	.globl	_render_polygon_list
;;; void render_polygon_list(screen *target, polygon *p, int clear_flags)
_render_polygon_list:
	move.l	renderer_gpu_address,a0
	lea	RENDERER_PARAMS(a0),a1
	move.l	4(sp),(a1)+
	move.l	8(sp),d0
	move.l	12(sp),d1
	and.b	#%11,d1
	or.b	d1,d0
	move.l	d0,(a1)+
	move.l	#$80000000,(a1)
	lea	RENDERER_RENDER(a0),a1
	jsr_gpu	a1
	rts

	.globl	_wait_renderer_completion
;;; void wait_renderer_completion
_wait_renderer_completion:	
	move.l	renderer_gpu_address,a0
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

