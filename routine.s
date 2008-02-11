	.if	^^defined	ROUTINE_H
	.print	"routine.s already included"
	end
	.endif
ROUTINE_H	equ	1
	.print	"including routine.s"

 	.extern	DSP_SUBROUT_ADDR
.macro	jsr_dsp
	;; \1: address of the subroutine
	move.l	\1,DSP_SUBROUT_ADDR
.endm

	.extern	GPU_SUBROUT_ADDR
.macro	jsr_gpu
	;; \1: address of the subroutine
	move.l	\1,GPU_SUBROUT_ADDR
.endm

	.offset	0
ROUTINE_KIND:	ds.l	1
ROUTINE_ADDR:	ds.l	1
ROUTINE_LENGTH:	ds.l	1
ROUTINE_PARAMS:	ds.l	1
ROUTINE_NB_SUBROUTS:	ds.l	1
	
	.text
GPU_ROUTINE	equ	(1<<0)
DSP_ROUTINE	equ	(1<<1)

