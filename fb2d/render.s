	.include	"jaguar.inc"
	.include	"screen_def.s"

	.offset	0
VERTEX_X:	ds.l	1
VERTEX_Y:	ds.l	1
VERTEX_SIZEOF:	ds.l	0

	.68000
	.text
	
	.globl	_draw_point
;;; void draw_point(screen *scr, int color, fixp x, fixp y)
_draw_point:
	move.l	4(sp),a0
	move.w	16(sp),d0	; integer part of Y
	blt.s	.skip
	cmp.w	SCREEN_H(a0),d0
	bge.s	.skip
	swap	d0
	move.w	12(sp),d0	; integer part of X
	blt.s	.skip
	cmp.w	SCREEN_W(a0),d0
	bge.s	.skip
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	SCREEN_FLAGS(a0),A2_FLAGS
	move.l	d0,A2_PIXEL
	move.l	#(1<<16)|1,B_COUNT
	move.l	8(sp),d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#DSTA2|PATDSEL,B_CMD
	wait_blitter	d0
.skip:
	rts

	.globl	_draw_vertices
;;; void draw_vertices(screen *scr, int color, int nb, vertex *vertices)
_draw_vertices:
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
	move.w	VERTEX_Y(a1),d1	; integer part of Y
	blt.s	.skip
	cmp.w	d3,d1
	bge.s	.skip
	swap	d1
	move.w	VERTEX_X(a1),d1
	blt.s	.skip
	cmp.w	d2,d1
	bge.s	.skip
	move.l	d1,A2_PIXEL
	move.l	#(1<<16)|1,B_COUNT
	move.l	#DSTA2|PATDSEL,B_CMD	
.skip:
	addq.w	#VERTEX_SIZEOF,a1		; next vertex
	;; we assume that the blitter will be
	;; fast enough to draw each point
	;; so we do not wait for it
	dbf	d0,.draw
	;; we only wait at the end
	wait_blitter	d0
.end:
	movem.l	(sp)+,d2-d3
	rts
	