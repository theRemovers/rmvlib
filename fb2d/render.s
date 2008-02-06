	.include	"jaguar.inc"
	.include	"screen_def.s"

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

	