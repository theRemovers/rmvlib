; The Removers'Library 
; Copyright (C) 2006 Seb/The Removers
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

;**************************************************
;*    ----- Protracker V2.3A Playroutine -----    *
;**************************************************

; VBlank Version 2:
; Call mt_init to initialize the routine, then call mt_music on
; each vertical blank (50 Hz). To end the song and turn off all
; voices, call mt_end.

; This playroutine is not very fast, optimized or well commented,
; but all the new commands in PT2.3A should work.
; If it's not good enough, you'll have to change it yourself.
; We'll try to write a faster routine soon...

; Changes from V1.0C playroutine:
; - Vibrato depth changed to be compatible with Noisetracker 2.0.
;   You'll have to double all vib. depths on old PT modules.
; - Funk Repeat changed to Invert Loop.
; - Period set back earlier when stopping an effect.

; Converted, improved and optimised by Seb/The Removers
; Improvements:
; - Tempo
; - old Protracker modules
; - 4/6/8 voices
; - setPanPosition
	
	.offset	0
n_note:			ds.w	1
n_cmd:			ds.b	1
n_cmdlo:		ds.b	1
n_start:		ds.l	1
n_loopstart:		ds.l	1
n_length:		ds.w	1
n_replen:		ds.w	1
n_period:		ds.w	1
n_finetune:		ds.b	1
n_volume:		ds.b	1
n_toneportdirec:	ds.b	1
n_toneportspeed:	ds.b	1
n_wantedperiod:		ds.w	1
n_vibratocmd:		ds.b	1
n_vibratopos:		ds.b	1
n_tremolocmd:		ds.b	1
n_tremolopos:		ds.b	1
n_wavecontrol:		ds.b	1
n_glissfunk:		ds.b	1
n_sampleoffset:		ds.b	1
n_pattpos:		ds.b	1
n_loopcount:		ds.b	1
n_funkoffset:		ds.b	1
n_wavestart:		ds.l	1
n_reallength:		ds.w	1
n_dmabit:		ds.w	1
	.long
n_sizeof:		ds.l	0

	.offset
sample_name:		ds.b	22
sample_length:		ds.w	1
sample_finetune:	ds.b	1
sample_volume:		ds.b	1
sample_repeat_start:	ds.w	1
sample_repeat_length:	ds.w	1
sample_sizeof:		ds.l	0
	
	.text

OPTIM	equ	1
	
.macro	clear_dma
	moveq	#0,d7
	move.w	\1,d7
	beq.s	.skip\~
	wait_dma	SOUND_DMA
	move.l	d7,SOUND_DMA
	dsp_interrupt
.skip\~:
.endm
	
.macro	set_dma
	moveq	#0,d7
	move.w	\1,d7
	and.w	mt_ActiveVoices,d7
	beq.s	.skip\~
	or.l	#$80000000,d7
	wait_dma	SOUND_DMA
	move.l	d7,SOUND_DMA
	dsp_interrupt
	wait_dma	SOUND_DMA
.skip\~:
.endm
	
.macro	set_period
	move.l	VOICE_CONTROL(a5),d7
	move.w	\1,d7
	add.w	d7,d7
	move.w	(a4,d7.w),d7
	move.l	d7,VOICE_CONTROL(a5)
.endm
	
.macro	set_volume
	move.l	VOICE_CONTROL(a5),d7
	swap	d7
	move.b	\1,d7
	swap	d7
	move.l	d7,VOICE_CONTROL(a5)
.endm

.macro	set_balance
	;; \1 is on 5 bits!!
	move.l	VOICE_CONTROL(a5),d7
	rol.l	#8,d7
	move.b	\1,d7
	ror.l	#8,d7
	move.l	d7,VOICE_CONTROL(a5)
.endm
	
.macro	set_sample
	move.l	\1,VOICE_START(a5)
	moveq	#0,d7
	move.w	\2,d7
	add.l	d7,d7
	move.l	d7,VOICE_LENGTH(a5)
.endm

.macro	new_chunk
	dc.w	\1
	dc.w	\2
	dc.l	\3
.endm
	
	.data
	.long
mt_chunks:
	new_chunk	4,$43c,"M.K."
	new_chunk	4,$43c,"M!K!"
	new_chunk	4,$43c,"M&K&"
	new_chunk	4,$43c,"RASP"
	new_chunk	4,$43c,"FLT4"
	new_chunk	6,$43c,"FLT6"
	new_chunk	8,$43c,"FLT8"
	new_chunk	4,$43c,"EXO4"
	new_chunk	6,$43c,"EXO6"
	new_chunk	8,$43c,"EXO8"
	new_chunk	4,$43c,"4CHN"
        new_chunk       5,$43c,"5CHN"
	new_chunk	6,$43c,"6CHN"
	new_chunk	8,$43c,"8CHN"
	new_chunk	8,$43c,"CD81"
	new_chunk	8,$43c,"OCTA"
	new_chunk	8,$43c,"OKTA"
	new_chunk	4,$43c,"04CH"
	new_chunk	6,$43c,"06CH"
	new_chunk	8,$43c,"08CH"
	new_chunk	4,$43c+4,"FA04"
	new_chunk	6,$43c+4,"FA06"
	new_chunk	8,$43c+4,"FA08"	
	;; last chunk is a dummy chunk
	new_chunk	0,0,"END!"
	
	.text

TEMPO_FLAG	equ	0
NOREPEAT_FLAG	equ	1
	
;; mt_init(char *module, int flags);
mt_init:
	move.l	4(sp),a0
	move.l	8(sp),d0
	btst	#TEMPO_FLAG,d0
	sne	mt_tempo_flag
	st	mt_SetPan_flag
	btst	#NOREPEAT_FLAG,d0
	sne	mt_no_repeat_flag
	movem.l	d2/a2,-(sp)
	MOVE.L	A0,mt_SongDataPtr
	;; we first determine the type of module
	move.l	$438(a0),d0			; read chunk
	
	move.w	#$43c,mt_PatternDataOffset	; new module format
	move.w	#31,mt_nbSamples		; 31 samples

	move.l	#mt_chunks,a1
.mt_search_chunk:
	tst.l	(a1)+		; is a valid chunk?
	beq.s	.mt_chunk_not_found
	cmp.l	(a1)+,d0
	bne.s	.mt_search_chunk
.mt_chunk_found:
	move.w	-8(a1),mt_nbVoices ; nb voices
	move.w	-6(a1),mt_PatternDataOffset ; offset
	bra.s	.mt_module_ok
.mt_chunk_not_found:
	move.w	#$258,mt_PatternDataOffset	; old module format
	move.w	#15,mt_nbSamples		; 15 samples
	move.w	#4,mt_nbVoices
.mt_module_ok:	
	move.w	mt_nbSamples,d0
	mulu.w	#sample_sizeof,d0
	add.w	#20+2,d0
	move.w	d0,mt_SequenceDataOffset
	;; here we compute the number of patterns
	move.l	a0,a1
	add.w	mt_SequenceDataOffset,a1
	move.b	-2(a1),mt_SongLength
	move.b	-1(a1),mt_SongRestart
	moveq	#128-1,d0
	moveq	#0,d2
.mt_loop:	
	move.b	(a1)+,d1	; num
	bmi.s	.mt_loop_skip
	cmp.b	d1,d2		; num > max?
	dbcs	d0,.mt_loop	; no
	bcc.s	.mt_loop_end	; no
	move.b	d1,d2		; yes
.mt_loop_skip:	
	dbf	d0,.mt_loop
.mt_loop_end:
	cmp.b	mt_SongRestart,d2 ; restart < max?
	bcc.s	.mt_SongRestart_ok ; yes
	clr.b	mt_SongRestart
.mt_SongRestart_ok:	
	addq.b	#1,d2
	
	;; we now compute the base address of each sample
	move.l	#mt_SampleStarts,a1
	lsl.l	#6,d2		; nb pattern * 64
	mulu.w	mt_nbVoices,d2	; * nb voices
	add.l	d2,d2
	add.l	d2,d2		; * 4
	lea	(a0,d2.l),a2
	add.w	mt_PatternDataOffset,a2
	add.w	#20,a0		; skip module name
	move.w	mt_nbSamples,d0
	subq.w	#1,d0
.mt_loop3:
	move.l	a2,(a1)+
	moveq	#0,d1
	move.w	sample_length(a0),d1
	bne.s	.mt_ok_sample
	;; no sample here
	clr.w	sample_repeat_start(a0)
	clr.w	sample_repeat_length(a0)
	bra.s	.mt_ok_repeat
.mt_ok_sample:
	;; clear first word of sample
	clr.w	(a2)		; to get silence when repeat = 0 and repeat length = 1
	;; check repeat
	move.w	sample_repeat_start(a0),d2
	add.w	sample_repeat_length(a0),d2
	cmp.w	d2,d1
	bcc.s	.mt_ok_repeat
	move.w	d1,d2		; repeat value out of bounds
	sub.w	sample_repeat_start(a0),d2
	bmi.s	.mt_repeat_err
	move.w	d2,sample_repeat_length(a0)
	bra.s	.mt_ok_repeat
.mt_repeat_err:
	clr.w	sample_repeat_start(a0)	; no repeat
	move.w	#1,sample_repeat_length(a0)
.mt_ok_repeat:	
	add.l	d1,d1		; in bytes
	add.l	d1,a2
	add.w	#sample_sizeof,a0
	dbf	d0,.mt_loop3
	
	MOVE.B	#6,mt_speed
	CLR.B	mt_counter
	CLR.B	mt_SongPos
	CLR.W	mt_PatternPos
	move.b	#125,mt_tempo
	move.w	#$00ff,mt_LowMask ; initialise Portamento Up/Down mask
	
	clr.w	mt_frame_tempo
	move.w	#$ffff,mt_SongPlayPause

	move.l	#mt_chan1temp,a0
	move.w	mt_nbVoices,d0
	subq.w	#1,d0
	moveq	#1,d1
.mt_init_chan:
	move.w	d1,n_dmabit(a0)
	lsl.w	#1,d1
	add.w	#n_sizeof,a0
	dbf	d0,.mt_init_chan

	move.w	mt_nbVoices,d1
	lsl.w	d1,d0
	subq.w	#1,d0
	move.w	d0,mt_ActiveVoices
	
	movem.l	(sp)+,d2/a2
mt_end:
	movem.l	d7/a5,-(sp)	; the macros uses d7

	move.l	#SOUND_VOICES,a5
	move.b	#%10011001,d0	; left - right - right - left - ...
	swap	d0
	move.w	mt_nbVoices,d0
	subq.w	#1,d0
.mt_set_voice:
	swap	d0
	moveq	#0,d1		; left
	move.l	d1,VOICE_CONTROL(a5) ; clear voice
	rol.b	#1,d0
	bcs.s	.mt_set_balance
	moveq	#16,d1		; right
.mt_set_balance:
	set_balance	d1
	add.w	#VOICE_SIZEOF,a5
	swap	d0
	dbf	d0,.mt_set_voice

	moveq	#1,d0
	moveq	#0,d1
	move.w	mt_nbVoices,d1
	lsl.w	d1,d0
	subq.w	#1,d0
	clear_dma	d0
	
	movem.l	(sp)+,d7/a5
	moveq	#0,d0
	move.w	mt_nbVoices,d0
	rts

mt_clear:
	clr.l	mt_SongDataPtr
	bra	mt_end
	
mt_pause:
	not.w	mt_SongPlayPause
	beq	mt_end
	rts

mt_enable_voices:
	move.w	mt_nbVoices,d0
	moveq	#1,d1
	lsl.w	d0,d1
	subq.w	#1,d1
	move.w	4+2(sp),d0
	and.w	d1,d0
	move.w	d0,mt_ActiveVoices
	move.l	d7,-(sp)
	not.w	d0
	and.w	d1,d0
	clear_dma	d0
	move.l	(sp)+,d7
	moveq	#0,d0
	move.w	mt_ActiveVoices,d0
	rts
	
	.bss
	.long
mt_frame_tempo:		ds.w	1
	.even
mt_SongPlayPause:	ds.w	1
	
	.text
mt_music_vbl:
	tst.w	mt_SongPlayPause
	bne.s	.mt_SongTest
	rts
.mt_SongTest:	
	tst.l	mt_SongDataPtr
	bne.s	.mt_music_vbl
	rts
.mt_music_vbl:
	move.l	d2,-(sp)
	move.w	CONFIG,d0
	move.l	#5*50,d1	; 5*50 Hz
	and.w	#VIDTYPE,d0
	beq.s	.mt_music_50Hz
.mt_music_60Hz:
	move.l	#5*60,d1	; 5*60 Hz
.mt_music_50Hz:	
	moveq	#0,d2
	move.b	mt_tempo,d2	; get tempo
	add.w	d2,d2
	add.w	mt_frame_tempo,d2 ; add previous remainder
	divu.w	d1,d2		; 2*tempo/(5*freq_vbl) = (2*tempo/5)/freq_vbl = freq/freq_vbl
	subq.w	#1,d2
	bmi.s	.skip
.call:
	bsr.s	mt_music
	dbf	d2,.call
.skip:
	swap	d2
	move.w	d2,mt_frame_tempo
	move.l	(sp)+,d2
	rts
	;; register allocation:
	;; d0-d3: general purpose registers (computation)
	;; d4: free!
	;; d5: voice counter
	;; d6: current note and command
	;; d7: temporary register (crashed by macros)
	;; a0: patterns
	;; a1: temporary
	;; a2: period table
	;; a3: samples
	;; a4: amiga_frequencies
	;; a5: current voice (DSP)
	;; a6: current channel (module)
mt_music:
	MOVEM.L	D2-D7/A2-A6,-(SP)
	ADDQ.B	#1,mt_counter
	MOVE.B	mt_counter,D0
	CMP.B	mt_speed,D0
	BLO.S	mt_NoNewNote
	CLR.B	mt_counter
	TST.B	mt_PattDelTime2
	BEQ.S	mt_GetNewNote
	BSR.S	mt_NoNewAllChannels
	BRA	mt_dskip

mt_NoNewNote:
	BSR.S	mt_NoNewAllChannels
	BRA	mt_NoNewPosYet

mt_NoNewAllChannels:
	move.l	#mt_PeriodTable,a2
	move.l	#_amiga_frequencies,a4

	move.w	mt_nbVoices,d5
	subq.w	#1,d5
	move.l	#SOUND_VOICES,a5
	move.l	#mt_chan1temp,a6
.go_CheckEfx:
	bsr	mt_CheckEfx	
	add.w	#VOICE_SIZEOF,a5
	add.w	#n_sizeof,a6
	dbf	d5,.go_CheckEfx
	rts
mt_GetNewNote:	
	MOVE.L	mt_SongDataPtr,A0
	LEA	12(A0),A3
	move.l	a0,a2
	add.w	mt_SequenceDataOffset,a2
	add.w	mt_PatternDataOffset,a0
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	mt_SongPos,D0
	MOVE.B	(A2,D0.W),D1
	and.b	#$7f,d1		; max pattern = 127
	lsl.w	#6,d1		; * 64
	add.w	mt_PatternPos,d1
	mulu.w	mt_nbVoices,d1	; * nb voices
	add.l	d1,d1
	add.l	d1,d1		; *4
	add.l	d1,a0
	CLR.W	mt_DMACONtemp

	move.l	#mt_PeriodTable,a2
	move.l	#_amiga_frequencies,a4

	move.l	#SOUND_VOICES,a5
	move.l	#mt_chan1temp,a6
	move.w	mt_nbVoices,d5
	subq.w	#1,d5
.go_PlayVoice:	
	bsr.s	mt_PlayVoice
	add.w	#VOICE_SIZEOF,a5
	add.w	#n_sizeof,a6
	dbf	d5,.go_PlayVoice
	bra	mt_SetDMA
mt_PlayVoice:	
	TST.L	(A6)
	BNE.S	.mt_plvskip
	BSR	mt_PerNop
.mt_plvskip:
	.if	OPTIM
	move.l	(a0)+,d6
	move.l	d6,(a6)
	move.w	d6,d2
	rol.w	#4,d2
	and.w	#$f,d2
	move.l	d6,d0
	rol.l	#8,d0
	and.b	#$f0,d0
	or.b	d0,d2
	beq.s	.mt_SetRegs
	.else
	move.l	(a0)+,(a6)
	moveq	#0,d2
	move.b	n_cmd(a6),d2
	and.b	#$f0,d2
	lsr.b	#4,d2
	move.b	(a6),d0
	and.b	#$f0,d0
	or.b	d0,d2
	BEQ	.mt_SetRegs
	.endif
	move.l	#mt_SampleStarts,A1
	move.w	d2,d7
	subq.w	#1,d2
	lsl.w	#2,d2
	mulu.w	#sample_sizeof,d7
	.if	OPTIM
	move.l	(a1,d2.w),d2	; start of sample
	move.l	d2,n_start(a6)
	move.l	(a3,d7.l),d1
	move.w	d1,n_finetune(a6) ; n_finetune and n_volume
	swap	d1
	move.w	d1,n_length(a6)
	move.w	d1,n_reallength(a6)
	move.l	4(a3,d7.l),d1	; repeat | repeat length
	move.w	d1,n_replen(a6)
	moveq	#0,d3
	swap	d1
	move.w	d1,d3		; repeat
	beq.s	.mt_NoLoop
	swap	d1
	add.w	d3,d1		; repeat + replen
	move.w	d1,n_length(a6)
	add.l	d3,d3		; 2*repeat
	add.l	d3,d2		; +start
.mt_NoLoop:
	move.l	d2,n_loopstart(a6)
	move.l	d2,n_wavestart(a6)
	.else
	MOVE.L	(A1,D2.w),n_start(A6)
	MOVE.W	(A3,d7.l),n_length(A6)
	MOVE.W	(A3,d7.l),n_reallength(A6)
	MOVE.B	2(A3,d7.l),n_finetune(A6)
	MOVE.B	3(A3,d7.l),n_volume(A6)
	moveq	#0,d3
	MOVE.W	4(A3,d7.l),D3 ; Get repeat
	BEQ.S	.mt_NoLoop
	MOVE.L	n_start(A6),D2	; Get start
	add.l	d3,d3
	ADD.L	D3,D2		; Add repeat
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	4(A3,d7.l),D0	; Get repeat
	ADD.W	6(A3,d7.l),D0	; Add replen
	MOVE.W	D0,n_length(A6)
	MOVE.W	6(A3,d7.l),n_replen(A6)	; Save replen
	bra.s	.mt_SetVol
.mt_NoLoop:	
	MOVE.L	n_start(A6),D2
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	6(A3,d7.l),n_replen(A6)	; Save replen
	.endif
.mt_SetVol:
; 	moveq	#0,d0
; 	move.b	n_volume(a6),d0
; 	set_volume	d0
	set_volume	n_volume(a6)
.mt_SetRegs:
	.if	OPTIM
	move.l	d6,d0
	swap	d0
	and.w	#$fff,d0
	beq	mt_CheckMoreEfx
	swap	d0
	.else
	move.w	(a6),d0
	AND.W	#$0FFF,D0
	BEQ	mt_CheckMoreEfx	; If no note
	move.w	2(a6),d0
	.endif
	and.w	#$0ff0,d0
	cmp.w	#$0e50,d0
	beq.s	.mt_DoSetFineTune
	.if	OPTIM
	move.w	d6,d0
	and.w	#$f00,d0
	cmp.w	#$300,d0
	beq.s	.mt_ChkTonePorta
	cmp.w	#$500,d0
	beq.s	.mt_ChkTonePorta
	cmp.w	#$900,d0
	bne.s	.mt_SetPeriod
	.else
	move.b	2(a6),d0
	and.b	#$f,d0
	cmp.b	#3,d0		; TonePortamento
	beq.s	.mt_ChkTonePorta
	cmp.b	#5,d0
	beq.s	.mt_ChkTonePorta
	cmp.b	#9,d0	; Sample Offset
	bne.s	.mt_SetPeriod
	.endif
	bsr	mt_CheckMoreEfx
	bra.s	.mt_SetPeriod
.mt_ChkTonePorta:	
	BSR	mt_SetTonePorta
	BRA	mt_CheckMoreEfx
.mt_DoSetFineTune:	
	BSR	mt_SetFineTune
; 	BRA.S	.mt_SetPeriod
.mt_SetPeriod:
	.if	OPTIM
	move.l	d6,d1
	swap	d1
	and.w	#$fff,d1
	.else
	move.w	(a6),d1
	AND.W	#$0FFF,D1
	.endif
	move.l	a2,a1		; mt_PeriodTable
	MOVEQ	#36-1,D7
.mt_ftuloop:
	cmp.w	(a1)+,d1
	dbcc	d7,.mt_ftuloop
.mt_ftufound:	
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	lsl.w	#3,d1
	add.w	d1,a1		; 36*2 = (8+1)*8
	lsl.w	#3,d1
	add.w	d1,a1
	move.w	-(a1),n_period(a6)

	.if	OPTIM
	move.w	d6,d0
	.else
	move.w	2(a6),d0
	.endif
	AND.W	#$0FF0,D0
	CMP.W	#$0ED0,D0 ; Notedelay
	BEQ	mt_CheckMoreEfx

	.if	!(^^defined	PAULA)
	clear_dma	n_dmabit(a6)
	.endif
	
	BTST	#2,n_wavecontrol(A6)
	BNE.S	.mt_vibnoc
	CLR.B	n_vibratopos(A6)
.mt_vibnoc:	
	BTST	#6,n_wavecontrol(A6)
	BNE.S	.mt_trenoc
	CLR.B	n_tremolopos(A6)
.mt_trenoc:
	set_sample	n_start(a6),n_length(a6)
	set_period	n_period(a6)
	MOVE.W	n_dmabit(A6),D0
	OR.W	D0,mt_DMACONtemp
	BRA	mt_CheckMoreEfx
 
mt_SetDMA:
 	set_dma	mt_DMACONtemp

	move.w	mt_nbVoices,d5
	subq.w	#1,d5
	move.l	#SOUND_VOICES,A5
	move.l	#mt_chan1temp,A6
.go_SetDMA:	
	set_sample	n_loopstart(a6),n_replen(a6)
	add.w	#VOICE_SIZEOF,a5
	add.w	#n_sizeof,a6
	dbf	d5,.go_SetDMA
mt_dskip:
	addq.w	#1,mt_PatternPos
	MOVE.B	mt_PattDelTime,D0
	BEQ.S	.mt_dskc
	MOVE.B	D0,mt_PattDelTime2
	CLR.B	mt_PattDelTime
.mt_dskc:	
	TST.B	mt_PattDelTime2
	BEQ.S	.mt_dska
	SUBQ.B	#1,mt_PattDelTime2
	BEQ.S	.mt_dska
	subq.w	#1,mt_PatternPos
.mt_dska:	
	TST.B	mt_PBreakFlag
	BEQ.S	.mt_nnpysk
	SF	mt_PBreakFlag
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos,D0
	CLR.B	mt_PBreakPos
	MOVE.W	D0,mt_PatternPos
.mt_nnpysk:	
	cmp.w	#64,mt_PatternPos
	BLO.S	mt_NoNewPosYet
mt_NextPosition:	
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos,D0
	MOVE.W	D0,mt_PatternPos
	CLR.B	mt_PBreakPos
	CLR.B	mt_PosJumpFlag
	ADDQ.B	#1,mt_SongPos
	AND.B	#$7F,mt_SongPos
	MOVE.B	mt_SongPos,D1
	MOVE.L	mt_SongDataPtr,A0
; 	CMP.B	950(A0),D1
	cmp.b	mt_SongLength,d1
	BLO.S	mt_NoNewPosYet
	move.b	mt_SongRestart,mt_SongPos
	tst.b	mt_no_repeat_flag ; repeat?
	beq.s	mt_NoNewPosYet
	clr.w	mt_SongPlayPause ; no => pause the song
; 	CLR.B	mt_SongPos
mt_NoNewPosYet:	
	TST.B	mt_PosJumpFlag
	BNE.S	mt_NextPosition
	MOVEM.L	(SP)+,D2-D7/A2-A6
	RTS

mt_CheckEfx:
	.if	OPTIM
	move.l	(a6),d6
	.endif
	BSR	mt_UpdateFunk
	.if	OPTIM
	move.w	d6,d0
	and.w	#$fff,d0
	beq.s	mt_PerNop
	move.w	d6,d0
	lsr.w	#6,d0
	and.w	#$f<<2,d0
	.else
	move.w	n_cmd(a6),d0
	AND.W	#$0FFF,D0
	BEQ.S	mt_PerNop
	move.b	n_cmd(a6),d0
	and.w	#$f,d0
	add.w	d0,d0
	add.w	d0,d0
	.endif
	move.l	.mt_CheckEfx_table(pc,d0.w),-(sp) ;
	rts			;
.mt_CheckEfx_table:
	dc.l	mt_Arpeggio		; 0
	dc.l	mt_PortaUp		; 1 
	dc.l	mt_PortaDown		; 2 
	dc.l	mt_TonePortamento	; 3 
	dc.l	mt_Vibrato		; 4 
	dc.l	mt_TonePlusVolSlide	; 5 
	dc.l	mt_VibratoPlusVolSlide	; 6 
	dc.l	mt_TremoloPlusSetBack	; 7 
	dc.l	SetBack			; 8 
	dc.l	SetBack			; 9 
	dc.l	mt_VolumeSlidePlusSetBack ; A
	dc.l	SetBack			; B
	dc.l	SetBack			; C
	dc.l	SetBack			; D
	dc.l	mt_E_Commands		; E 
	dc.l	SetBack			; F 

mt_PerNop:	
SetBack:
	set_period	n_period(a6)
mt_Return2:	
	rts
	
mt_Arpeggio:	
	MOVEQ	#0,D0
	MOVE.B	mt_counter,D0
	DIVU	#3,D0
	SWAP	D0
	subq.b	#1,d0
	bmi.s	.mt_Arpeggio2
	bne.s	.mt_Arpeggio1
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	LSR.B	#4,D0
	BRA.S	.mt_Arpeggio3
.mt_Arpeggio1:
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	AND.w	#$f,D0
	BRA.S	.mt_Arpeggio3
.mt_Arpeggio2:	
	MOVE.W	n_period(A6),D2
	BRA.S	.mt_Arpeggio4
.mt_Arpeggio3:	
	add.w	d0,d0
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	move.l	a2,a1		; mt_PeriodTable
	lsl.w	#3,d1
	add.w	d1,a1		; 36*2 = (8+1)*8
	lsl.w	#3,d1
	add.w	d1,a1
	MOVE.W	n_period(A6),D1
	MOVEQ	#36-1,D7
.mt_arploop:
	cmp.w	(a1)+,d1
	dbcc	d7,.mt_arploop
	bcc.s	.to_mt_Arpeggio4
	rts
.to_mt_Arpeggio4:
	move.w	-2(a1,d0.w),d2
.mt_Arpeggio4:
	set_period	d2
	RTS

mt_FinePortaUp:	
	TST.B	mt_counter
	bne.s	mt_PortaUpRet
	MOVE.B	#$0F,mt_LowMask+1
mt_PortaUp:	
; 	moveq	#0,d0
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
; 	AND.B	mt_LowMask,D0
	and.w	mt_LowMask,d0
	MOVE.B	#$FF,mt_LowMask+1
	SUB.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#113,D0
	BPL.S	.mt_PortaUskip
	move.w	#113,d0
	move.w	d0,n_period(a6)
.mt_PortaUskip:
	set_period	d0
mt_PortaUpRet:	
	rts
 
mt_FinePortaDown:	
	TST.B	mt_counter
	bne.s	mt_PortaDownRet
	MOVE.B	#$0F,mt_LowMask+1
mt_PortaDown:	
; 	moveq	#0,d0
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
; 	AND.B	mt_LowMask,D0
	and.w	mt_LowMask,d0
	MOVE.B	#$FF,mt_LowMask+1
	ADD.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#856,D0
	BMI.S	.mt_PortaDskip
	move.w	#856,d0
	move.W	d0,n_period(a6)
.mt_PortaDskip:
	set_period	d0
mt_PortaDownRet:	
	rts

mt_SetTonePorta:
	.if	OPTIM
	move.l	d6,d2
	swap	d2
	and.w	#$fff,d2
	.else
	MOVE.W	(A6),D2
	AND.W	#$0FFF,D2
	.endif
	moveq	#0,d0
	move.b	n_finetune(a6),d0
	move.b	d0,d3		; save finetune
	move.l	a2,a1		; mt_PeriodTable
	lsl.w	#3,d0
	add.w	d0,a1		; 36*2 = (32+4)*2 = (8*4+4)*2 = (8+1)*4*2
	lsl.w	#3,d0
	add.w	d0,a1
	moveq	#36-1,d7
.mt_StpLoop:
	cmp.w	(a1)+,d2
	dbcc	d7,.mt_StpLoop
.mt_StpFound:	
; 	MOVE.B	n_finetune(A6),D2
; 	AND.B	#8,D2
; 	BEQ.S	.mt_StpGoss	; finetune >= 0
	and.b	#%1000,d3
	beq.s	.mt_StpGoss	; finetune >= 0
	cmp.w	#36-1,d7
	beq.s	.mt_StpGoss
	subq.w	#2,a1
.mt_StpGoss:	
	move.w	-(a1),d2
	cmp.w	n_period(a6),d2
	beq.s	.mt_ClearTonePorta
	bhi.s	.mt_TonePortaUp
.mt_TonePortaDown:	
	move.w	d2,n_wantedperiod(a6)
	move.b	#1,n_toneportdirec(a6)
	rts
.mt_TonePortaUp:
	move.w	d2,n_wantedperiod(a6)
	clr.b	n_toneportdirec(a6)
	rts
.mt_ClearTonePorta:	
	clr.w	n_wantedperiod(a6)
	clr.b	n_toneportdirec(a6)
	rts	
; 	MOVE.W	D2,n_wantedperiod(A6)
; 	MOVE.W	n_period(A6),D0
; 	CLR.B	n_toneportdirec(A6)
; 	CMP.W	D0,D2
; 	BEQ.S	.mt_ClearTonePorta
; 	BGE	mt_Return2
; 	MOVE.B	#1,n_toneportdirec(A6)
; 	RTS
; .mt_ClearTonePorta:	
; 	CLR.W	n_wantedperiod(A6)
; 	RTS

mt_TonePortamento:
	.if	OPTIM
	tst.b	d6
	beq.s	mt_TonePortNoChange
	move.b	d6,n_toneportspeed(a6)
	clr.b	d6
	move.b	d6,n_cmdlo(a6)
	.else
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_TonePortNoChange
	MOVE.B	D0,n_toneportspeed(A6)
	CLR.B	n_cmdlo(A6)
	.endif
mt_TonePortNoChange:	
	TST.W	n_wantedperiod(A6)
	beq.s	.mt_TonePortRet
	MOVEQ	#0,D0
	MOVE.B	n_toneportspeed(A6),D0
	TST.B	n_toneportdirec(A6)
	BNE.S	.mt_TonePortaUp
.mt_TonePortaDown:	
	ADD.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BGT.S	.mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)
	BRA.S	.mt_TonePortaSetPer
.mt_TonePortaUp:	
	SUB.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BLT.S	.mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)
.mt_TonePortaSetPer:	
	MOVE.W	n_period(A6),D2
	MOVE.B	n_glissfunk(A6),D0
	AND.B	#$0F,D0
	BEQ.S	.mt_GlissSkip
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	move.l	a2,a1		; mt_PeriodTable
	lsl.w	#3,d0
	add.w	d0,a1
	lsl.w	#3,d0		; 36*2 = (8+1)*8
	add.w	d0,a1
	moveq	#36-1,d7
.mt_GlissLoop:
	cmp.w	(a1)+,d2
	dbcc	d7,.mt_GlissLoop
	move.w	-(a1),d2
.mt_GlissSkip:
	set_period	d2
.mt_TonePortRet:	
	RTS

mt_Vibrato:
	.if	OPTIM
	move.b	d6,d0
	beq.s	mt_Vibrato2
	move.b	n_vibratocmd(a6),d2
	and.b	#$f,d0
	beq.s	.mt_vibskip
	and.b	#$f0,d2
	or.b	d0,d2
.mt_vibskip:
	move.b	d6,d0
	and.b	#$f0,d0
	beq.s	.mt_vibskip2
	and.b	#$f,d2
	or.b	d0,d2
.mt_vibskip2:
	move.b	d2,n_vibratocmd(a6)
	.else
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Vibrato2
	MOVE.B	n_vibratocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	.mt_vibskip
	AND.B	#$F0,D2
	OR.B	D0,D2
.mt_vibskip:	
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	.mt_vibskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
.mt_vibskip2:	
	MOVE.B	D2,n_vibratocmd(A6)
	.endif
mt_Vibrato2:	
	MOVE.B	n_vibratopos(A6),D0
	move.l	#mt_VibratoTable,A1
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	AND.B	#$03,D2
	BEQ.S	.mt_vib_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	.mt_vib_rampdown
	MOVE.B	#255,D2
	BRA.S	.mt_vib_set
.mt_vib_rampdown:	
	TST.B	n_vibratopos(A6)
	BPL.S	.mt_vib_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	.mt_vib_set
.mt_vib_rampdown2:	
	MOVE.B	D0,D2
	BRA.S	.mt_vib_set
.mt_vib_sine:	
	MOVE.B	0(A1,D0.W),D2
.mt_vib_set:	
	MOVE.B	n_vibratocmd(A6),D0
	AND.W	#$f,D0
	MULU	D0,D2
	LSR.W	#7,D2
	MOVE.W	n_period(A6),D0
	TST.B	n_vibratopos(A6)
	BMI.S	.mt_VibratoNeg
	ADD.W	D2,D0
	BRA.S	.mt_Vibrato3
.mt_VibratoNeg:	
	SUB.W	D2,D0
.mt_Vibrato3:
	set_period	d0
	MOVE.B	n_vibratocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_vibratopos(A6)
	RTS

mt_TonePlusVolSlide:	
	BSR	mt_TonePortNoChange
	BRA	mt_VolumeSlide

mt_VibratoPlusVolSlide:	
	BSR	mt_Vibrato2
	BRA	mt_VolumeSlide

mt_TremoloPlusSetBack:
	set_period	n_period(a6)
mt_Tremolo:
	.if	OPTIM
	move.b	d6,d0
	beq.s	mt_Tremolo2
	move.b	n_tremolocmd(a6),d2
	and.b	#$f,d0
	beq.s	.mt_treskip
	and.b	#$f0,d2
	or.b	d0,d2
.mt_treskip:
	move.b	d6,d0
	and.b	#$f0,d0
	beq.s	.mt_treskip2
	and.b	#$f,d2
	or.b	d0,d2
.mt_treskip2:
	move.b	d2,n_tremolocmd(a6)
	.else
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Tremolo2
	MOVE.B	n_tremolocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	.mt_treskip
	AND.B	#$F0,D2
	OR.B	D0,D2
.mt_treskip:	
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	.mt_treskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
.mt_treskip2:	
	MOVE.B	D2,n_tremolocmd(A6)
	.endif
mt_Tremolo2:	
	MOVE.B	n_tremolopos(A6),D0
	move.l	#mt_VibratoTable,A1
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	LSR.B	#4,D2
	AND.B	#$03,D2
	BEQ.S	.mt_tre_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	.mt_tre_rampdown
	MOVE.B	#255,D2
	BRA.S	.mt_tre_set
.mt_tre_rampdown:	
	TST.B	n_vibratopos(A6)
	BPL.S	.mt_tre_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	.mt_tre_set
.mt_tre_rampdown2:	
	MOVE.B	D0,D2
	BRA.S	.mt_tre_set
.mt_tre_sine:	
	MOVE.B	0(A1,D0.W),D2
.mt_tre_set:	
	MOVE.B	n_tremolocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#6,D2
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	TST.B	n_tremolopos(A6)
	BMI.S	.mt_TremoloNeg
	ADD.W	D2,D0
	BRA.S	.mt_Tremolo3
.mt_TremoloNeg:	
	SUB.W	D2,D0
.mt_Tremolo3:	
	BPL.S	.mt_TremoloSkip
	CLR.W	D0
.mt_TremoloSkip:	
	CMP.W	#$40,D0
	BLS.S	.mt_TremoloOk
	MOVE.W	#$40,D0
.mt_TremoloOk:
	set_volume	d0
	MOVE.B	n_tremolocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_tremolopos(A6)
	RTS

mt_SampleOffset:
	.if	OPTIM
	moveq	#0,d0
	move.b	d6,d0
	beq.s	.mt_sononew
	move.b	d0,n_sampleoffset(a6)
	bra.s	.mt_sook
.mt_sononew:
	move.b	n_sampleoffset(a6),d0
.mt_sook:
	lsl.w	#7,d0
	sub.w	d0,n_length(a6)
	bcs.s	.mt_sofskip
	add.l	d0,d0
	add.l	d0,n_start(a6)
	rts
.mt_sofskip:
	move.w	#1,n_length(a6)
	rts
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	.mt_sononew
	MOVE.B	D0,n_sampleoffset(A6)
.mt_sononew:	
	MOVE.B	n_sampleoffset(A6),D0
	LSL.W	#7,D0
	CMP.W	n_length(A6),D0
	BGE.S	.mt_sofskip
	SUB.W	D0,n_length(A6)
	LSL.W	#1,D0
	ADD.L	D0,n_start(A6)
	RTS
.mt_sofskip:	
	MOVE.W	#$0001,n_length(A6)
	RTS
	.endif

mt_VolumeSlidePlusSetBack:
	set_period	n_period(a6)
mt_VolumeSlide:
	.if	OPTIM
	move.b	d6,d0
	lsr.b	#4,d0
	beq.s	mt_VolSlideDown
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	BEQ.S	mt_VolSlideDown
	.endif
mt_VolSlideUp:	
	ADD.B	D0,n_volume(A6)
	CMP.B	#$40,n_volume(A6)
	BMI.S	.mt_vsuskip
	MOVE.B	#$40,n_volume(A6)
.mt_vsuskip:	
; 	MOVE.B	n_volume(A6),D0
; 	set_volume	d0
 	set_volume	n_volume(a6)
	RTS

mt_VolSlideDown:
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	.else	
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	.endif
mt_VolSlideDown2:	
	SUB.B	D0,n_volume(A6)
	BPL.S	.mt_vsdskip
	CLR.B	n_volume(A6)
.mt_vsdskip:	
; 	MOVE.B	n_volume(A6),D0
; 	set_volume	d0
 	set_volume	n_volume(a6)
	RTS

mt_PositionJump:
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	SUBQ.B	#1,D0
	bra.s skip_SetSongPos
mt_SetSongPos:
	MOVE.L 4(sp),D0
skip_SetSongPos:
	MOVE.B	D0,mt_SongPos
mt_pj2:	
	CLR.B	mt_PBreakPos
	ST 	mt_PosJumpFlag
	RTS

mt_VolumeChange:	
; 	MOVEQ	#0,D0
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	CMP.B	#$40,D0
	BLS.S	.mt_VolumeOk
	MOVEQ	#$40,D0
.mt_VolumeOk:	
	MOVE.B	D0,n_volume(A6)
	set_volume	d0
	RTS

mt_PatternBreak:	
	.if	OPTIM
	moveq	#0,d0
	move.b	d6,d0
	move.w	d0,d2
	lsr.w	#4,d0
	mulu.w	#10,d0
	and.w	#$f,d2
	add.w	d2,d0
	cmp.w	#63,d0
	bhi.s	mt_pj2
	move.b	d0,mt_PBreakPos
	st	mt_PosJumpFlag
	rts
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	MOVE.L	D0,D2
	LSR.B	#4,D0
	MULU	#10,D0
	AND.B	#$0F,D2
	ADD.B	D2,D0
	CMP.B	#63,D0
	BHI.S	mt_pj2
	MOVE.B	D0,mt_PBreakPos
	ST	mt_PosJumpFlag
	RTS
	.endif

mt_SetSpeed:
	.if	OPTIM
	move.b	d6,d0
	beq.s	.mt_rts
	cmp.b	#32,d0
	bhi.s	.mt_SetTempo
.mt_set_speed:	
	clr.b	mt_counter
	move.b	d0,mt_speed
.mt_rts:
	rts
.mt_SetTempo:
	tst.b	mt_tempo_flag
	bne.s	.mt_doSetTempo
	move.b	#32,d0
	bra.s	.mt_set_speed
.mt_doSetTempo:	
	move.b	d0,mt_tempo
	rts
	.else
	MOVE.B	3(A6),D0
	BEQ	mt_Return2
	CLR.B	mt_counter
	MOVE.B	D0,mt_speed
	RTS
	.endif

mt_CheckMoreEfx:	
	BSR	mt_UpdateFunk
	.if	OPTIM
	move.w	d6,d0
	lsr.w	#6,d0
	and.w	#$f<<2,d0
	.else
	move.b	2(a6),d0
	and.w	#$f,d0
	add.w	d0,d0
	add.w	d0,d0
	.endif
	move.l	.mt_CheckMoreEfx_table(pc,d0.w),-(sp)
	rts
.mt_CheckMoreEfx_table:
	dc.l	mt_PerNop	; 0
	dc.l	mt_PerNop	; 1
	dc.l	mt_PerNop	; 2
	dc.l	mt_PerNop	; 3
	dc.l	mt_PerNop	; 4
	dc.l	mt_PerNop	; 5
	dc.l	mt_PerNop	; 6
	dc.l	mt_PerNop	; 7
	dc.l	mt_PerNop	; 8
	dc.l	mt_SampleOffset	; 9
	dc.l	mt_PerNop	; A
	dc.l	mt_PositionJump	; B
	dc.l	mt_VolumeChange	; C
	dc.l	mt_PatternBreak	; D
	dc.l	mt_E_Commands	; E
	dc.l	mt_SetSpeed	; F

mt_E_Commands:
	.if	OPTIM	
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	and.w	#$f0,d0
	lsr.w	#2,d0
	move.l	.mt_E_Commands_table(pc,d0.w),-(sp)
	rts
.mt_E_Commands_table:
	dc.l	mt_FilterOnOff	; 0
	dc.l	mt_FinePortaUp	; 1
	dc.l	mt_FinePortaDown; 2
	dc.l	mt_SetGlissControl ; 3
	dc.l	mt_SetVibratoControl ; 4
	dc.l	mt_SetFineTune	; 5
	dc.l	mt_JumpLoop	; 6
	dc.l	mt_SetTremoloControl ; 7
	dc.l	mt_E8_Efx	; 8
	dc.l	mt_RetrigNote	; 9
	dc.l	mt_VolumeFineUp	; A
	dc.l	mt_VolumeFineDown ; B
	dc.l	mt_NoteCut	; C
	dc.l	mt_NoteDelay	; D
	dc.l	mt_PatternDelay	; E
	dc.l	mt_FunkIt	; F

mt_FilterOnOff:	
	RTS	

mt_SetGlissControl:
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	and.b	#$f0,n_glissfunk(a6)
	or.b	d0,n_glissfunk(a6)
	rts
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	RTS
	.endif

mt_SetVibratoControl:
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	and.b	#$f0,n_wavecontrol(a6)
	or.b	d0,n_wavecontrol(a6)
	rts
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS
	.endif

mt_SetFineTune:
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	move.b	d0,n_finetune(a6)
	rts
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	MOVE.B	D0,n_finetune(A6)
	RTS
	.endif

mt_JumpLoop:	
	TST.B	mt_counter
; 	BNE	mt_Return2
	bne.s	.mt_jumpret
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	beq.s	.mt_SetLoop
	subq.b	#1,n_loopcount(a6)
	bmi.s	.mt_jumpcnt
	beq.s	.mt_jumpret
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	.mt_SetLoop
	TST.B	n_loopcount(A6)
	BEQ.S	.mt_jumpcnt
	SUBQ.B	#1,n_loopcount(A6)
	BEQ	mt_Return2
	.endif
.mt_jmploop:	
	MOVE.B	n_pattpos(A6),mt_PBreakPos
	ST	mt_PBreakFlag
.mt_jumpret:	
	RTS
.mt_jumpcnt:	
	MOVE.B	D0,n_loopcount(A6)
	BRA.S	.mt_jmploop
.mt_SetLoop:	
	MOVE.W	mt_PatternPos,D0
	MOVE.B	D0,n_pattpos(A6)
	RTS

mt_SetTremoloControl:
	.if	OPTIM
	move.b	d6,d0
	lsl.b	#4,d0
	and.b	#$f,n_wavecontrol(a6)
	or.b	d0,n_wavecontrol(a6)
	rts
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS
	.endif

mt_E8_Efx:
	tst.b	mt_SetPan_flag
	beq.s	mt_KarplusStrong
mt_SetPanPosition:
	move.b	d6,d0
	and.b	#$f,d0
	set_balance	d0
	rts

mt_KarplusStrong:
	move.l	a0,d7		; save a0
        MOVE.L  n_loopstart(A6),A0
        MOVE.L  A0,A1
        MOVE.W  n_replen(A6),D0
        ADD.W   D0,D0
        SUBQ.W  #2,D0
.mt_karplop:	
        MOVE.B  (A0),D1
        EXT.W   D1
        MOVE.B  1(A0),D2
        EXT.W   D2
        ADD.W   D1,D2
        ASR.W   #1,D2
        MOVE.B  D2,(A0)+
        DBRA    D0,.mt_karplop
        MOVE.B  (A0),D1
        EXT.W   D1
        MOVE.B  (A1),D2
        EXT.W   D2
        ADD.W   D1,D2
        ASR.W   #1,D2
        MOVE.B  D2,(A0)
	move.l	d7,a0		; restore a0
        RTS
	
mt_RetrigNote:	
	MOVEQ	#0,D0
	.if	OPTIM
	move.b	d6,d0
	.else
	MOVE.B	n_cmdlo(A6),D0
	.endif
	AND.B	#$0F,D0
	BEQ	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter,D1
	BNE.S	.mt_rtnskp
	.if	OPTIM
	move.l	d6,d2
	swap	d2
	and.w	#$fff,d2
	bne	mt_rtnend
	.else
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	BNE	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter,D1
	.endif
.mt_rtnskp:	
	DIVU	D0,D1
	SWAP	D1
	TST.W	D1
	BNE	mt_rtnend
mt_DoRetrig:
	.if	!(^^defined	PAULA)
	clear_dma	n_dmabit(a6)
	.endif
	set_sample	n_start(a6),n_length(a6)
	set_dma		n_dmabit(a6)
	set_sample	n_loopstart(a6),n_replen(a6)
	set_period	n_period(a6)
mt_rtnend:	
	RTS

mt_VolumeFineUp:	
	TST.B	mt_counter
	BNE	mt_Return2
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F,D0
	.endif
	BRA	mt_VolSlideUp

mt_VolumeFineDown:	
	TST.B	mt_counter
	BNE	mt_Return2
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	.endif
	BRA	mt_VolSlideDown2

mt_NoteCut:
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	.endif
	CMP.B	mt_counter,D0
	bne.s	.mt_NoteCutRet
	CLR.B	n_volume(A6)
	set_volume	#0
.mt_NoteCutRet:	
	RTS

mt_NoteDelay:
	.if	OPTIM
	move.l	d6,d0
	and.b	#$f,d0
	cmp.b	mt_counter,d0
	bne.s	.mt_NoteDelayRet
	clr.w	d0
	swap	d0
	bne	mt_DoRetrig
.mt_NoteDelayRet:
	rts
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter,D0
	BNE	mt_Return2
	MOVE.W	(A6),D0
	BEQ	mt_Return2
	BRA	mt_DoRetrig
	.endif

mt_PatternDelay:
	TST.B	mt_counter
	bne.s	.mt_PatternDelayRet
	.if	OPTIM
	move.b	d6,d0
	and.b	#$f,d0
	tst.b	mt_PattDelTime2
	bne.s	.mt_PatternDelayRet
	addq.b	#1,d0
	move.b	d0,mt_PattDelTime
	.else
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	TST.B	mt_PattDelTime2
	BNE	mt_Return2
	ADDQ.B	#1,D0
	MOVE.B	D0,mt_PattDelTime
	.endif
.mt_PatternDelayRet:	
	RTS

mt_FunkIt:	
	TST.B	mt_counter
	BNE	mt_Return2
	AND.B	#$0F,n_glissfunk(A6)
	.if	OPTIM
	move.b	d6,d0
	lsl.b	#4,d0
	beq	mt_Return2
	or.b	d0,n_glissfunk(a6)
	.else
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	OR.B	D0,n_glissfunk(A6)
	TST.B	D0
	BEQ	mt_Return2
	.endif
mt_UpdateFunk:	
	MOVEQ	#0,D0
	MOVE.B	n_glissfunk(A6),D0
	LSR.B	#4,D0
	BEQ.S	.mt_funkend
	move.l	#mt_FunkTable,A1
	MOVE.B	(A1,D0.W),D0
	ADD.B	D0,n_funkoffset(A6)
	bcc.s	.mt_funkend
	CLR.B	n_funkoffset(A6)

	MOVE.L	n_loopstart(A6),D0
	MOVEQ	#0,D1
	MOVE.W	n_replen(A6),D1
	ADD.L	D1,D0
	ADD.L	D1,D0
	MOVE.L	n_wavestart(A6),A1
	ADDQ.w	#1,A1
	CMP.L	D0,A1
	BLO.S	.mt_funkok
	MOVE.L	n_loopstart(A6),A1
.mt_funkok:	
	MOVE.L	A1,n_wavestart(A6)
	MOVEQ	#-1,D0
	SUB.B	(A1),D0
	MOVE.B	D0,(A1)
.mt_funkend:
	RTS

	.data
mt_FunkTable:	
	dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_VibratoTable:		
	dc.b   0, 24, 49, 74, 97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120, 97, 74, 49, 24

mt_PeriodTable:	
; Tuning 0, Normal
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113
; Tuning 1
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113
; Tuning 2
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112
; Tuning 3
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111
; Tuning 4
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110
; Tuning 5
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109
; Tuning 6
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109
; Tuning 7
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108
; Tuning -8
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120
; Tuning -7
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119
; Tuning -6
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118
; Tuning -5
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118
; Tuning -4
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117
; Tuning -3
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116
; Tuning -2
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115
; Tuning -1
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114

	.bss
	.long
mt_chan1temp:	ds.b	n_sizeof
mt_chan2temp:	ds.b	n_sizeof
mt_chan3temp:	ds.b	n_sizeof
mt_chan4temp:	ds.b	n_sizeof
mt_chan5temp:	ds.b	n_sizeof
mt_chan6temp:	ds.b	n_sizeof
mt_chan7temp:	ds.b	n_sizeof
mt_chan8temp:	ds.b	n_sizeof
	
	.long
mt_SampleStarts:
	ds.l	31

	.long
mt_SongDataPtr:	
	ds.l	1
	.even
mt_PatternDataOffset:	ds.w	1
mt_SequenceDataOffset:	ds.w	1
mt_nbSamples:		ds.w	1
mt_nbVoices:		ds.w	1

	.even
mt_SongLength:	ds.b	1
mt_SongRestart:	ds.b	1

mt_no_repeat_flag:	ds.b	1
mt_tempo_flag:		ds.b	1
mt_SetPan_flag:		ds.b	1
mt_tempo:		ds.b	1
mt_speed:		ds.b	1		; 6
mt_counter:		ds.b	1
mt_SongPos:		ds.b	1
mt_PBreakPos:		ds.b	1
mt_PosJumpFlag:		ds.b	1
mt_PBreakFlag:		ds.b	1
mt_PattDelTime:		ds.b	1
mt_PattDelTime2:	ds.b	1

	.even
mt_ActiveVoices:	ds.w	1
mt_LowMask:		ds.w	1
	
	.even
mt_PatternPos:	ds.w	1
mt_DMACONtemp:	ds.w	1

;/* End of File */
