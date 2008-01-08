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

	.if	^^defined	DISPLAY_H
	.print	"display_def.s already included"
	end
	.endif
DISPLAY_H	equ	1
	.print	"including display_def.s"

	include	"display_def.s"
	
	.extern	_a_vdb
	.extern	_bcopy
	.extern	_vblCounter
	.extern	_stop_object

;; DISPLAY_BG_IT	equ	1
	
	include	"display_cfg.s"

GPU_STACK_SIZE		equ	32	; in long words
	
; 	.bss
; 	.phrase
; gpu_isp:	ds.l	GPU_STACK_SIZE
; 	.phrase
; gpu_usp:	ds.l	GPU_STACK_SIZE
; GPU_ISP	equ	gpu_isp
; GPU_USP	equ	gpu_usp
GPU_USP	equ	(G_ENDRAM-(4*GPU_STACK_SIZE))
GPU_ISP	equ	(GPU_USP-(4*GPU_STACK_SIZE))
			
	.text
	.68000

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

.macro	display_save_first_regs
	push	r1
	push	r2
	push	r14
	push	r15
.endm

.macro	display_restore_first_regs
	pop	r15
	pop	r14
	pop	r2
	pop	r1
.endm	
		
.macro	display_save_other_regs
	push	r0
*	push	r1
*	push	r2
	push	r3
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
*	push	r14
*	push	r15
	push	r16
	push	r17
	push	r18
	push	r19
	push	r20
	push	r21
	push	r22
	push	r23
	push	r24
	push	r25
	push	r26
	push	r27
.endm

.macro	display_restore_other_regs
	pop	r27
	pop	r26
	pop	r25
	pop	r24
	pop	r23
	pop	r22
	pop	r21
	pop	r20
	pop	r19
	pop	r18
	pop	r17
	pop	r16
*	pop	r15
*	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	r7
	pop	r6
	pop	r5
	pop	r4
	pop	r3
*	pop	r2
*	pop	r1
	pop	r0
.endm

;;; the GPU display driver
;;; for sake of simplicity, it clears the interrupt handlers
;;; so you shoud install your own interrupts after having initialised
;;; the display driver
;;; this code is not self-relocatable
	.phrase
gpu_display_driver:
	.gpu
	.org	G_RAM
.gpu_display_driver_begin:
	;; CPU interrupt
	.if	!DISPLAY_USE_OP_IT
	movei	#.gpu_display_from_cpu_it,r28
	movei	#G_FLAGS,r30
	jump	(r28)
	load	(r30),r29	; get flags
	.endif
	padding_nop	(G_RAM+$10-*)
	;; 
	.org	G_RAM+$10
	;; DSP interrupt
	padding_nop	$10
	;; 
	.org	G_RAM+$20
	;; Timing interrupt
	padding_nop	$10
	;; 
	.org	G_RAM+$30
	;; OP interrupt
	.if	DISPLAY_USE_OP_IT
	movei	#.gpu_display_from_op_it,r28
	movei	#G_FLAGS,r30
	jump	(r28)
	load	(r30),r29	; get flags
	.endif
	padding_nop	(G_RAM+$40-*)
	;; 
	.org	G_RAM+$40	
	;; Blitter interrupt
	padding_nop	$10
	.org	G_RAM+$50
.macro	gpu_display_swap_lists
	;; r15 is display list address
	load	(r15+DISPLAY_LOG/4),r1 ; logical list
	load	(r15+DISPLAY_PHYS/4),r14 ; physical list
	store	r1,(r15+DISPLAY_PHYS/4)	; logical becomes physical
	store	r14,(r15+DISPLAY_LOG/4)	; physical becomes logical
	shrq	#3,r1		; physical list address in phrases
	load	(r15+(DISPLAY_LIST_OB4+4)/4),r2	; read BRANCH object
	move	r1,r28		; copy address
	shlq	#15,r2
	shrq	#8,r1		; high bits of BRANCH object
	shrq	#15,r2
	shlq	#24,r28
	or	r28,r2		; low bits
	store	r1,(r15+DISPLAY_LIST_OB4/4)
	store	r2,(r15+((DISPLAY_LIST_OB4+4)/4))
.endm
	.if	!DISPLAY_USE_OP_IT
.gpu_display_from_cpu_it:
	.if	DISPLAY_IT_SAVE_REGS
	display_save_first_regs
	.endif
	movei	#active_display_list,r1
	load	(r1),r15
	gpu_display_swap_lists
	.if	DISPLAY_BG_IT
	movei	#DISPLAY_BG_CPU,r1
	.endif
*	movei	#.gpu_display_main,r28
	bset	#9,r29		; clear latch 0
*	jump	(r28)
*	nop
	.else
.gpu_display_from_op_it:
	.if	DISPLAY_IT_SAVE_REGS
	display_save_first_regs
	.endif
	.if	DISPLAY_OP_IT_COMP_PT
	movei	#active_display_list,r1
	load	(r1),r15
	.else
	movei	#OB2,r1
	load	(r1),r15
	rorq	#16,r15
	.endif
	gpu_display_swap_lists
	.if	DISPLAY_BG_IT
	movei	#DISPLAY_BG_OP,r1	; BLUE
	.endif
	movei	#OBF,r28
	storew	r28,(r28)	; relaunch OP
*	movei	#.gpu_display_main,r28
	bset	#12,r29		; clear latch 3
*	jump	(r28)
*	nop
	.endif
.gpu_display_main:
	.if	DISPLAY_IT_SAVE_REGS
	display_save_other_regs
	.endif
	.if	DISPLAY_BG_IT
	movei	#BG,r2
	or	r2,r2
	storew	r1,(r2)
	.endif
	;; must not modify neither r29 nor r30 nor r31 !!
	;; r15 is display address
	;; r14 is logical list address
	movei	#DISPLAY_STRIP_TREE_SIZEOF,r0
	movei	#DISPLAY_STRIPS,r1
	;; r20 is .gpu_display_strips
	movei	#.gpu_display_strips,r20
	add	r14,r0		; skip decision tree in logical list
	move	r20,r2
	add	r15,r1		; to read strips 
	moveq	#DISPLAY_NB_STRIPS,r3
.gpu_copy_strips:
	load	(r1),r4		; read Y|H
	addq	#4,r1
	move	r4,r6
	sharq	#16,r4		; Y
	load	(r1),r5		; read offset (in bytes)	
	store	r4,(r2)
	addq	#4,r2
	addq	#4,r1
	add	r0,r5		; start of corresponding list
	shrq	#3,r5		; in phrases
	subq	#1,r3		; strip--
	store	r5,(r2)		; do not change flags!
	jr	ne,.gpu_copy_strips
	addqt	#4,r2
	shlq	#16,r6
	shrq	#16,r6
	add	r4,r6		; y_max
	store	r6,(r2)
	;; the strips have been copied in GPU ram at this point!
	movei	#_a_vdb,r0	
	movei	#DISPLAY_HASHTBL,r10
	loadw	(r0),r0		     ; a_vdb
	load	(r15+DISPLAY_Y/4),r1 ; read DISPLAY_Y|DISPLAY_X
	addq	#1,r0		     ; a_vdb+1
	move	r1,r2
	add	r15,r10		     ; address of hash table
	sharq	#16,r1		     ; DISPLAY_Y
	shrq	#1,r0		     ; y_min = (a_vdb+1)/2
	shlq	#16,r2		     ; DISPLAY_X|0
	add	r0,r1		     ; y_min + DISPLAY_Y
	shrq	#16,r2		     ; DISPLAY_X
	shlq	#16,r1		     ; (y_min + DISPLAY_Y)|0
	moveq	#1<<DISPLAY_NB_LAYER,r11 ; layer counter
	or	r2,r1			 ; (y_min + DISPLAY_Y)|DISPLAY_X
	movei	#.compute_one_layer,r28
	movei	#.do_layer,r27
	movei	#.do_layer_tst,r26
	movei	#.next_in_layer,r25
	movei	#.anim_off,r24
	movei	#.non_scaled_sprite,r23
	movei	#.non_scaled_cut_sprite,r22
	movei	#.scaled_cut_sprite,r21
.compute_one_layer:
	;; r10 goes through hash table
	;; r11 is the layer counter
	;; r1 is (y_min + DISPLAY_Y)|DISPLAY_X where y_min = (a_vdb+1)/2
	load	(r10),r9	; read attribute
	addq	#4,r10		; skip it
	sharq	#1,r9		; test hidden flag
	jr	cs,.layer_visible ; set then visible
	moveq	#0,r14		  ; otherwise simulate empty layer
	jump	(r26)		  ; jump .do_layer_tst
	addq	#12,r10		; next layer
.layer_visible:
	load	(r10),r9	; LAYER_Y|LAYER_X
	move	r1,r2		; copy (y_min+DISPLAY_Y)|DISPLAY_X
	move	r9,r3		; copy LAYER_Y|LAYER_X
	shlq	#16,r2		; DISPLAY_X|0
	shlq	#16,r3		; LAYER_X|0
	sharq	#16,r9		; LAYER_Y
	add	r3,r2		; (DISPLAY_X+LAYER_X)|0
	move	r1,r3		; copy (y_min+DISPLAY_Y)|DISPLAY_X
	sharq	#16,r2		; DISPLAY_X+LAYER_X
	sharq	#16,r3		; y_min+DISPLAY_Y
	addq	#8,r10		; go to "next" field
	add	r9,r3		; y_min+DISPLAY_Y+LAYER_Y
	;; r2 is DISPLAY_X+LAYER_X
	;; r3 is y_min+DISPLAY_Y+LAYER_Y
	load	(r10),r14	; get sprite address
	jump	(r26)		  ; jump .do_layer_tst	
	addq	#4,r10		; next layer
.do_layer:
	;; r14 is sprite base address
	;; process a sprite
	;;  1-check if visible
	;;  2-compute DATA base address
	;; for unscaled sprites:
	;;  3a-compute coords 
	;;  4a-emit 
	;; for scaled sprites:
	;;  3b-compute coords 
	;;  4b-emit
	load	(r14+SPRITE_SND_PHRASE/4),r9
	btst	#SPRITE_INVISIBLE,r9 ; invisible?
	jump	ne,(r25)	; jump ne,.next_in_layer
	btst	#SPRITE_ANIM_ON_OFF,r9 ; animated?
	jump	eq,(r24)	; jump eq,.anim_off
	load	(r14+(SPRITE_SND_PHRASE+4)/4),r8 ; ** load low bits of snd phrase **
.anim_on:
	load	(r14+SPRITE_ANIM_DATA/4),r7 ; anim settings
	load	(r14+SPRITE_ANIM_ARRAY/4),r12 ; anim array address
	move	r7,r6		; COUNTER|(L|INDEX)
	shlq	#17,r7		; clear LOOP flag
	shrq	#16,r6		; COUNTER
	shrq	#17-3,r7	; INDEX<<3
	move	r12,r13
	add	r7,r12		; address of animation chunck
	subq	#1,r6		; COUNTER--
	jr	ne,.anim_no_next
	shrq	#3,r7		; INDEX
.anim_next:
	addq	#1<<3,r12	; next animation chunck
	addq	#1,r7		; INDEX++
	load	(r12),r4	; DATA base address
	addq	#4,r12
	cmpq	#0,r4		; end of array?
	jr	ne,.anim_write_data
	loadw	(r12),r6	; new COUNTER = SPEED
	jr	.anim_index_fix
	move	r6,r7		; loop INDEX
.anim_no_next:
	jr	.anim_write_data
	load	(r12),r4	; DATA base address
.anim_index_fix:
	shlq	#3,r6		; INDEX<<3
	bset	#15,r7		; set LOOP flag
	add	r6,r13
	load	(r13),r4	; DATA base address
	addq	#4,r13
	loadw	(r13),r6	; new COUNTER = SPEED
.anim_write_data:
	;; r4 = DATA base address
	;; r6 = COUNTER
	;; r7 = L|INDEX
	shlq	#16,r6
	or	r6,r7
	jr	.data_ok
	store	r7,(r14+SPRITE_ANIM_DATA/4)
.anim_off:
	load	(r14+SPRITE_DATA/4),r4 ; DATA base address
.data_ok:
	;; at this point, DATA is computed
	;; the content of the registers is the following
	;; r1 is (y_min + DISPLAY_Y)|DISPLAY_X where y_min = (a_vdb+1)/2
	;; r2 is DISPLAY_X+LAYER_X
	;; r3 is y_min+DISPLAY_Y+LAYER_Y
	;; r4 is DATA in bytes
	;; r8 is low bits of snd phrase
	;; r9 is high bits of snd phrase
	;; r10 goes through hash table
	;; r11 is layer counter
	;; r14 is sprite base address
	load	(r14+SPRITE_Y/4),r5 ; Y|X
	shrq	#3,r4		; DATA in phrases
	move	r5,r6
	shlq	#16,r5		; X|0
	sharq	#16,r6		; Y
	sharq	#16,r5		; X
	add	r3,r6		; Y+y_min+DISPLAY_Y+LAYER_Y
	add	r2,r5		; X+DISPLAY_X+LAYER_X
	;; r5 is X (still to be adjusted according to HOTSPOT)
	;; r6 is Y (...)
	move	r8,r19		; copy low bits of snd phrase
	move	r8,r7		; copy low bits of snd phrase
	shlq	#22,r19		; HEIGHT<<22
	shrq	#12,r8		; clear HEIGHT field
	cmpq	#0,r19		; HEIGHT<<22 = 0?
	jump	eq,(r25)	; jump eq,.next_in_layer
	shrq	#22,r19		; HEIGHT
	;; r19 is HEIGHT (not null)
	shlq	#12,r8		; 12 lower bits cleared
	shlq	#4,r7
	btst	#SPRITE_TYPE,r9	;
	jump	eq,(r23)	; jump eq,.non_scaled_sprite
	shrq	#32-10,r7	; DWIDTH
.scaled_sprite:
	subq	#1,r19		; HEIGHT-- (scaled sprites fix)
	jump	eq,(r25)	; jump eq,.next_in_layer
	nop
	load	(r14+SPRITE_SCALE/4),r18 ; REMAINDER|VSCALE|HSCALE
	move	r18,r0			 ; REMAINDER|VSCALE|HSCALE
	move	r18,r17			 ; REMAINDER|VSCALE|HSCALE
	shlq	#32-16,r18		 ; VSCALE|HSCALE|0|0
	shlq	#8,r0			 ; REMAINDER|VSCALE|HSCALE|0
	shrq	#32-8,r18	; VSCALE 
	jump	eq,(r25)	; VSCALE = 0 ? jump eq,.next_in_layer
	shrq	#8,r0		; 0|REMAINDER|VSCALE|HSCALE
	shlq	#32-8,r17	; HSCALE|0|0|0
	btst	#SPRITE_USE_HOTSPOT,r9
	jr	eq,.scaled_ok_coords
	shrq	#32-8,r17	; HSCALE
	load	(r14+SPRITE_HY/4),r16 ; HY|HX
	move	r16,r13
	sharq	#16,r16		; HY
	shlq	#16,r13		; HX|0
	imult	r18,r16		; HY*VSCALE
	sharq	#16,r13		; HX
	sharq	#5,r16		; integer part of HY*VSCALE
	imult	r17,r13		; HX*HSCALE
	sub	r16,r6		; Y -= HY*VSCALE
	btst	#SPRITE_REFLECT,r9 ; REFLECT?
	jr	eq,.scaled_no_reflect
	sharq	#5,r13		; integer part of HX*HSCALE
	neg	r13		; negate HX*HSCALE
.scaled_no_reflect:
	sub	r13,r5		; X -= HX*HSCALE
.scaled_ok_coords:
	;; the content of the registers is the following
	;; r1 is (y_min+DISPLAY_Y)|DISPLAY_X where y_min = (a_vdb+1)/2
	;; r2 is DISPLAY_X+LAYER_X
	;; r3 is y_min+DISPLAY_Y+LAYER_Y
	;; r4 is DATA in phrases
	;; r5 is X 
	;; r6 is Y 
	;; r7 is DWIDTH
	;; r8 is low bits of snd phrase (12 lower bits cleared)
	;; r9 is high bits of snd phrase
	;; r10 goes through hash table
	;; r11 is layer counter
	;; r14 is sprite base address
	;; r19 is HEIGHT (not null)
	;; r0 is 0|REMAINDER|VSCALE|HSCALE (VSCALE is not null) ie R0>>16 is the remainder!
	move	r20,r13		; .gpu_display_strips
	shlq	#20,r5		; keep only 12 bits for X
	moveq	#DISPLAY_NB_STRIPS,r12		; i = 0
	shrq	#20,r5		; XPOS
	or	r5,r8		; low bits of snd phrase ready
	;; r5 is now free
	movei	#.scaled_emit_sprite,r18
.scaled_search_strip:
	;; for(i = 0; i < DISPLAY_NB_STRIPS && strip[i].y <= y; i++)
	load	(r13),r5	; strip[i].y
	cmp	r5,r6
	jr	mi,.scaled_found_strip ; if y - strip.y < 0 then found
	subqt	#4,r13		; previous strip (list pointer)
	subq	#1,r12
	jr	pl,.scaled_search_strip ; pl because of the last strip
	addq	#12,r13		; next strip
	jump	(r25)		; jump .next_in_layer
	nop
.scaled_found_strip:
	cmpq	#DISPLAY_NB_STRIPS,r12
	jump	ne,(r18)	; jr ne,.scaled_emit_sprite 
	addq	#1,r12
.scaled_first_strip:
	;; the first strip is particular
	;; because the part above the strip is invisible
	addq	#8,r13
	subq	#1,r12
.scaled_cut_sprite:
	;; r5 is strip.y at this point
	;; there is a substantial overhead
	;; for cutting scaled sprites
	;; so spare them!
	move	r5,r17		; strip.y
	move	r0,r18		; 0|REMAINDER|VSCALE|HSCALE
	sub	r6,r17		; dy = strip.y - y
	shlq	#16,r0		; VSCALE|HSCALE|0|0
	shlq	#5,r17		; dy << 5
	shrq	#16,r18		; REMAINDER
	move	r0,r16		; VSCALE|HSCALE|0|0
	shrq	#16,r0		; 0|0|VSCALE|HSCALE (ready to update REMAINDER)
	move	r5,r6		; y = strip.y
	movei	#G_REMAIN,r5
	sub	r17,r18		; REMAINDER - (dy << 5)
	jr	pl,.scaled_cut_sprite_end
	moveq	#0,r17		; DATA will not change in this case
	shrq	#24,r16		; VSCALE
	neg	r18		; (dy << 5) - REMAINDER
	div	r16,r18		; ((dy << 5) - REMAINDER) / VSCALE 
	move	r18,r17		; wait for division to complete (we really waste cycles there)
	load	(r5),r18	; get G_REMAIN
	neg	r18		; negate
	jr	eq,.scaled_cut_sprite_ok_division ; if 0 then ok
	nop
	jr	pl,.scaled_cut_sprite_ok_division ; if > 0 then
	addq	#1,r17				  ; fix quotient
	add	r16,r18				  ; if < 0 fix also remainder
.scaled_cut_sprite_ok_division:
	;; r17 is the quotient
	;; r18 is the remainder
	sub	r17,r19		; h -= q
	jump	mi,(r25)
	mult	r7,r17		; q*DWIDTH
.scaled_cut_sprite_end:
	;; r17 is 0 or q*DWIDTH
	;; r18 is the new remainder
	shlq	#16,r18
	add	r17,r4		; DATA += q*DWIDTH
	or	r18,r0
.scaled_emit_sprite:
	load	(r13),r15
	move	r6,r16		; y
	btst	#1,r15		; is it 32 bytes aligned?
	jr	eq,.scaled_emit_aligned	; yes
	move	r15,r17			; copy 
	shlq	#3,r15			; in bytes
	addq	#2,r17
	movei	#O_BREQ|($7ff<<3)|BRANCHOBJ,r5 ; branch always
	move	r17,r18
	shrq	#8,r18
	store	r18,(r15)
	move	r17,r18
	addq	#4,r15
	shlq	#32-8,r18
	or	r18,r5
	store	r5,(r15)
	move	r17,r15
.scaled_emit_aligned:
	shlq	#3,r15		; in bytes
	addq	#4,r17
	move	r19,r5		; height
	store	r17,(r13)	; next object in list
	shlq	#32-11+1,r16	; keep 11 bits of Y*2
	shlq	#32-10,r5
	shrq	#32-14,r16	; YPOS|0
	shrq	#32-24,r5
	addq	#1,r16		; scaled sprite!
	addq	#4,r13
	or	r5,r16		; HEIGHT|YPOS|0
	move	r17,r5		; copy LINK
	shlq	#32-8,r17
	shrq	#8,r5
	or	r17,r16		; low bits of first phrase
	store	r0,(r15+5)	; copy scale factors
	move	r4,r17
	store	r16,(r15+1)
	shlq	#11,r17		; DATA|0
	store	r8,(r15+3)
	or	r5,r17		; high bits of first phrase
	store	r9,(r15+2)
	subq	#1,r12		; strip--
	jump	eq,(r25)	; jump eq,.next_in_layer
	store	r17,(r15)
	load	(r13),r5	; strip.y
	jump	(r21)		; jump .scaled_cut_sprite
	addq	#4,r13
.non_scaled_sprite:
	btst	#SPRITE_USE_HOTSPOT,r9
	jr	eq,.non_scaled_ok_coords
	nop
	load	(r14+SPRITE_HY/4),r18 ; HY|HX
	move	r18,r17
	sharq	#16,r18		; HY
	shlq	#16,r17
	sub	r18,r6		; Y -= HY
	btst	#SPRITE_REFLECT,r9 ; REFLECT?
	jr	eq,.non_scaled_no_reflect
	sharq	#16,r17		; HX
	neg	r17		; negate HX
.non_scaled_no_reflect:
	sub	r17,r5		; X -= HX
.non_scaled_ok_coords:
	;; the content of the registers is the following
	;; r1 is (y_min+DISPLAY_Y)|DISPLAY_X where y_min = (a_vdb+1)/2
	;; r2 is DISPLAY_X+LAYER_X
	;; r3 is y_min+DISPLAY_Y+LAYER_Y
	;; r4 is DATA in phrases
	;; r5 is X 
	;; r6 is Y 
	;; r7 is DWIDTH
	;; r8 is low bits of snd phrase (12 lower bits cleared)
	;; r9 is high bits of snd phrase
	;; r10 goes through hash table
	;; r11 is layer counter
	;; r14 is sprite base address
	;; r19 is HEIGHT (not null)
	shlq	#20,r5		; keep only 12 bits for X
	move	r20,r13		; .gpu_display_strips
	shrq	#20,r5		; XPOS
	moveq	#DISPLAY_NB_STRIPS,r12		; i = 0
	or	r5,r8		; low bits of snd phrase ready
	;; r5 is now free
.non_scaled_search_strip:
	;; for(i = 0; i < DISPLAY_NB_STRIPS && strip[i].y <= y; i++)
	load	(r13),r5	; strip[i].y
	cmp	r5,r6
	jr	mi,.non_scaled_found_strip ; if y - strip.y < 0 then found
	subqt	#4,r13		; previous strip (list pointer)
	subq	#1,r12
;; 	jr	ne,.non_scaled_search_strip
	jr	pl,.non_scaled_search_strip ; pl because of the last strip
	addq	#12,r13		; next strip
	;; check whether it is in the last strip
;; 	load	(r13),r5	; y_max
;; 	cmp	r5,r6
;; 	jr	mi,.non_scaled_found_strip
;; 	subq	#4,r13
	;; the sprite is invisible
	jump	(r25)		; jump .next_in_layer
	nop
.non_scaled_found_strip:
	cmpq	#DISPLAY_NB_STRIPS,r12
	jr	ne,.non_scaled_emit_sprite
	addq	#1,r12
.non_scaled_first_strip:
	;; the first strip is particular
	;; because the part above the strip is invisible
	addq	#8,r13
	subq	#1,r12
.non_scaled_cut_sprite:
	;; r5 is strip.y
	move	r5,r17		; strip.y
	sub	r6,r17		; strip.y - y
	move	r5,r6		; y = strip.y
	sub	r17,r19		; h -= strip.y - y
	jump	mi,(r25)	; jump mi,.next_in_layer
	mult	r7,r17		; DWIDTH*(strip.y-y)
	add	r17,r4		; DATA += DWIDTH*(strip.y-y)
.non_scaled_emit_sprite:
	load	(r13),r15
	move	r6,r16		; y
	move	r15,r17
	shlq	#3,r15		; in bytes
	addq	#2,r17		; next LINK
	move	r19,r5		; height
	store	r17,(r13)	; next object in list
	shlq	#32-11+1,r16	; keep 11 bits of Y*2
	shlq	#32-10,r5
	shrq	#32-14,r16	; YPOS|0
	shrq	#32-24,r5
	addq	#4,r13
	or	r5,r16		; HEIGHT|YPOS|0
	move	r17,r5		; copy LINK
	shlq	#32-8,r17
	shrq	#8,r5
	or	r17,r16		; low bits of first phrase
	move	r4,r17
	store	r16,(r15+1)
	shlq	#11,r17		; DATA|0
	store	r8,(r15+3)
	or	r5,r17		; high bits of first phrase
	store	r9,(r15+2)
	subq	#1,r12		; strip--
	jr	eq,.next_in_layer
	store	r17,(r15)
	load	(r13),r5	; strip.y
	jump	(r22)		; jump .non_scaled_cut_sprite
	addq	#4,r13
.next_in_layer:
	load	(r14+SPRITE_NEXT/4),r14
.do_layer_tst:
	cmpq	#0,r14		; is there a sprite? if yes then process it
	jump	ne,(r27)	; jump ne,.do_layer 
	nop
.end_layer:
	subq	#1,r11		; one layer less
	jump	ne,(r28)	; jump ne,.compute_one_layer
	nop
	;; this is the end my friend!!
	;; write a final stop object at the end of each list
	moveq	#STOPOBJ,r0	
	addq	#4,r20		; skip Y|H
	moveq	#DISPLAY_NB_STRIPS,r2
.gpu_write_stop_objects:
	load	(r20),r15	; read address
	shlq	#3,r15		; in bytes
	subq	#1,r2
	addqt	#8,r20
	jr	ne,.gpu_write_stop_objects
	store	r0,(r15+1)	; emit stop object
	;; end of the interrupt
.gpu_display_end_it:
	.if	DISPLAY_BG_IT
	movei	#BG,r1
	moveq	#0,r0	
	storew	r0,(r1)
	.endif
	movei	#_vblCounter,r28
	loadw	(r28),r26
	movei	#displayCounter,r28
	storew	r26,(r28)
	.if	DISPLAY_IT_SAVE_REGS
	display_restore_other_regs
	display_restore_first_regs
	.endif
	load	(r31),r28	; return address
	bclr	#3,r29		; clear IMASK
	addq	#2,r28		; next instruction
	addq	#4,r31		; pop from stack
	jump	t,(r28)		; return
	store	r29,(r30)	; restore flags
	.long
.gpu_display_strips:
	rept	DISPLAY_NB_STRIPS
	dc.l	0		; Y
	dc.l	0		; list address
	endr
	dc.l	0		; for y_max
.gpu_display_driver_loop:
	movei	#.gpu_display_driver_param,r0
	movei	#.gpu_display_driver_loop,r1
	load	(r0),r2		; read SUBROUT_ADDR
	moveq	#0,r3
	cmpq	#0,r2		; SUBROUT_ADDR != null
	jr	eq,.gpu_display_driver_loop ; if null then loop
	nop
	subq	#4,r31		; push on stack
	store	r3,(r0)		; clear SUBROUT_ADDR
	jump	(r2)		; jump to SUBROUT_ADDR
	store	r1,(r31)	; return address
	.long
.gpu_display_driver_param:
GPU_SUBROUT_ADDR	equ	.gpu_display_driver_param
	dc.l	0
	.long
.gpu_display_driver_init:
	;; assume run from bank 1
	movei	#GPU_ISP+(GPU_STACK_SIZE*4),r31	; init isp
	movei	#G_DIVCTRL,r0
	moveq	#0,r1
	store	r1,(r0)		; 32 bits unsigned integer division
	moveta	r31,r31		; ISP (bank 0)
	movei	#.gpu_display_driver_param,r0
	movei	#.gpu_display_driver_loop,r2
	movei	#GPU_USP+(GPU_STACK_SIZE*4),r31	; init usp
	;; enable interrupts
	movei	#G_FLAGS,r28
	.if	DISPLAY_USE_OP_IT
	movei	#G_OPENA|REGPAGE,r29
	.else
	movei	#G_CPUENA|REGPAGE,r29
	.endif
	store	r29,(r28)
	;; jump to driver
	jump	(r2)
	store	r1,(r0)		; clear SUBROUT_ADDR (mutex)
	.long
.gpu_display_driver_end:
		
DISPLAY_DRIVER_INIT	equ	.gpu_display_driver_init
DISPLAY_DRIVER_SIZE	equ	.gpu_display_driver_end-.gpu_display_driver_begin

GPU_FREE_RAM		set	.gpu_display_driver_init

	.print	"Display manager code size (GPU): ", DISPLAY_DRIVER_SIZE
	.print	"Available GPU Ram after G_RAM+",GPU_FREE_RAM-G_RAM
				
	.68000

	.globl	GPU_SUBROUT_ADDR
	.globl	__GPU_FREE_RAM
__GPU_FREE_RAM	equ	GPU_FREE_RAM

	.globl	_init_display_driver	
_init_display_driver:
	move.l	#0,G_CTRL
	move.l	#_stop_object,d0
	swap	d0
	move.l	d0,OLP
	.if	!(DISPLAY_USE_OP_IT&!DISPLAY_OP_IT_COMP_PT)
	clr.l	active_display_list
	.endif
	clr.w	displayCounter
	;; copy GPU code
	pea	DISPLAY_DRIVER_SIZE	
	pea	G_RAM
	pea	gpu_display_driver
	jsr	_bcopy
	lea	12(sp),sp
	;; set GPU for interrupts
	move.l	#REGPAGE,G_FLAGS
	;; launch the driver
	move.l	#GPU_SUBROUT_ADDR,a0
	move.l	#$ffffffff,(a0)
	move.l	#DISPLAY_DRIVER_INIT,G_PC
	move.l	#GPUGO,G_CTRL
.wait_init:
	tst.l	(a0)
	bne.s	.wait_init
	move.w	#0,OBF
	rts

	.globl	_show_display
_show_display:
	move.l	4(sp),d0
	.if	!(DISPLAY_USE_OP_IT&!DISPLAY_OP_IT_COMP_PT)
	move.l	d0,active_display_list
	.endif
	add.l	#DISPLAY_LIST,d0
	swap	d0
	move.l	d0,OLP
	rts

	.globl	_hide_display
_hide_display:
	move.l	#_stop_object,d0
	swap	d0
	move.l	d0,OLP
	rts
	
	.globl	_jump_gpu_subroutine
_jump_gpu_subroutine:
	move.l	4(sp),GPU_SUBROUT_ADDR
	rts

	.globl	_wait_display_refresh
_wait_display_refresh:
	move.l	#_vblCounter,a0
	move.l	#displayCounter,a1
.wait:
	move.w	(a0),d0		; inside the loop because interrupts can occur at any time
	cmp.w	(a1),d0
	bne.s	.wait
	rts

	.bss
	
	.if	!(DISPLAY_USE_OP_IT&!DISPLAY_OP_IT_COMP_PT)	
	.long
active_display_list:	ds.l	1
	.endif

	.bss
displayCounter:	
	ds.w	1
			
	.data
	.even
	dc.b	"Display Driver by Seb/The Removers"
	.even


