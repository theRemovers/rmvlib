	.text
	
	.include	"skunk.s"

	.text
	.68000

	.globl	_skunkRESET
	.globl	_skunkNOP
	.globl	_skunkCONSOLEWRITE
	.globl	_skunkCONSOLECLOSE
	.globl	_skunkCONSOLEREAD
	.globl	_skunkFILEOPEN
	.globl	_skunkFILEWRITE
	.globl	_skunkFILEREAD
	.globl	_skunkFILECLOSE

	
_skunkRESET:
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkRESET
	movem.l	(sp)+,d2-d7/a2-a6
	rts

_skunkNOP:
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkNOP
	movem.l	(sp)+,d2-d7/a2-a6
	rts

_skunkCONSOLEWRITE:
	move.l	4(sp),a0	; buffer address
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkCONSOLEWRITE
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
_skunkCONSOLECLOSE:
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkCONSOLECLOSE
	movem.l	(sp)+,d2-d7/a2-a6
	rts

_skunkCONSOLEREAD:
	move.l	4(sp),a0	; buffer address
	move.l	8(sp),d0	; length
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkCONSOLEREAD
	movem.l	(sp)+,d2-d7/a2-a6
	rts

_skunkFILEOPEN:
	move.l	4(sp),a0	; filename
	move.l	8(sp),d0	; read/write mode
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkFILEOPEN
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
_skunkFILEWRITE:
	move.l	4(sp),a0	; buffer address
	move.l	8(sp),d0	; length
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkFILEWRITE
	movem.l	(sp)+,d2-d7/a2-a6
	move.l	a0,d0		; updated buffer address
	rts
	
_skunkFILEREAD:
	move.l	4(sp),a0	; buffer address
	move.l	8(sp),d0
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkFILEREAD
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
_skunkFILECLOSE:
	movem.l	d2-d7/a2-a6,-(sp)
	bsr	skunkFILECLOSE
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
