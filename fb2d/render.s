	.include	"jaguar.inc"
	.include	"screen_def.s"

	.globl	_draw_point
;;; void draw_point(screen *scr, int color, fixp x, fixp y)
_draw_point:
	move.l	4(sp),a0
	move.l	12(sp),d0
	blt.s	.skip
	move.l	16(sp),d1
	blt.s	.skip
	swap	d0
	cmp.w	SCREEN_W(a0),d0
	bge.s	.skip
	swap	d1
	cmp.w	SCREEN_H(a0),d1
	bge.s	.skip
	swap	d1
	move.w	d0,d1		; Y|X
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	SCREEN_FLAGS(a0),A2_FLAGS
	move.l	d1,A2_PIXEL
	move.l	#(1<<16)|1,B_COUNT
	move.l	8(sp),d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	#DSTA2|PATDSEL,B_CMD
	wait_blitter	d0
.skip:
	rts

	