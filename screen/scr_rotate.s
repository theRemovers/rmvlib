; The Removers'Library
; Copyright (C) 2006-2020 Seb/The Removers
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
	.include	"screen_def.inc"

.macro	imul16_16
	;; \1 = a fixpoint 16.16 value
	;; \2 = a POSITIVE integer (15 bits)
	;; \3 = temporary register
	;; \1 is preserved
	;; result goes into \2
	move.w	\2,\3
	mulu.w	\1,\3		; fractional part
	swap	\1
	muls.w	\1,\2		; integer part
	swap	\1
	swap	\2		; shift 16
	clr.w	\2
	add.l	\3,\2		; add fractional part
.endm
        
	.globl	_screen_rotate
;;; void screen_rotate(screen *src, screen *dst, int alpha)        
_screen_rotate:
        movem.l d2-d7,-(sp)
        move.l  6*4+4(sp),a0        ; src
        move.l  6*4+4+4(sp),a1      ; dst
        move.w  6*4+4+(4*2)+2(sp),d1 ; alpha
        ;; 
        move.l  SCREEN_DATA(a0),A1_BASE
        move.l  SCREEN_FLAGS(a0),d0
        or.l    #XADDINC,d0
        move.l  d0,A1_FLAGS
        move.l  SCREEN_H(a0),A1_CLIP ; set clipping zone to screen height and width
        ;;
        move.l  SCREEN_DATA(a1),A2_BASE
        move.l  SCREEN_FLAGS(a1),d0
        move.l  SCREEN_H(a1),d4 ; H|W
        or.l    #XADDPIX,d0
        move.l  d0,A2_FLAGS
        move.l  #0,A2_PIXEL
        moveq   #1,d0
        swap    d0      
        move.w  d4,d0 ; 1|W
        neg.w   d0    ; 1|-W
        move.l  d0,A2_STEP
        ;;
        move.l  d4,B_COUNT      ; H|W
        ;;
        bsr     get_cos_and_sin ; d1(16.16) = cos(alpha), d2(16.16) = sin(alpha)
        ;; set fractional part of increment
	move.w	d2,d0
	swap	d2
	swap	d0
	move.w	d1,d0
	swap	d1
	move.l	d0,A1_FINC
        ;; set integer part of increment
	move.w	d2,d0
	swap	d2
	swap	d0
	move.w	d1,d0
	swap	d1
	move.l	d0,A1_INC
	;; compute A1_STEP/FSTEP
        move.w  d4,d3    ; W
	imul16_16	d1,d3,d7 ; W*cos(alpha)
	imul16_16	d2,d4,d7 ; W*sin(alpha)
	move.l	d2,d5
	neg.l	d5		; -sin(alpha)
	sub.l	d3,d5		; -sin(alpha)-W*cos(alpha)
	move.l	d1,d6		; cos(alpha)
	sub.l	d4,d6		; cos(alpha)-W*sin(alpha)
        ;; 
	move.w	d6,d0
	swap	d6
	swap	d0
	move.w	d5,d0
	swap	d5
	move.l	d0,A1_FSTEP
	;; 
	move.w	d6,d0
	swap	d0
	move.w	d5,d0
	move.l	d0,A1_STEP
        ;; compute A1_PIXEL/FPIXEL
        move.w  SCREEN_X(a1),d3 ; Xcenter: center in target image
	imul16_16	d1,d3,d7 ; XCenter*cos(alpha)
        move.w  SCREEN_Y(a1),d4  ; Ycenter: center in target image
	imul16_16	d2,d4,d7 ; YCenter*sin(alpha)
	sub.l	d4,d3		; XCenter*cos - YCenter*sin
        moveq   #0,d4
        move.w  SCREEN_X(a0),d4 ; Xo: center in source image
        swap    d4
	sub.l	d3,d4		; Xo - (XCenter*cos - YCenter*sin)
	move.w	SCREEN_X(a1),d3
	imul16_16	d2,d3,d7 ; XCenter*sin(alpha)
	move.w	SCREEN_Y(a1),d5
	imul16_16	d1,d5,d7 ; YCenter*cos(alpha)
	add.l	d5,d3		; XCenter*sin + YCenter*cos
	neg.l	d3
        moveq   #0,d7
        move.w  SCREEN_Y(a0),d7
        swap    d7
        add.l   d7,d3           ; Yo - (XCenter*sin + YCenter*cos)
	exg.l	d3,d4
        ;; 
	move.w	d4,d0
	swap	d4
	swap	d0
	move.w	d3,d0
	swap	d3
	move.l	d0,A1_FPIXEL
        ;; 
	move.w	d4,d0
	swap	d0
	move.w	d3,d0
	move.l	d0,A1_PIXEL
        ;; 
	move.l	#CLIP_A1|UPDA1|UPDA1F|UPDA2|LFU_REPLACE|SRCEN|DSTA2,B_CMD
        wait_blitter d0
        movem.l (sp)+,d2-d7
        rts

get_cos_and_sin:
	;; input
	;; d1 = angle
	;; output
	;; d1 = cosinus
	;; d2 = sinus
	move.l	a0,-(sp)
	move.l	#cos_table,a0
	and.w	#$ff,d1
	move.w	d1,d2
	add.b	#256/4,d2	; add pi/2 (mod 256, note the .b)
	add.w	d1,d1
	add.w	d2,d2
	add.w	d1,d1
	add.w	d2,d2
	move.l	(a0,d1.w),d1
	move.l	(a0,d2.w),d2
	move.l	(sp)+,a0
	rts
	
	.data
	.long
cos_table:	
	dc.l	$00010000, $0000FFEC, $0000FFB1, $0000FF4E, $0000FEC4, $0000FE13, $0000FD3B, $0000FC3B
	dc.l	$0000FB15, $0000F9C8, $0000F854, $0000F6BA, $0000F4FA, $0000F314, $0000F109, $0000EED9
	dc.l	$0000EC83, $0000EA0A, $0000E76C, $0000E4AA, $0000E1C6, $0000DEBE, $0000DB94, $0000D848
	dc.l	$0000D4DB, $0000D14D, $0000CD9F, $0000C9D1, $0000C5E4, $0000C1D8, $0000BDAF, $0000B968
	dc.l	$0000B505, $0000B086, $0000ABEB, $0000A736, $0000A268, $00009D80, $00009880, $00009368
	dc.l	$00008E3A, $000088F6, $0000839C, $00007E2F, $000078AD, $0000731A, $00006D74, $000067BE
	dc.l	$000061F8, $00005C22, $0000563E, $0000504D, $00004A50, $00004447, $00003E34, $00003817
	dc.l	$000031F1, $00002BC4, $00002590, $00001F56, $00001918, $000012D5, $00000C90, $00000648
	dc.l	$00000000, $FFFFF9B9, $FFFFF371, $FFFFED2C, $FFFFE6E9, $FFFFE0AB, $FFFFDA71, $FFFFD43D
	dc.l	$FFFFCE10, $FFFFC7EA, $FFFFC1CD, $FFFFBBBA, $FFFFB5B1, $FFFFAFB4, $FFFFA9C3, $FFFFA3DF
	dc.l	$FFFF9E09, $FFFF9843, $FFFF928D, $FFFF8CE7, $FFFF8754, $FFFF81D2, $FFFF7C65, $FFFF770B
	dc.l	$FFFF71C7, $FFFF6C99, $FFFF6781, $FFFF6281, $FFFF5D99, $FFFF58CB, $FFFF5416, $FFFF4F7B
	dc.l	$FFFF4AFC, $FFFF4699, $FFFF4252, $FFFF3E29, $FFFF3A1D, $FFFF3630, $FFFF3262, $FFFF2EB4
	dc.l	$FFFF2B26, $FFFF27B9, $FFFF246D, $FFFF2143, $FFFF1E3B, $FFFF1B57, $FFFF1895, $FFFF15F7
	dc.l	$FFFF137E, $FFFF1128, $FFFF0EF8, $FFFF0CED, $FFFF0B07, $FFFF0947, $FFFF07AD, $FFFF0639
	dc.l	$FFFF04EC, $FFFF03C6, $FFFF02C6, $FFFF01EE, $FFFF013D, $FFFF00B3, $FFFF0050, $FFFF0015
	dc.l	$FFFF0001, $FFFF0015, $FFFF0050, $FFFF00B3, $FFFF013D, $FFFF01EE, $FFFF02C6, $FFFF03C6
	dc.l	$FFFF04EC, $FFFF0639, $FFFF07AD, $FFFF0947, $FFFF0B07, $FFFF0CED, $FFFF0EF8, $FFFF1128
	dc.l	$FFFF137E, $FFFF15F7, $FFFF1895, $FFFF1B57, $FFFF1E3B, $FFFF2143, $FFFF246D, $FFFF27B9
	dc.l	$FFFF2B26, $FFFF2EB4, $FFFF3262, $FFFF3630, $FFFF3A1D, $FFFF3E29, $FFFF4252, $FFFF4699
	dc.l	$FFFF4AFC, $FFFF4F7B, $FFFF5416, $FFFF58CB, $FFFF5D99, $FFFF6281, $FFFF6781, $FFFF6C99
	dc.l	$FFFF71C7, $FFFF770B, $FFFF7C65, $FFFF81D2, $FFFF8754, $FFFF8CE7, $FFFF928D, $FFFF9843
	dc.l	$FFFF9E09, $FFFFA3DF, $FFFFA9C3, $FFFFAFB4, $FFFFB5B1, $FFFFBBBA, $FFFFC1CD, $FFFFC7EA
	dc.l	$FFFFCE10, $FFFFD43D, $FFFFDA71, $FFFFE0AB, $FFFFE6E9, $FFFFED2C, $FFFFF371, $FFFFF9B9
	dc.l	$00000000, $00000648, $00000C90, $000012D5, $00001918, $00001F56, $00002590, $00002BC4
	dc.l	$000031F1, $00003817, $00003E34, $00004447, $00004A50, $0000504D, $0000563E, $00005C22
	dc.l	$000061F8, $000067BE, $00006D74, $0000731A, $000078AD, $00007E2F, $0000839C, $000088F6
	dc.l	$00008E3A, $00009368, $00009880, $00009D80, $0000A268, $0000A736, $0000ABEB, $0000B086
	dc.l	$0000B505, $0000B968, $0000BDAF, $0000C1D8, $0000C5E4, $0000C9D1, $0000CD9F, $0000D14D
	dc.l	$0000D4DB, $0000D848, $0000DB94, $0000DEBE, $0000E1C6, $0000E4AA, $0000E76C, $0000EA0A
	dc.l	$0000EC83, $0000EED9, $0000F109, $0000F314, $0000F4FA, $0000F6BA, $0000F854, $0000F9C8
	dc.l	$0000FB15, $0000FC3B, $0000FD3B, $0000FE13, $0000FEC4, $0000FF4E, $0000FFB1, $0000FFEC
