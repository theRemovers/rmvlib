; Skunkboard console support functions (68k)
; Code by Tursi/M.Brent http://www.harmlesslion.com
; Orig:5 July 2008
; Rev: 3 Sep 2008  - added skunkNOP
; Rev: 7 Sep 2008  - added double confirm with data from PC, increased timeouts
; Rev: 16 Oct 2008 - Made the console close function wait for both buffers
; 
; This file is licensed freely and may be used for any purpose, commercial or
; otherwise, without notice or compensation.
;
; All console functions will delay if buffers are full, 
; and will time out if they stay full. If the console reconnects
; then they should resume but previous accesses are lost.
; If your program *relies* on the console input then it
; should test skunkConsoleUp after a call.
;
; You should not use these functions in your production cartridge,
; rather create dummy stubs that do nothing or comment the calls out 
; in your code. Without the Skunkboard they may work, they may not, 
; there are no guarantees.
;
; None of these functions are 'thread safe' so you should resist
; calling them from interrupts.
;
; All addresses must be on a word boundary. All lengths must be
; even, except text writes may be an odd count (but an even number
; of bytes are still read and transmitted).
;

;---------------------------------------------------------------------

	.globl	_skunk_init
	.globl	_skunk_asynchronous_request
	.globl	_skunk_synchronous_request	
	
;---------------------------------------------------------------------

	.text
	.68000
	
timeout	.equ	200000

ASYNC_MSG	equ	1
SYNC_MSG	equ	2

MSGHDRSZ	equ	6
	
_skunk_init:
	movem.l	a1-a2,-(sp)
	move.l	#-1,skunkConsoleUp	; optimistic!

	bsr	setAddresses		; get HPI addresses into a1 & a2
					; try and get both buffers, that tells us the console is up
	bsr	getBothBuffers		; also sets skunkConsoleUp

	movem.l (sp)+,a1-a2			; Restore regs
	rts

_skunk_is_up:
	move.l	skunkConsoleUp,d0
	rts
	
;;; int skunk_synchronous_request(Message *request, Message *reply)
_skunk_synchronous_request:
	moveq	#SYNC_MSG,d0
	bra.s	emit_request
;;; int skunk_asynchronous_request(Message *request)
_skunk_asynchronous_request:
	moveq	#ASYNC_MSG,d0
emit_request:
	movem.l	d2-d4/a2,-(sp)
	move.w	d0,d3		; save request type
	
	bsr	setAddresses
	bsr	getBuffer
	moveq	#-1,d0		; failure
	tst.l	d1
	beq	.exit

	;; emit request
	move.l	4+(4*4)(sp),a0	; get request message
	
	move.w	#$4004,(a1)	; enter HPI write mode
	move.w	d1,(a1)		; set write address

	;; write header
	move.w	#$ffff,(a2)	
	move.w	d3,(a2)		; request type

	;; write message
	move.w	(a0)+,d2	; size of content
	move.w	d2,(a2)		; write content length
	move.w	(a0)+,(a2)	; write request asbtract
	move.w	(a0)+,(a2)	
	move.l	(a0),a0		; get content address
	move.w	d2,d0
	beq.s	.request_content_emitted
	move.l	a0,d4
	lsr.b	#1,d4
	bcc.s	.write_request_content_even
.write_request_content_odd:
	move.b	(a0)+,d4
	rol.w	#8,d4
	move.b	(a0)+,d4
	move.w	d4,(a2)
	subq.w	#2,d0
	bhi.s	.write_request_content_odd
	bra.s	.request_content_emitted
.write_request_content_even:
	move.w	(a0)+,(a2)	; write content
	subq.w	#2,d0
	bhi.s	.write_request_content_even
.request_content_emitted:
	
	;; write length
	add.w	#$FEA,d1	; get address of length flag
	move.w	d1,(a1)		; set address
	addq.w	#4,d2		; add header size (escape command)
	addq.w	#MSGHDRSZ,d2
	move.w	d2,(a2)		; write length (PC gets this buffer now)

	move.w #$4001,(a1)	; enter flash read-only mode	
	
	;; check for reply
	cmp.w	#SYNC_MSG,d3
	bne.s	.no_reply
.get_reply:
 	add.w	#$1000,d1	; switch to second buffer for reply
	; wait for a response - (done with d0 since
	; the PC side must honor our length request)
.wait_reply:	
	move.w	d1,(a1)		; write address
	move.w	(a1),d2		; read data
	andi.w	#$FF00,d2
	cmp.w	#$FF00,d2	; test if used
	beq.s	.wait_reply
.got_reply:
	; get the real value again
	move.w	d1,(a1)		; write address
	move.w	(a1),d2		; read data (length)
	move.l	8+(4*4)(sp),a0	; get reply message

	sub.w	#$FEA,d1	; get base address of buffer
	move.w	d1,(a1)		; set address

	move.w	(a1),(a0)+	; read content length
	move.w	(a1),(a0)+	; read content kind
	move.w	(a1),(a0)+	; read content kind
	move.l	(a0),a0		; get address of content
	subq.w	#MSGHDRSZ,d2
	beq.s	.reply_content_read
	move.l	a0,d4
	lsr.b	#1,d4
	bcc.s	.read_reply_content_even
.read_reply_content_odd:
	move.w	(a1),d4
	ror.w	#8,d4
	move.b	d4,(a0)+
	rol.w	#8,d4
	move.b	d4,(a0)+
	subq.w	#2,d2
	bhi.s	.read_reply_content_odd
	bra.s	.reply_content_read
.read_reply_content_even:
	move.w	(a1),(a0)+	; write data
	subq.w	#2,d2
	bhi.s	.read_reply_content_even
.reply_content_read:

	add.w	#$FEA,d1	; go back up to the length field again			
	move.w	#$4004,(a1)	; enter HPI write mode
	move.w	d1,(a1)		; set HPI write data address
	move.w	#$0000,(a2)	; write data

	move.w	#$4001,(a1)	; enter flash read-only mode
	;; wait for PC to clear the buffer flag
.synchro:
	move.w	d1,(a1)
	move.w	(a1),d2
	and.w	#$ff00,d2
	cmp.w	#$ff00,d2
	bne.s	.synchro
.no_reply:	
	;; done

	moveq	#0,d0		; success
.exit:
	movem.l	(sp)+,d2-d4/a2
	rts

; ---------------------------------------------------------------------
; Helper functions - not intended to be externally called
; ---------------------------------------------------------------------
		
; setAddresses - helper function to set console addresses
setAddresses:
		move.l	#$C00000,a1			; HPI write address/read data
		move.l	#$800000,a2			; HPI write data
		rts
		
; Following functions assume setAddresses has been called!		
; check buffer - test if buffer in d1 is available (d1 points to length word)
checkbuffer:
		move.l	d0,-(sp)
		
		move.w	d1,(a1)				; set read address
		move.w	(a1),d0				; read data
		andi.w	#$ff00,d0			; saw a race where the low byte was set first, high can never be $FF
		cmp.w	#$ff00,d0			; is it empty?
		beq		.empty
		clr.l	d1					; not empty
		jmp		.exit
.empty:	
		sub.w	#$FEA,d1			; get base address

.exit:
		move.l	(sp)+,d0
		rts		
		
; checkBuffer1 - test if buffer 1 is available (returns in d1)
checkBuffer1:
		move.l	#($1800+$FEA),d1
		jmp		checkbuffer

; checkBuffer2 - test if buffer 2 is available (returns in d1)
checkBuffer2:
		move.l	#($2800+$FEA),d1
		jmp		checkbuffer

; getBuffer - helper function to return either buffer when it's free in d1
; returns 0 in d1 if neither buffer is free 
getBuffer:
		bsr		checkBuffer1
		tst.l	d1
		bne		.exit
		bsr		checkBuffer2
		tst.l	d1
		bne		.exit
		; both buffers are in use - do we sit and wait?
		tst.l	skunkConsoleUp
		beq		.exit			; no, console was down last time too
		
		; else yes, we want to wait here for a few spins
		move.l	d0,-(sp)		; get a work register
		move.l	#timeout,d0		; number of spins to wait
.waitlp:
		bsr		checkBuffer1
		tst.l	d1
		bne		.exitwait
		bsr		checkBuffer2
		tst.l	d1
		bne		.exitwait
		dbra	d0,.waitlp
		
		; whatever we have now, we're going to go with
.exitwait:		
		move.l	(sp)+,d0		; fix the stack
.exit:
		move.l	d1,skunkConsoleUp	; save the result for next time
		rts		

; getBothBuffers - waits for both buffers to be free then returns the
; first buffer ($1800) in d1. Returns 0 in d1 if both buffers do not free up.
getBothBuffers:
		bsr		checkBuffer2
		tst.l	d1
		beq		.trywait		; busy - try waiting
		bsr		checkBuffer1
		tst.l	d1
		beq		.trywait		; busy - try waiting
		; both buffers are free, we can exit already! (note we put buffer 1 last)
		bra		.exit

.trywait:
		tst.l	skunkConsoleUp
		beq		.exit			; no, console was down last time too
		
		; else yes, we want to wait here for a few spins
		move.l	d0,-(sp)		; get a work register
		move.l	#timeout,d0		; number of spins to wait
.waitlp:
		bsr		checkBuffer2
		tst.l	d1
		beq		.dolp			; still busy, repeat loop
		bsr		checkBuffer1
		tst.l	d1
		bne		.exitwait		; not busy (and buffer 2 not busy), exit loop
.dolp:
		dbra	d0,.waitlp
		; whatever we have now, we're going to go with
.exitwait:		
		move.l	(sp)+,d0		; fix the stack
.exit:
		move.l	d1,skunkConsoleUp	; save the result for next time
		rts		

; waitforbufferack - waits for the buffer with d1 pointing to the length offset
; to be cleared by the PC. will time out but the timeout is longer than the length
; of getBuffer.
waitforbufferack:
		movem.l	d0-d2,-(sp)
		; wait for that buffer to be cleared by the PC - d1 already has the right value in it
		; but checkbuffer will nuke d1 if it's not ready, so we need to save it off
		move.l	d1,d0
		move.l	#timeout,d2
.synclp:
		move.l	d0,d1
		jsr		checkbuffer
		tst.l	d1
		bne		.exit
		dbra	d2,.synclp

.exit:
		movem.l	(sp)+,d0-d2
		rts

		.bss
; Set to nonzero when console is okay, cleared to 0 if the console times out
; (so only the first operation lags)
	.long
skunkConsoleUp::	ds.l	1
