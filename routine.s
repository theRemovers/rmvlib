	.if	^^defined	__ROUTINE_H
	.print	"routine.s already included"
	end
	.endif
__ROUTINE_H	equ	1
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

