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

	include	"jaguar.inc"

	include	"../risc.s"
	
DSP_BG	equ	0
	
DSP_STACK_SIZE	equ	32	; long words

; 	.bss
; 	.phrase
; dsp_isp:	ds.l	DSP_STACK_SIZE
; 	.phrase
; dsp_usp:	ds.l	DSP_STACK_SIZE
; DSP_USP	equ	dsp_usp		
; DSP_ISP	equ	dsp_isp
DSP_USP	equ	(D_ENDRAM-(4*DSP_STACK_SIZE))
DSP_ISP	equ	(DSP_USP-(4*DSP_STACK_SIZE))

; VOICEs
; ======
; START (read by DSP)
; -----
; base address of sound
;
; LENGTH (read by DSP)
; ------
; length of sound in **bytes**
;
; CONTROL (read by DSP)
; -------
; 800Bbbbb 0Vvvvvvv IIIIiiii iiiiiiii
;
; 8: 0 = 8 bits sound, 1 = 16 bits sound
; Bbbbb: right balance from 0 to 16 [saturated] (left balance is 16 minus right balance)
; Vvvvvvv: volume from 0 to 64 [saturated]
; IIII.iiiiiiiiiiii: 4.12 resampling increment
;
; private fields
; ==============
; CURRENT (read/written by DSP) 
; -------
; current address in the sound
;
; END (read/written by DSP)
; ---
; end address of the sound
;
; FRAC (read/written by DSP)
; ----
; fractionnal increment (12 higher bits)

	.offset	0
VOICE_START:	ds.l	1
VOICE_LENGTH:	ds.l	1
VOICE_CONTROL:	ds.l	1
VOICE_CURRENT:	ds.l	1
VOICE_END:	ds.l	1
VOICE_FRAC:	ds.l	1
VOICE_SIZEOF:	ds.l	0

; CONTROL (read by DSP and cleared for acknowledgement)
; -------
; S0000000 00000000 00000000 OOOOOOOO
;
; S: 0 = clear bits, 1 = set bits
; O: activate/deactivate voice
;
; private fields
; ==============
; STATE (read/written by DSP)
; -----
; 00000000 00000000 00000000 OOOOOOOO
; O: voice on/off
	
	.offset	0
DMA_CONTROL:	ds.l	1
DMA_STATE:	ds.l	1
DMA_SIZEOF:	ds.l	0

	.text

LOG2_NB_VOICES	equ	3
NB_VOICES	equ	(1<<LOG2_NB_VOICES)

	.extern	_bcopy
	
;;; the DSP sound driver
;;; for sake of simplicity, it clears the interrupt handlers
;;; so you shoud install your own interrupts after having initialised
;;; the sound driver
;;; this code is not self-relocatable
	.phrase
dsp_sound_driver:
	.dsp
	.org	D_RAM
.dsp_sound_driver_begin:
	;; CPU interrupt
	padding_nop	$10
	;; I2S interrupt
	movei	#.dsp_sound_i2s_it,r28
	movei	#D_FLAGS,r30
	jump	(r28)
	load	(r30),r29	; read flags
	padding_nop	(D_RAM+$20-*)
	;; Timer 0 interrupt
	padding_nop	$10
	;; Timer 1 interrupt
	padding_nop	$10
	;; External 0 interrupt
	padding_nop	$10
	;; External 1 interrupt
	padding_nop	$10
.dsp_sound_i2s_it:
	.if	DSP_BG
	movei	#BG,r26
	movei	#$f800,r27
	storew	r27,(r26)
	moveq	#0,r27
	.endif
	;; init mixing
	movei	#.sound_dma,r14
	moveq	#0,r17		; right channel
	load	(r14+DMA_CONTROL/4),r18	; read DMA control
	load	(r14+DMA_STATE/4),r19	; read DMA state
	move	r14,r15
	moveq	#0,r16		; left channel
	addqt	#DMA_SIZEOF,r15	; VOICEs
	;; dma management
	move	r18,r24			; save control (for ack at the end) 
	move	r19,r20			; save DMA state
	shlq	#1,r18			; clear or set?
	jr	cc,.sound_dma_clear_bits
	shrq	#1,r18
.sound_dma_set_bits:
	jr	.sound_dma_ok_bits
	or	r18,r19
.sound_dma_clear_bits:
	not	r18
	and	r18,r19
.sound_dma_ok_bits:
	xor	r19,r20
	jr	eq,.sound_dma_same
	and	r19,r20			; r20 contains the new voices activated 	
	store	r19,(r14+DMA_STATE/4)	; save state
.sound_dma_same:	
	;; start mixing
	move	PC,r22
	moveq	#NB_VOICES,r21		; mix all voices
	move	r22,r25
	addq	#.sound_mixing-.sound_dma_same,r22	; .sound_mixing
	movei	#.sound_mix_next,r23			; .sound_mix_next
	addq	#.sound_loop-.sound_dma_same,r25	; .sound_loop 
.sound_mixing:
	;; r14:	sound_dma address
	;; r15:	current voice address
	;; r16:	left channel
	;; r17:	right channel (actually the two channels are swapped, so it depends on the parity of r21)
	;; r12: new left sample is put here
	;; r13:	new right sample is put here
	;; r19:	dma state (voices enabled)
	;; r20:	new voices enabled
	;; r21:	number of voices remaining
	;; r22:	.sound_mixing
	;; r23:	.sound_mix_next
	;; r24:	dma_control
	shrq	#1,r20			; new voice enabled?
	jr	cc,.sound_no_change	; no! 
	moveq	#0,r13			; clear right sample
.sound_set_voice:
	move	r13,r12
	shrq	#1,r19			; voice is enabled since by definition r20 = r19 & something
	store	r13,(r15+VOICE_FRAC/4)		; clear fractionnal increment
.sound_loop:
	load	(r15+VOICE_START/4),r1		; start address
	load	(r15+VOICE_LENGTH/4),r2		; length in bytes 
	add	r1,r2				; end of sound
	cmpq	#0,r1
	jr	ne,.sound_no_loop
	store	r2,(r15+VOICE_END/4)		; new end address
	jump	(r23)				; if loop = 0 then skip voice 
	store	r1,(r15+VOICE_CURRENT/4)	; and clear current pointer
.sound_no_change: 
	shrq	#1,r19			; voice enabled? 	
	jump	cc,(r23)		; no then .sound_mix_next
	moveq	#0,r12			; clear left sample
.sound_compute_voice:
	load	(r15+VOICE_CURRENT/4),r1	; current address
	load	(r15+VOICE_END/4),r2		; end address
	cmpq	#0,r1				; current = 0?
	jump	eq,(r23)			; if current = 0 then skip voice
	cmp	r2,r1				; end <= current
	jump	pl,(r25)			; yes then go .sound_loop
	load	(r15+VOICE_CONTROL/4),r3	; voice control 
.sound_no_loop:
	load	(r15+VOICE_FRAC/4),r4		; fractionnal increment
	move	r3,r5		; copy control
	move	r3,r2		; copy control
	shlq	#16,r5		; 
	shlq	#16+4,r3	; get fractionnal increment
	jr	cc,.sound_8_bits
	shrq	#32-4,r5	; get integer increment
.sound_16_bits:
	add	r3,r4		; add fractionnal increment
	loadw	(r1),r12	; load sample (flags unaffected)
	addc	r5,r1		; add integer increment with carry
	jr	.sound_sample_ok
	sub	r3,r4		; remove fractionnal increment (so that we get another carry)
.sound_8_bits:
	loadb	(r1),r12
	shlq	#8,r12		; put on 16 bits
.sound_sample_ok:
	add	r3,r4		; add fractionnal increment
	store	r4,(r15+VOICE_FRAC/4) ; store fractionnal increment (no scoreboard failure since ALU operation for r4)
	move	r2,r4		; get balance
	addc	r5,r1		; add integer increment with carry
	shlq	#16-7,r2	; to get volume
	shlq	#16-13,r4	; 5 bits
	sharq	#32-7,r2	; volume
	jr	pl,.sound_volume_no_sat
	move	r12,r13		; copy sample
	movei	#64,r2		; saturate at 64
.sound_volume_no_sat:		
	sharq	#32-5,r4	; right balance
	jr	pl,.sound_balance_no_sat
	moveq	#16,r3
	moveq	#16,r4		; saturate at 16
.sound_balance_no_sat:	
	store	r1,(r15+VOICE_CURRENT/4) ; store next sample position
	sub	r4,r3		; left balance = 16 - right balance
	mult	r2,r4		; get left volume
	mult	r2,r3		; get right volume
	imult	r4,r13		; signed multiply by right volume
	imult	r3,r12		; signed multiply by left volume
.sound_mix_next:
	add	r13,r17		; add right channel
	subq	#1,r21		; one channel less
	addqt	#VOICE_SIZEOF,r15	; next voice (flags unaffected)
	jump	ne,(r22)		; .sound_mixing
	add	r12,r16		; add left channel
.sound_end_mixing:	 
	;; mix finished!
	cmpq	#0,r24			; was control = 0?
					; it would be incorrect to re-read control 
					; at this point since it could have been
					; written between the two reads 
	jr	eq,.sound_no_ack	; yes then no ack
	moveq	#0,r0			; otherwise
	store	r0,(r14+DMA_CONTROL/4)	; acknowledge
.sound_no_ack:
	;; output channels
	movei	#L_I2S,r15	; I2S output
	sharq	#6+4+LOG2_NB_VOICES-1,r16 ; 6 for volume, 4 for balance
	sharq	#6+4+LOG2_NB_VOICES-1,r17 ; 
	sat16s	r16		; saturate
	sat16s	r17		; idem
;; 	store	r16,(r15)	; write left channel
;; 	store	r17,(r15+1)	; write right channel
	store	r16,(r15+1)	; write left channel (Zerosquare fix)
	store	r17,(r15)	; write right channel (Zerosquare fix)
	.if	DSP_BG
	storew	r27,(r26)
	.endif
	;; return from interrupt
	load	(r31),r28	; return address
	bset	#10,r29		; clear latch 1
	bclr	#3,r29		; clear IMASK
	addq	#4,r31		; pop from stack
	addqt	#2,r28		; next instruction
	jump	t,(r28)		; return
	store	r29,(r30)	; restore flags
	.long
.sound_dma:
SOUND_DMA	equ	.sound_dma
	.rept	DMA_SIZEOF/4
	dc.l	0
	.endr
	.long
.sound_voices:
;;; voices are alternating: left, right, left, right, ...
SOUND_VOICES	equ	.sound_voices
	.rept	NB_VOICES
	.rept	VOICE_SIZEOF/4
	dc.l	0
	.endr
	.endr	
.dsp_sound_driver_loop:
	move	PC,r0		; .dsp_sound_driver_loop
	move	r0,r1		; .dsp_sound_driver_loop
	addq	#.dsp_sound_driver_param-.dsp_sound_driver_loop,r0 ; .dsp_sound_driver_param
	load	(r0),r2		; read SUBROUT_ADDR
	moveq	#0,r3
	cmpq	#0,r2		; SUBROUT_ADDR != null
	jr	eq,.dsp_sound_driver_loop ; if null then loop
	nop
	subq	#4,r31		; push on stack
	store	r3,(r0)		; clear SUBROUT_ADDR
	jump	(r2)		; jump to SUBROUT_ADDR
	store	r1,(r31)	; return address
	.long
.dsp_sound_driver_param:
DSP_SUBROUT_ADDR	equ	.dsp_sound_driver_param
	dc.l	0
	.long
.dsp_sound_driver_init:
	;; assume run from bank 1
	movei	#DSP_ISP+(DSP_STACK_SIZE*4),r31	; init isp
	moveq	#0,r1
	moveta	r31,r31		; ISP (bank 0)
	movei	#DSP_USP+(DSP_STACK_SIZE*4),r31	; init usp
	movei	#.dsp_sound_driver_param,r0
	movei	#.dsp_sound_driver_loop,r2
	;; set I2S
	movei	#SCLK,r10
	movei	#SMODE,r11
	movei	#.dsp_sound_driver_init_param,r12
;; 	movei	#%010101,r13	; SMODE
	movei	#%001101,r13	; SMODE (Zerosquare fix)
	load	(r12),r12	; SCLK
	store	r12,(r10)
	store	r13,(r11)
	;; enable interrupts
	movei	#D_FLAGS,r28
	movei	#D_I2SENA|REGPAGE,r29
	store	r29,(r28)
	;; go to driver
	jump	(r2)
	store	r1,(r0)		; clear SUBROUT_ADDR (mutex)
	.long
.dsp_sound_driver_init_param:
	dc.l	0
	.long
.dsp_sound_driver_end:
		
SOUND_DRIVER_INIT	equ	.dsp_sound_driver_init
SOUND_DRIVER_INIT_PARAM	equ	.dsp_sound_driver_init_param
SOUND_DRIVER_SIZE	equ	.dsp_sound_driver_end-.dsp_sound_driver_begin

DSP_FREE_RAM		set	.dsp_sound_driver_init

	.print	"Sound driver code size (DSP): ", SOUND_DRIVER_SIZE
	.print	"Available DSP Ram after D_RAM+",DSP_FREE_RAM-D_RAM
				
	.68000

.macro	dsp_interrupt
.endm
	
	.globl	DSP_SUBROUT_ADDR
	.globl	__DSP_FREE_RAM
__DSP_FREE_RAM	equ	DSP_FREE_RAM

	.globl	_init_sound_driver
;; int init_sound_driver(int frequency)
_init_sound_driver:
	move.l	#0,D_CTRL
	;; copy DSP code
	pea	SOUND_DRIVER_SIZE	
	pea	D_RAM
	pea	dsp_sound_driver
	jsr	_bcopy
	lea	12(sp),sp
	;; set timers
	move.l	4(sp),d0
	; n = (830968,75/(2*freq))-1 = 25 for 16000hz
        ; f = 830968,75/(2*(n+1))
; 	move.l	d0,replay_frequency
	move.l	#83096875,d1
	divu.w	d0,d1
	and.l	#$ffff,d1
	divu.w	#200,d1
	and.l	#$ffff,d1
	subq.l	#1,d1
	move.l	d1,SOUND_DRIVER_INIT_PARAM
 	addq.l	#1,d1
	mulu.w	#200,d1
 	move.l	#83096875,d0
 	divu.w	d1,d0
	and.l	#$ffff,d0
 	move.l	d0,replay_frequency
; 	;; I2S
; 	move.l	#%010101,SMODE
; 	move.l	d1,SCLK
	;; set DSP for interrupts
	move.l	#REGPAGE,D_FLAGS
	;; launch the driver
	move.l	#DSP_SUBROUT_ADDR,a0
	move.l	#$ffffffff,(a0)
	move.l	#SOUND_DRIVER_INIT,D_PC
	move.l	#DSPGO,D_CTRL
	bsr	compute_amiga_frequencies ; does not modify a0
.wait_init:
	tst.l	(a0)
	bne.s	.wait_init
	move.l	replay_frequency,d0
	rts

	.globl	_jump_dsp_subroutine
;; jump_dsp_subroutine(void *addr); 
_jump_dsp_subroutine:
	move.l	4(sp),DSP_SUBROUT_ADDR
	rts

MAX_PERIOD	equ	1024

compute_amiga_frequencies:
	move.l	d2,-(sp)
	move.l	replay_frequency,d2	
	move.l	#_amiga_frequencies + (2*MAX_PERIOD),a1
	move.l	#MAX_PERIOD-1,d0
.compute_one_period:
	move.l	#7159092,d1	; (10^7 / 2.79365) << 1
	tst.l	d0
	beq.s	.skip_div
	divu.w	d0,d1
.skip_div:	
	swap	d1
	clr.w	d1
	lsr.l	#5,d1		; <<11
	divu.w	d2,d1
	move.w	d1,-(a1)
	dbf	d0,.compute_one_period
	move.l	(sp)+,d2
	rts

.macro	wait_dma
.wait\~:
	tst.l	\1
	bne.s	.wait\~
.endm
	
	.globl  _set_voice
;; void set_voice(int voice_num, int control, char *start, int len, char *loop_start, int loop_len);
_set_voice:
        move.l  #SOUND_VOICES,a0
	move.l  0+4(sp),d0
        and.l   #NB_VOICES-1,d0
	moveq	#1,d1
	lsl.l	d0,d1		; select voice
        mulu.w  #VOICE_SIZEOF,d0
        lea     (a0,d0.l),a0
	;; 
	move.l	#SOUND_DMA,a1
	wait_dma	DMA_CONTROL(a1)
	move.l	d1,DMA_CONTROL(a1) ; disable voice
	;; 
	move.l	0+8(sp),VOICE_CONTROL(a0)
	move.l	0+12(sp),VOICE_START(a0)
	move.l	0+12+4(sp),VOICE_LENGTH(a0)
	;; 
	or.l	#$80000000,d1
	wait_dma	DMA_CONTROL(a1)
	move.l	d1,DMA_CONTROL(a1) ; enable voice
	wait_dma	DMA_CONTROL(a1)
	;; 
	move.l	0+20(sp),VOICE_START(a0)
	move.l	0+20+4(sp),VOICE_LENGTH(a0)
        rts

	.globl	_clear_voice
;; void clear_voice(int voice_num);
_clear_voice:
        move.l  #SOUND_VOICES,a0
	move.l  0+4(sp),d0
        and.l   #NB_VOICES-1,d0
	moveq	#1,d1
	lsl.l	d0,d1		; select voice
        mulu.w  #VOICE_SIZEOF,d0
        lea     (a0,d0.l),a0
	;; 
	move.l	#SOUND_DMA,a1
	wait_dma	DMA_CONTROL(a1)
	move.l	d1,DMA_CONTROL(a1) ; disable voice
	rts
	
	.globl	_set_panning
;; void set_panning(int voice_num, int panning);
_set_panning:	
        move.l  #SOUND_VOICES,a0
	move.l  0+4(sp),d0
        and.l   #NB_VOICES-1,d0
	moveq	#1,d1
	lsl.l	d0,d1		; select voice
        mulu.w  #VOICE_SIZEOF,d0
        lea     (a0,d0.l),a0
	;;
	move.w	0+8+2(sp),d0
	and.w	#%11111,d0
	move.l	VOICE_CONTROL(a0),d1
	rol.l	#8,d1
	and.b	#%11100000,d1
	or.b	d0,d1
	ror.l	#8,d1
	move.l	d1,VOICE_CONTROL(a0)
	rts

	.globl	_set_volume
;; void set_volume(int voice_num, int volume);
_set_volume:	
        move.l  #SOUND_VOICES,a0
	move.l  0+4(sp),d0
        and.l   #NB_VOICES-1,d0
	moveq	#1,d1
	lsl.l	d0,d1		; select voice
        mulu.w  #VOICE_SIZEOF,d0
        lea     (a0,d0.l),a0
	;;
	move.w	0+8+2(sp),d0
	and.w	#%1111111,d0
	move.l	VOICE_CONTROL(a0),d1
	swap	d1
	move.b	d0,d1
	swap	d1
	move.l	d1,VOICE_CONTROL(a0)
	rts

	.data
	.even
	dc.b	"Sound Driver by Seb/The Removers"
	.even

	.bss
	.long
replay_frequency:
	ds.l	1
	
	.long
	.globl	_amiga_frequencies
_amiga_frequencies:
	ds.w	MAX_PERIOD
	.long

	.text
SOUND_VOICE0	equ	SOUND_VOICES
SOUND_VOICE1	equ	SOUND_VOICE0+VOICE_SIZEOF
SOUND_VOICE2	equ	SOUND_VOICE1+VOICE_SIZEOF
SOUND_VOICE3	equ	SOUND_VOICE2+VOICE_SIZEOF
SOUND_VOICE4	equ	SOUND_VOICE3+VOICE_SIZEOF
SOUND_VOICE5	equ	SOUND_VOICE4+VOICE_SIZEOF
SOUND_VOICE6	equ	SOUND_VOICE5+VOICE_SIZEOF
SOUND_VOICE7	equ	SOUND_VOICE6+VOICE_SIZEOF		
	
	include	"pt-play.s"

	.text
	.globl	_init_module
;; init_module(char *module, int tempo_enabled);
_init_module	equ	mt_init

	.globl	_play_module
;; play_module();
_play_module	equ	mt_music_vbl

	.globl	_clear_module
;; clear_module();
_clear_module	equ	mt_clear

	.globl	_pause_module
;; pause_module();
_pause_module	equ	mt_pause

	.globl	_enable_module_voices
;; enable_module_voices(int mask);
_enable_module_voices	equ	mt_enable_voices

	.globl	_set_song_position
;; set_song_position(int position);
_set_song_position	equ	mt_SetSongPos
	
