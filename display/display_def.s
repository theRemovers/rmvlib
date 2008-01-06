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

	.offset	0
	;; these two fields must be at the beginning in this order (see hashtbl)
	;; an attached sprite has always previous != NULL
SPRITE_PREVIOUS:	ds.l	1
SPRITE_NEXT:		ds.l	1
	.phrase
	;; the following phrase is a template of the second phrase
	;; of bitmap/scaled bitmap object
	;; but some other information is also encoded
	;; such as HEIGHT or TYPE
SPRITE_SND_PHRASE:
	;; WORD1
	;; TAVH0000 0FFFFFFB
	;; T = TYPE (0 = unscaled, 1 = scaled)
	;; A = Animation (0 = Off, 1 = On)
	;; V = Visible (0 = Yes, 1 = No)
	;; H = Hotspot (0 = No, 1 = Yes)
	;; FFFFFF = FIRSTPIX
	;; B = RELEASE
SPRITE_WORD1:		ds.w	1
	;; WORD2
	;; tRriiiii iiIIIIII
	;; t = TRANS
	;; R = RMW
	;; r = REFLECT
	;; iiiiiii = INDEX
SPRITE_WORD2:		ds.w	1
	;; WORD3
	;; IIIIWWWW WWWWWWPP
	;; iiiiiiiiii = IWIDTH
	;; WWWWWWWWWW = DWIDTH
SPRITE_WORD3:		ds.w	1
	;; WORD4
	;; Pddd00HH HHHHHHHH
	;; PPP = PITCH
	;; ddd = DEPTH
	;; HHHHHHHHHH = HEIGHT (this the real height, before adjustment for scaled objects)
SPRITE_WORD4:		ds.w	1
	.long
SPRITE_Y:		ds.w	1
SPRITE_X:		ds.w	1
	.long
SPRITE_HY:		ds.w	1
SPRITE_HX:		ds.w	1
	.long
SPRITE_SCALE:		ds.b	1 ; padding
SPRITE_REMAINDER:	ds.b	1
SPRITE_VSCALE:		ds.b	1
SPRITE_HSCALE:		ds.b	1
	.long
SPRITE_DATA:		ds.l	1 ; used if Animation if Off
SPRITE_ANIM_ARRAY:	ds.l	1 ; must be defined is Animation is On
SPRITE_ANIM_DATA:
SPRITE_ANIM_COUNTER:	ds.w	1
	;; bit #15: has looped
	;; other bits: index in the animation
SPRITE_ANIM_INDEX:	ds.w	1
	.long
SPRITE_SIZEOF:		ds.l	0
	
SPRITE_TYPE		equ	31
SPRITE_ANIM_ON_OFF	equ	30
SPRITE_INVISIBLE	equ	29
SPRITE_USE_HOTSPOT	equ	28
SPRITE_REFLECT		equ	13
		
MASK_HEIGHT	equ	$3ff		; 10 bits in WORD4
MASK_DEPTH	equ	$7000		; 3 bits in WORD4
MASK_PITCH	equ	$00038000	; 3 bits in WORD3/WORD4
MASK_DWIDTH	equ	$0ffc		; 10 bits in WORD3
MASK_IWIDTH	equ	$003ff000	; 10 bits in WORD2/WORD3 
MASK_INDEX	equ	$1fc0		; 7 bits in WORD2 
MASK_FIRSTPIX	equ	$007e		; 6 bits in WORD1 

MASK_XPOS	equ	$fff
MASK_YPOS	equ	$7ff

