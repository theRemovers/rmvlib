	.include	"jaguar.inc"
	.include	"screen_def.s"

	.offset	0
PIXEL_X:	ds.w	1
PIXEL_Y:	ds.w	1
PIXEL_SIZEOF:	ds.l	0

	.68000
	.text
	
	.globl	_put_pixels
;;; void draw_points(screen *scr, int color, int nb, pixel pixels[])
_put_pixels:
	movem.l	d2-d3,-(sp)
	move.w	8+12+2(sp),d0	; nb vertices
	subq.w	#1,d0
	blo.s	.end
	move.l	8+4(sp),a0	; scr
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	SCREEN_FLAGS(a0),A2_FLAGS
	move.l	8+8(sp),d2
	move.l	d2,B_PATD
	move.l	d2,B_PATD+4	
	move.w	SCREEN_W(a0),d2
	move.w	SCREEN_H(a0),d3
	move.l	8+16(sp),a1	; vertices
.draw:
	move.w	PIXEL_Y(a1),d1	; Y
	blt.s	.skip
	cmp.w	d3,d1
	bge.s	.skip
	swap	d1
	move.w	PIXEL_X(a1),d1	; X
	blt.s	.skip
	cmp.w	d2,d1
	bge.s	.skip
	move.l	d1,A2_PIXEL
	move.l	#(1<<16)|1,B_COUNT
	move.l	#DSTA2|PATDSEL,B_CMD	
.skip:
	addq.w	#PIXEL_SIZEOF,a1		; next vertex
	;; we assume that the blitter will be
	;; fast enough to draw each point
	;; so we do not wait for it
	dbf	d0,.draw
	;; we only wait at the end
	wait_blitter	d0
.end:
	movem.l	(sp)+,d2-d3
	rts
