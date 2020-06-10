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

	.include	"../jaguar.inc"
	.include	"screen_def.s"

	.68000
	.text

        .globl  _line
;;; void line(screen *scr, int x1, int y1, int x2, int y2, int color)
_line:
        move.l  d2,-(sp)
        move.l  8(sp),a0        ; scr
        ;; set pattern data
        move.l  8+(5*4)+0(sp),d0     ; color
        move.l  d0,B_PATD
        move.l  d0,B_PATD+4
        ;; set base address and clipping window
        move.l  SCREEN_DATA(a0),A1_BASE
        move.l  SCREEN_H(a0),A1_CLIP ; clipping window
        ;;
        move.w  8+(1*4)+2(sp),d1      ; X1
        move.w  8+(2*4)+2(sp),d2      ; Y1
        swap    d2
        move.w  d1,d2           ; Y1|X1
        move.l  d2,A1_PIXEL     ; Y1|X1
        move.l  #$80008000,A1_FPIXEL

        sub.w   8+(3*4)+2(sp),d1  ; X1-X2
        beq     .vline
        swap    d2
        sub.w   8+(4*4)+2(sp),d2  ; Y1-Y2
        beq     .hline
        bgt     .dy_pos
        ;; d1 = X1-X2 <> 0
        ;; d2 = Y1-Y2 <> 0
.dy_neg:
        neg.w   d2              ; Y2-Y1
        tst.w   d1
        bgt     .dy_neg_dx_pos
.dy_neg_dx_neg:
        neg.w   d1
        ;; d2 = Y2-Y1 > 0
        ;; d1 = X2-X1 > 0
        cmp.w   d1,d2
        bgt     .oct2
        bne.s   .oct1
        ;; X2-X1 = Y2-Y1
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        move.l  #0,A1_FINC
        move.l  #$00010001,A1_INC
        bra     .continue
.oct1:
        ;; 0 < Y2-Y1 < X2-X1
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d2
        clr.w   d2
        divu.w  d1,d2           ; 0 < Y2-Y1/X2-X1 < 1
        swap    d2
        move.w  #0,d2
        move.l  d2,A1_FINC
        move.l  #$00000001,A1_INC
        bra     .continue
.oct2:
        ;; 0 < X2-X1 < Y2-Y1
        moveq   #1,d0
        swap    d0
        move.w  d2,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d1
        clr.w   d1
        divu.w  d2,d1           ; 0 < X2-X1/Y2-Y1 < 1
        swap    d1
        move.w  #0,d1
        swap    d1
        move.l  d1,A1_FINC
        move.l  #$00010000,A1_INC
        bra     .continue
.dy_neg_dx_pos:
        ;; d2 = Y2-Y1 > 0
        ;; d1 = X1-X2 > 0
        cmp.w   d1,d2
        blt     .oct4
        bne.s   .oct3
        ;; X1-X2 = Y2-Y1
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        move.l  #0,A1_FINC
        move.l  #$0001ffff,A1_INC
        bra     .continue
.oct3:
        ;; 0 < X1-X2 < Y2-Y1
        moveq   #1,d0
        swap    d0
        move.w  d2,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d1
        clr.w   d1
        divu.w  d2,d1           ; 0 < X1-X2/Y2-Y1 < 1
        neg.w   d1
        swap    d1
        move.w  #0,d1
        swap    d1
        move.l  d1,A1_FINC
        move.l  #$0001ffff,A1_INC
        bra     .continue
.oct4:
        ;; 0 < Y2-Y1 < X1-X2
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d2
        clr.w   d2
        divu.w  d1,d2           ; 0 < Y2-Y1/X1-X2 < 1
        swap    d2
        move.w  #0,d2
        move.l  d2,A1_FINC
        move.l  #$0000ffff,A1_INC
        bra     .continue
.dy_pos:
        tst.w   d1
        bgt     .dy_pos_dx_pos
.dy_pos_dx_neg:
        neg.w   d1
        ;; d2 = Y1-Y2 > 0
        ;; d1 = X2-X1 > 0
        cmp.w   d1,d2
        blt     .oct8
        bne.s   .oct7
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        move.l  #0,A1_FINC
        move.l  #$ffff0001,A1_INC
        bra     .continue
.oct7:
        ;; 0 < X2-X1 < Y1-Y2
        moveq   #1,d0
        swap    d0
        move.w  d2,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d1
        clr.w   d1
        divu.w  d2,d1           ; 0 < X2-X1/Y1-Y2 < 1
        swap    d1
        move.w  #0,d1
        swap    d1
        move.l  d1,A1_FINC
        move.l  #$ffff0000,A1_INC
        bra     .continue
.oct8:
        ;; 0 < Y1-Y2 < X2-X1
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d2
        clr.w   d2
        divu.w  d1,d2           ; 0 < Y1-Y2/X2-X1 < 1
        neg.w   d2
        swap    d2
        move.w  #0,d2
        move.l  d2,A1_FINC
        move.l  #$ffff0001,A1_INC
        bra     .continue
.dy_pos_dx_pos:
        ;; d2 = Y1-Y2 > 0
        ;; d1 = X1-X2 > 0
        cmp.w   d1,d2
        bgt     .oct6
        bne.s   .oct5
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        move.l  #0,A1_FINC
        move.l  #$ffffffff,A1_INC
        bra     .continue
.oct5:
        ;; 0 < Y1-Y2 < X1-X2
        moveq   #1,d0
        swap    d0
        move.w  d1,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d2
        clr.w   d2
        divu.w  d1,d2           ; 0 < Y1-Y2/X1-X2 < 1
        neg.w   d2
        swap    d2
        move.w  #0,d2
        move.l  d2,A1_FINC
        move.l  #$ffffffff,A1_INC
        bra.s   .continue
.oct6:
        ;; 0 < X1-X2 < Y1-Y2
        moveq   #1,d0
        swap    d0
        move.w  d2,d0
        addq.w  #1,d0
        move.l  d0,B_COUNT
        swap    d1
        clr.w   d1
        divu.w  d2,d1           ; 0 < X1-X2/Y1-Y2 < 1
        neg.w   d1
        swap    d1
        move.w  #0,d1
        swap    d1
        move.l  d1,A1_FINC
        move.l  #$ffffffff,A1_INC
.continue:
        move.l  SCREEN_FLAGS(a0),d0
        or.l    #XADDINC,d0
        move.l  d0,A1_FLAGS
        move.l  #CLIP_A1|DSTEN|PATDSEL,B_CMD
        wait_blitter    d0
        move.l  (sp)+,d2
        rts
;;; vertical line (X1 = X2)
.vline:
        move.l  SCREEN_FLAGS(a0),d0
        or.l    #XADD0|YSIGNSUB|YADD1,d0
        move.w  #1,d2           ; repeat outer loop 1 time
        swap    d2
        sub.w   8+(4*4)+2(sp),d2  ; Y1-Y2
        bge.s   .vline_dy_ok
        neg.w   d2
        and.l   #~YSIGNSUB,d0
.vline_dy_ok:
        addq.w  #1,d2
        move.l  d2,B_COUNT
        move.l  d0,A1_FLAGS
        move.l  #CLIP_A1|DSTEN|PATDSEL,B_CMD
        wait_blitter    d0
        move.l  (sp)+,d2
        rts
;;; horizontal line (X1 <> X2, Y1 = Y2)
.hline:
        move.l  SCREEN_FLAGS(a0),d0
        or.l    #XADDPIX|XSIGNSUB,d0
        tst.w   d1
        bge.s   .hline_dx_ok
        neg.w   d1
        and.l    #~XSIGNSUB,d0
.hline_dx_ok:
        addq.w  #1,d1
        swap    d1
        move.w  #1,d1
        swap    d1
        move.l  d1,B_COUNT
        move.l  d0,A1_FLAGS
        move.l  #CLIP_A1|DSTEN|PATDSEL,B_CMD
        wait_blitter    d0
        move.l  (sp)+,d2
        rts
