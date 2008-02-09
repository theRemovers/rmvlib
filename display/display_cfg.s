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
	;; use OP interrupt instead of CPU interrupt
	.if	^^defined	DISPLAY_USE_OP_IT
	.else
DISPLAY_USE_OP_IT	equ	1
	.endif

	;; use compatibility mode with Project Tempest for OP interrupt
	.if	^^defined	DISPLAY_OP_IT_COMP_PT
	.else
DISPLAY_OP_IT_COMP_PT	equ	1
	.endif

	;; show working mode with help of BG color
	.if	^^defined	DISPLAY_BG_IT
	.else
DISPLAY_BG_IT		equ	0
	.endif

	;; to save/restore registers in the interrupt handler
	.if	^^defined	DISPLAY_IT_SAVE_REGS
	.else
DISPLAY_IT_SAVE_REGS	equ	0
	.endif

	;; mode of division
	.if	^^defined	GPU_DIV_FRAC
	.else
GPU_DIV_FRAC	equ	0
	.endif
	
	.if	DISPLAY_USE_OP_IT
	.print	"The display manager will use OP interrupt"
	.if	DISPLAY_OP_IT_COMP_PT
	.print	"It will use Project Tempest compatibility mode for OP interrupt"
	.endif
	.else
	.print	"The display manager will use CPU interrupt"	
	.endif

	.if	DISPLAY_BG_IT
	.print	"The BG color will be used to indicate the display manager setting"
	.endif

	.if	DISPLAY_IT_SAVE_REGS
	.print	"The interrupt handler will save & restore used registers (except r28 to r30)"
	.else
	.print	"The interrupt handler will **not** save used registers"
	.endif

	.if	GPU_DIV_FRAC
	.print	"Division mode is 16.16"
	.else
	.print	"Division mode is 32"
	.endif
	
	;; BG = RED -> CPU interrupt
DISPLAY_BG_CPU		equ	$f800
	;; BG = BLUE -> OP interrupt
DISPLAY_BG_OP		equ	$07c0

	.if	(SPRITE_PREVIOUS <> 0)
	.fail
	.endif
	.if	(SPRITE_NEXT <> 4)
	.fail
	.endif
	
DISPLAY_NB_LAYER	equ	4	; 2^DISPLAY_NB_LAYER
DISPLAY_DFLT_MAX_SPRITE	equ	256	;
	
;; DISPLAY_LOG_NB_STRIPS	equ	3
DISPLAY_NB_STRIPS	equ	(1<<DISPLAY_LOG_NB_STRIPS)

DISPLAY_STRIP_TREE_SIZEOF	equ	(16*((8*(3*(1<<(DISPLAY_LOG_NB_STRIPS-1))+2)+16-1)/16))

	.offset	0
DISPLAY_PHYS:		ds.l	1
DISPLAY_LOG:		ds.l	1
	.long
DISPLAY_Y:		ds.w	1
DISPLAY_X:		ds.w	1
	.phrase
DISPLAY_LIST:	
DISPLAY_LIST_OB1:	ds.l	2	; if vde < VC then STOP
DISPLAY_LIST_OB2:	ds.l	2	; if vdb > VC then STOP
DISPLAY_LIST_OB3:	ds.l	2	; if vdb = VC then GPU
DISPLAY_LIST_OB4:	ds.l	2	; if true then DISPLAY_PHYS
DISPLAY_LIST_OB5:	ds.l	2	; GPU
DISPLAY_LIST_OB6:	ds.l	2	; if true then OB4
DISPLAY_LIST_OB7:	ds.l	2	; STOP
	.long
DISPLAY_STRIPS:
	.rept	DISPLAY_NB_STRIPS+1
	ds.l	1		; Y
	ds.l	1		; offset
	.endr
	.long
DISPLAY_HASHTBL:
	.rept	(1<<DISPLAY_NB_LAYER)
	ds.l	1		; attribute
	ds.l	1		; Y|X
	ds.l	1		; previous
	ds.l	1		; next
	.endr
	.qphrase 
DISPLAY_SIZEOF:		ds.l	0

