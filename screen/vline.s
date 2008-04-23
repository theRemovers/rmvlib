	.include	"jaguar.inc"
	.include	"screen_def.s"

	.68000
	.text

	.globl	_vline
;;; void vline(screen *scr, int x, int ymin, int ymax, int color)
_vline:
	move.w	8+2(sp),d0	; X
	blt	.skip
	move.l	4(sp),a0	; scr
	cmp.w	SCREEN_W(a0),d0
	bge	.skip
	swap	d0
	move.w	12+2(sp),d0	; Ymin
	bge.s	.clip_ymin
	clr.w	d0
.clip_ymin:
	move.w	16+2(sp),d1	; Ymax
	addq.w	#1,d1
	cmp.w	SCREEN_H(a0),d1
	blt.s	.clip_ymax
	move.w	SCREEN_H(a0),d1
.clip_ymax:
	sub.w	d0,d1		; H
	ble.s	.skip
	swap	d1
	move.w	#1,d1
	swap	d0
	move.l	SCREEN_DATA(a0),A2_BASE
	move.l	d0,A2_PIXEL
	move.l	d1,B_COUNT
	move.l	20(sp),d0
	move.l	d0,B_PATD
	move.l	d0,B_PATD+4
	move.l	SCREEN_FLAGS(a0),d0
	move.w	d0,d1
	lsr.w	#3,d1
	and.w	#%111,d1
	cmp.w	#3,d1
	bhs.s	.depth_ge_8
.depth_lt_8:
	move.l	#DSTA2|DSTEN|PATDSEL|UPDA2,d1
	bra.s	.depth_ok
.depth_ge_8:
	move.l	#DSTA2|PATDSEL|UPDA2,d1
.depth_ok:
	or.l	#XADD0,d0
	move.l	d0,A2_FLAGS
	moveq	#0,d0
	move.w	SCREEN_W(a0),d0
	move.l	d0,A2_STEP
	move.l	d1,B_CMD
	wait_blitter	d0
.skip:
	rts

