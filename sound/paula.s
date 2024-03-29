; The Removers'Library
; Copyright (C) 2006-2012 Seb/The Removers
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

	;; enable this to display time devoted to resampling
DSP_BG	equ	0

	;; a stack size of 1 is enough
DSP_STACK_SIZE	equ	2	; long words

	;; audio buffer size
	;; max size corresponds to 44100 Hz, for a VBL at 50 Hz
MAX_BUFSIZE	equ	882

	;; display cases when command interrupt tweak return address
CHECK_FIXING	equ	0

RED	equ	$f800
BLUE	equ	$07c0
GREEN	equ	$003f

DSP_USP	equ	(D_ENDRAM-(4*DSP_STACK_SIZE))
DSP_ISP	equ	(DSP_USP-(4*DSP_STACK_SIZE))

	include	"./paula_def.s"

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
	movei	#.dsp_sound_cpu_it,r28
	movei	#D_FLAGS,r30
	jump	(r28)
	load	(r30),r29	; read flags
	padding_nop	(D_RAM+$10-*)
	;; I2S interrupt
	movei	#D_FLAGS,r30
	load	(r30),r29	; read flags
.dsp_sound_i2s_it:
	;; r0 = start of first half (currently played)
	;; r1 = end of first half
	;; r2 = start of other half (currently generated)
	;; r3 = end of other half
	;; r14 = current pointer in played buffer
	;; r15 = L_I2S
	;; r16, r17 = reserved
	;; register usage = r4, r5
	load	(r14),r4		; left sample
	load	(r14+1),r5		; right sample
	addq	#8,r14
	sharq	#8+5+LOG2_NB_VOICES,r4	; rescale sample (8 for volume, 5 for balance)
	sharq	#8+5+LOG2_NB_VOICES,r5	; rescale sample
	sat16s	r4			; saturate left sample
	sat16s	r5			; saturate right sample
	store	r4,(r15+1)	; write left channel (Zerosquare fix)
	store	r5,(r15)	; write right channel (Zerosquare fix)
	cmp	r14,r1
	jr	ne,.no_swap	; have we reached the end of buffer?
	moveq	#1,r4
	;; r0 <-> r2
	;; r1 <-> r3
	;; r14 := previous r2 = current r0
	move	r2,r14		; other half becomes active buffer
	move	r3,r5		; update end pointer of active buffer
	move	r0,r2		; first half becomes other half
	move	r1,r3
	move	r14,r0		; other half becomes first half
	move	r5,r1
	moveta	r4,r0		; indicate switch of sound buffer to main loop
.no_swap:
	;; return from interrupt
	load	(r31),r28	; return address
	bset	#10,r29		; clear latch 1
	bclr	#3,r29		; clear IMASK
	addqt	#4,r31		; pop from stack
	addqt	#2,r28		; next instruction
	jump	(r28)		; return
	store	r29,(r30)	; restore flags
.dsp_sound_cpu_it:
	;; r0, r1, r2, r3, r14, r15 = reserved
	;; r16 = SOUND_DMA
	;; r17 = VOICES
	;; r18 = DMA_STATE
	;; register usage = r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r18
	move	r15,r5		; save r15
	;;
	move	r17,r15		; SOUND_VOICES
	load	(r16),r6
	movei	#.no_command,r28
	cmpq	#0,r6
	moveq	#0,r13		; no need to adjust return address
	jump	eq,(r28)	; => .no_command
	move	r6,r8		; backup command
	move	r6,r7
	sharq	#31,r8		; replicate command bit on r8
				; r8 = 0 if CLEAR, r8 = FFFFFFFF if SET
	moveq	#NB_VOICES,r9
	movefa	r3,r4		; load loop counter of main loop
.do_command:
	shrq	#1,r6
	jr	cc,.skip_voice
	moveq	#0,r10
	load	(r15+VOICE_START/4),r11		; start address
	load	(r15+VOICE_LENGTH/4),r12	; length in bytes
	store	r10,(r15+VOICE_FRAC/4)		; clear fractionnal increment
	add	r11,r12				; end address
	and	r8,r11
	and	r8,r12
	store	r11,(r15+VOICE_CURRENT/4)	; update current pointer
	cmp	r4,r9				; compare voice counter with main loop voice counter
	jr	ne,.skip_voice
	store	r12,(r15+VOICE_END/4)		; and end pointer
	moveq	#1,r13				; return address needs to be fixed
.skip_voice:
	subq	#1,r9		; one voice has been processed
	jr	ne,.do_command
	addqt	#VOICE_SIZEOF,r15 ; next voice
	;; new state = command (voice + state) + (not command) (not voice) state
	;; let c = command, s = state, v = voice
	;; s' = c (v + s) + ~c ~v s = c v + c s + ~c ~v s
	;; ie s' = c v + c (v + ~v) s + ~c ~v s
	;;       = c v + c v s + c ~v s + ~c ~v s
	;;       = c v (1 + s) + (c ~v + ~c ~v) s
	;;       = c v + (c + ~c) ~v s
	;;       = c v + ~v s
	move	r7,r6		; v
	not	r7		; ~v
	and	r8,r6		; c v
	and	r7,r18		; ~v s
	store	r10,(r16)	; acknowledge command
	or	r6,r18		; c v + ~v s
.no_command:
	;;
	move	r5,r15		; restore r15
	;; fix return address
	movei	#.return_from_interrupt,r28
	cmpq	#0,r13
	.if	CHECK_FIXING
	movei	#BG,r5
	.endif
	jump	eq,(r28)
	.if	CHECK_FIXING
	moveq	#0,r4
	.else
	nop
	.endif
	load	(r31),r13	; load return address
	addqt	#2,r13		; next instruction
	;; check whether .load_values <= r13 < .values_loaded
	movei	#.load_values,r10
	movei	#.values_loaded,r11
	cmp	r10,r13		; .load_values <= r13 ?
	jump	mi,(r28)	; no => .return_from_interrupt
	cmp	r11,r13		; .values_loaded <= r13 ?
	jr	pl,.not_loading	; yes => .not_loading
	subqt	#2,r10
.loading:
	;; here we force reading again the values
	.if	CHECK_FIXING
	movei	#GREEN,r4
	.endif
	jump	(r28)
	store	r10,(r31)
.not_loading:
	;; we already know that .values_loaded <= r13
	;; check whether .values_loaded <= r13 < .generate_end
	movei	#.generate_end,r11
	movei	#.next_voice,r12
	cmp	r11,r13		; .generate_end <= r13 ?
	jr	pl,.not_generating ; yes => .not_generating
	nop
	;; here we force the main loop to skip code at .generate_end
	;; and jump directly at .next_voice when generation is done
	.if	CHECK_FIXING
	movei	#BLUE,r4
	.endif
	jump	(r28)
	moveta	r12,r28
.not_generating:
	;; check whether .generate_end <= r13 < .next_voice
	cmp	r12,r13
	jr	pl,.return_from_interrupt
	subqt	#2,r12
	.if	CHECK_FIXING
	movei	#RED,r4
	.endif
	;; here we force to skip code at .generate_end and
	;; jump directly to .next_voice
	store	r12,(r31)
.return_from_interrupt:
	.if	CHECK_FIXING
	storew	r4,(r5)
	.endif
	;; return from interrupt
	load	(r31),r28	; return address
	bset	#9,r29		; clear latch 0
	bclr	#3,r29		; clear IMASK
	addqt	#4,r31		; pop from stack
	addqt	#2,r28		; next instruction
	jump	(r28)		; return
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
.dsp_sound_driver_main:
	;; BEWARE: r0 is used by it handler to indicate that audio
	;;         buffers have been switched
	move	PC,r30
	cmpq	#0,r0		; is sound generation requested?
	jump	eq,(r30)	; => .dsp_sound_driver_main
	movefa	r17,r15		; SOUND_VOICES
	moveq	#0,r0		; reset flag
	movefa	r2,r1		; get working buffer start address
	movefa	r3,r2		; and end address
	;;
	.if	DSP_BG
	movei	#BG,r29
	movei	#$f800,r28
	storew	r28,(r29)
	.endif
	;; we first clear the audio buffer
	move	r1,r4		;
	move	r1,r3		; left channel
	addqt	#4,r4		; right channel
	moveq	#0,r5
.clear_buffer:
	store	r5,(r3)
	addqt	#8,r3
	store	r5,(r4)
	cmp	r3,r2
	jr	ne,.clear_buffer
	addqt	#8,r4
	;; we now remix the voices that are enabled
	;; r15 = current voice
	;; r1 = start address of working buffer
	;; r2 = end address of working buffer
	moveq	#NB_VOICES,r3	; number of VOICEs (WARNING: read by interrupt to detect if hack of return address is needed)
	movefa	r18,r16		; get DMA_STATE
.do_voice:
	move	PC,r29		; to loop
	movei	#.next_voice,r28      ; .next_voice
	;; r3 = VOICE counter
	;; r16 = DMA state (shifted at each iteration)
	shrq	#1,r16		; is current VOICE enabled?
	jump	cc,(r28)	; no => .next_voice
	nop
	;; read voice parameters
.load_values:
	load	(r15+VOICE_CURRENT/4),r17	; current pointer
	load	(r15+VOICE_END/4),r18		; end pointer
	load	(r15+VOICE_START/4),r19		; loop pointer
	load	(r15+VOICE_LENGTH/4),r20	; length of loop in bytes
	cmpq	#0,r17				; is there a sound to play?
	load	(r15+VOICE_FRAC/4),r21		; fractionnal increment
	jump	eq,(r28)			; no sound => .next_voice
	load	(r15+VOICE_CONTROL/4),r22	; voice control
	add	r19,r20				; compute end of loop
	movei	#.generate_end,r28		; WARNING: is possibly forced to be .next_voice by interrupt
.values_loaded:
	;; we now extract all the needed information from CONTROL word
	move	r22,r23			; to get resampling increment
	move	r22,r24			; to get volume
	move	r22,r25			; to get balance
	shlq	#9,r24			; clear high part to get volume
	shlq	#3,r25			; clear high part to get balance
	movei	#volume_table,r26
	sharq	#32-7,r24		; get volume index
	move	r26,r14
	jr	pl,.get_volume
	shlq	#16,r23			; clear high part to get resampling increment
	moveq	#1,r24			; compute maximum volume
	jr	.volume_ok
	shlq	#8,r24			; 8 bit fix-point arithmetic
.get_volume:
	add	r24,r26
	loadb	(r26),r24		; get volume in table
.volume_ok:
	sharq	#32-5,r25		; get balance
	movei	#16,r26			; to saturate balance
	jr	pl,.get_balance
	shrq	#31,r22			; get 8 bits/16 bits flag
	move	r26,r25			; saturate balance to 16
.get_balance:
	cmpq	#8,r25
	jr	pl,.balanced_right
	nop
.balanced_left:
	;; 0 <= balance < 8
	;; so left balance = 256
	;; and right balance is volume_table[balance*32]
	shlq	#5,r25
	shlq	#4,r26		; left balance = 16 << 4 = 256
	add	r14,r25
	jr	.balance_ok
	loadb	(r25),r25	; read right balance
.balanced_right:
	;; balance >= 8
	jr	eq,.not_balanced
	sub	r25,r26		; 16 - balance
	;; 8 < balance <= 16
	;; so right balance = 256
	;; and left balance is volume_table[(16-balance)*32]
	moveq	#1,r25
	shlq	#5,r26
	shlq	#8,r25		; right balance = 256
	add	r14,r26
	jr	.balance_ok
	loadb	(r26),r26	; read left balance
.not_balanced:
	;; balance = 8
	moveq	#1,r25
	moveq	#1,r26
	shlq	#8,r25			; right balance = 256
	shlq	#8,r26			; left balance = 256
.balance_ok:
	shrq	#3,r25			; rescale right balance
	shrq	#3,r26			; rescale left balance
	mult	r24,r25			; right factor = right balance * volume factor (on 12 bits)
	mult	r26,r24			; left factor = left balance * volume factor (on 12 bits)
	;; at this point, we have
	;; r17 = current pointer
	;; r18 = current end
	;; r19 = replay pointer
	;; r20 = end of replay
	;; r21 = fractionnal increment
	;; r22 = 8 bits/16 bits flag (0 = 8 bits, 1 = 16 bits)
	;; r23 = resampling increment << 16
	;; r24 = left factor
	;; r25 = right factor
	sh	r22,r17		; convert address in samples
	sh	r22,r18		; this only affect 16 bits samples
	sh	r22,r19		; and simplify the management
	sh	r22,r20		; this works because 16 bits samples
				; must be aligned on 2 bytes boundary
	;;
	move	r23,r26
	shrq	#32-4,r23	; integer part of resampling increment
	shlq	#4,r26		; fractionnal part of resampling increment
	;;
	movei	#~3,r14		; for prefetching
	moveq	#0,r6		; no address prefetched initially
	move	r1,r4		; left pointer in working buffer
	cmpq	#0,r22		; 8 bits or 16 bits?
	move	r1,r5		; get pointer in working buffer
	jr	eq,.do_voice_8_bits
	addqt	#4,r5		; right pointer in working buffer
	movei	#.do_voice_16_bits,r27
	jump	(r27)
	;; addqt	#.generate_voice_16_bits-.do_voice_16_bits,r27
	nop
.do_voice_8_bits:
	movei	#.generate_voice_8_bits,r27
.generate_voice_8_bits:
	;; register usage
	;; r0 = reserved by interrupt
	;; r1 = working buffer start address
	;; r2 = working buffer end address
	;; r3 = voice counter (read by interrupt)
	;; r4 = left channel
	;; r5 = right channel
	;; r15 = current voice
	;; r16 = voice state
	;; r17 = current pointer (not null)
	;; r18 = end pointer
	;; r19 = loop pointer
	;; r20 = end of loop
	;; r21 = fractionnal increment (so that address of "real sample" is r17.r21)
	;; r22 = 0 if 8 bits, 1 if 16 bits
	;; r23 = integer part of resampling increment
	;; r24 = left volume
	;; r25 = right volume
	;; r26 = fractionnal part of resampling increment
	;; r27 = .generate_voice_{8,16}_bits
	;; r28 = .generate_end (may be modified by interrupt to .next_voice)
	;; r29 = .do_voice
	;; r30 = .dsp_sound_driver_main
	;; free/working registers = r6, r7, r8, r9, r10, r11, r12, r13, r14
	;; r6 = address of last prefetch
	;; r9 = prefetched samples
	;; r14 = ~3
	cmp	r18,r17		; end <= current?
	jr	mi,.no_loop_8_bits
	cmpq	#0,r19		; is there a sound
	move	r19,r17		; copy loop pointer
	jump	eq,(r28)	; => .generate_end
	move	r20,r18		; new end pointer
.no_loop_8_bits:
	moveq	#3,r8
	move	r14,r7		; ~3
	and	r17,r8		; address & 3
	and	r17,r7		; address & ~3
	shlq	#3,r8		; 8 * (address & 3)
	cmp	r6,r7
	subqt	#24,r8		; 8 * (address & 3) - 8 * 3
	jr	eq,.no_reload_8_bits
	neg	r8		; 8 * 3 - 8 * (address & 3)
	load	(r7),r9		; prefetch four samples at (address & ~3) [A;B;C;D]
	move	r7,r6
.no_reload_8_bits:
	add	r26,r21		; add fractionnal part to fractionnal increment
	move	r9,r12		; copy samples
	addc	r23,r17		; add integer part with carry to current pointer
	ror	r8,r12		; get current sample
	load	(r4),r10	; read left voice
	shlq	#8,r12		; rescale 8 bits sample
	load	(r5),r11	; read right voice
	move	r12,r13
	imult	r24,r12		; * left volume
	imult	r25,r13		; * right volume
	add	r12,r10		; add to left channel
	add	r13,r11		; add to right channel
	store	r10,(r4)
	addqt	#8,r4
	store	r11,(r5)
	cmp	r4,r2		; have we finished?
	jump	ne,(r27)	; => .generate_voice
	addqt	#8,r5
	jump	(r28)		; => .generate_end (interrupt may change to .next_voice)
	nop
.do_voice_16_bits:
.generate_voice_16_bits:
	;; register usage
	;; r0 = reserved by interrupt
	;; r1 = working buffer start address
	;; r2 = working buffer end address
	;; r3 = voice counter (read by interrupt)
	;; r4 = left channel
	;; r5 = right channel
	;; r15 = current voice
	;; r16 = voice state
	;; r17 = current pointer (not null)
	;; r18 = end pointer
	;; r19 = loop pointer
	;; r20 = end of loop
	;; r21 = fractionnal increment (so that address of "real sample" is r17.r21)
	;; r22 = 0 if 8 bits, 1 if 16 bits
	;; r23 = integer part of resampling increment
	;; r24 = left volume
	;; r25 = right volume
	;; r26 = fractionnal part of resampling increment
	;; r27 = .generate_voice_{8,16}_bits
	;; r28 = .generate_end (may be modified by interrupt to .next_voice)
	;; r29 = .do_voice
	;; r30 = .dsp_sound_driver_main
	;; free/working registers = r6, r7, r8, r9, r10, r11, r12, r13, r14
	;; r6 = address of last prefetch
	;; r9 = prefetched samples
	;; r14 = ~3
	cmp	r18,r17		; end <= current?
	jr	mi,.no_loop_16_bits
	move	r17,r12		; copy r17 to compute address of 16 bits sample
	move	r19,r17		; copy loop pointer
	move	r19,r12		; ensure that r12 = r17
	cmpq	#0,r17		; is there a sound?
	move	r20,r18		; new end pointer
	jump	eq,(r28)	; => .generate_end
.no_loop_16_bits:
	add	r12,r12		; address of 16 bits sample (it is even)
	moveq	#3,r8
	move	r14,r7
	and	r12,r8		; address & 3
	and	r12,r7		; address & ~3
	shlq	#3,r8		; 8 * (address & 3)
	cmp	r6,r7
	subqt	#16,r8		; 8 * (address & 3) - 8 * 2
	jr	eq,.no_reload_16_bits
	neg	r8		; 8 * 2 - 8 * (address & 3)
	load	(r7),r9		; prefetch two samples at (address & 3) [A2;A1;B2;B1]
	move	r7,r6
.no_reload_16_bits:
	add	r26,r21		; add fractionnal part to fractionnal increment
	move	r9,r12
	addc	r23,r17		; add integer part with carry to current pointer
	ror	r8,r12
	load	(r4),r10	; read left voice
	move	r12,r13
	load	(r5),r11	; read right voice
	imult	r24,r12
	imult	r25,r13
	add	r12,r10
	add	r13,r11
	store	r10,(r4)
	addqt	#8,r4
	store	r11,(r5)
	cmp	r4,r2		; have we finished?
	jump	ne,(r27)	; => .generate_voice
	addqt	#8,r5
	jump	(r28)		; => .generate_end (interrupt may change to .next_voice)
	nop
.generate_end:
	neg	r22		       ; negate flag (0 = 8 bits, -1 = 16 bits)
	store	r21,(r15+VOICE_FRAC/4) ; save fractionnal increment
	sh	r22,r17		       ; convert in bytes
	sh	r22,r18		       ; convert in bytes
	store	r17,(r15+VOICE_CURRENT/4) ; save current pointer
	store	r18,(r15+VOICE_END/4)	  ; save end pointer
.next_voice:
	subq	#1,r3			; one voice less to do
	jump	ne,(r29)		; => .do_voice
	addqt	#VOICE_SIZEOF,r15 ; next voice
	;;
	.if	DSP_BG
	movei	#BG,r29
	moveq	#0,r28
	jump	(r30)		; return to main loop
	storew	r28,(r29)
	.else
	jump	(r30)
	nop
	.endif
	.long
.dsp_sound_driver_init:
	;;
SOUND_DRIVER_FRQ	equ	0
SOUND_DRIVER_BUFSIZE	equ	4
SOUND_DRIVER_LOCK	equ	8
	;; assume run from bank 1
	movei	#DSP_ISP+(DSP_STACK_SIZE*4),r31	; init isp
	moveta	r31,r31		; ISP (bank 0)
	movei	#DSP_USP+(DSP_STACK_SIZE*4),r31	; init usp
	;; set I2S
	movei	#SCLK,r10
	movei	#SMODE,r11
	movei	#.dsp_sound_driver_param,r14
	movei	#%001101,r13	; SMODE (Zerosquare fix)
	load	(r14+SOUND_DRIVER_FRQ/4),r12	; SCLK
	store	r12,(r10)
	store	r13,(r11)
	;;
	load	(r14+SOUND_DRIVER_BUFSIZE/4),r13 ; number of samples (might be odd)
	movei	#.dsp_sound_buffer,r10		; first half of audio buffer
	move	r13,r12
	shrq	#1,r13				; half of samples
	move	r10,r11
	shlq	#3,r13				; a sample is 8 bytes
	shlq	#3,r12
	add	r13,r11				; second half of audio buffer
	add	r10,r12				; end of audio buffer
	;; initialise registers of I2S interrupt
	moveta	r10,r0				; start of first half (buffer played)
	moveta	r11,r1				; end of first half (buffer played)
	moveta	r11,r2				; start of other half (buffer generated)
	moveta	r12,r3				; end of other half (buffer generated)
	moveta	r10,r14				; current point in buffer played
	movei	#L_I2S,r13
	moveta	r13,r15
	;; and registers of CPU interrupt
	movei	#SOUND_DMA,r13
	moveta	r13,r16		; SOUND_DMA
	addqt	#DMA_SIZEOF,r13
	moveta	r13,r17		; SOUND_VOICES
	moveq	#0,r13
	moveta	r13,r18		; DMA_STATE
	;; enable interrupts
	movei	#D_FLAGS,r28
	movei	#D_CPUENA|D_I2SENA|REGPAGE,r29
	;; go to driver
	moveq	#0,r1
	movei	#.dsp_sound_driver_main,r0
	store	r1,(r14+SOUND_DRIVER_LOCK/4)	; clear LOCK
	jump	(r0)				; jump to main loop
	store	r29,(r28)
	.long
.dsp_sound_driver_param:
	dc.l	0		; frequency
	dc.l	0		; buffer size (number of samples)
	dc.l	0		; lock
	.long
.dsp_sound_buffer:
	.rept	MAX_BUFSIZE
	dc.l	0
	dc.l	0
	.endr
.dsp_sound_driver_end:

SOUND_DRIVER_INIT	equ	.dsp_sound_driver_init
SOUND_DRIVER_PARAM	equ	.dsp_sound_driver_param
SOUND_DRIVER_SIZE	equ	.dsp_sound_driver_end-.dsp_sound_driver_begin

	.if	(SOUND_DRIVER_SIZE+(2*4*DSP_STACK_SIZE)) > (D_ENDRAM-D_RAM)
	.print	"Sound driver too big: ", (SOUND_DRIVER_SIZE+(2*4*DSP_STACK_SIZE)), " bytes (max allowed = ", (D_ENDRAM-D_RAM), " bytes)"
	.fail
	.endif

	.print	"Sound driver code size (DSP): ", SOUND_DRIVER_SIZE

	.68000

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
;	move.l	d0,replay_frequency
	move.l	#83096875,d1
	divu.w	d0,d1
	and.l	#$ffff,d1
	divu.w	#200,d1
	and.l	#$ffff,d1
	subq.l	#1,d1
	move.l	d1,SOUND_DRIVER_PARAM+SOUND_DRIVER_FRQ
	addq.l	#1,d1
	mulu.w	#200,d1
	move.l	#83096875,d0
	divu.w	d1,d0
	and.l	#$ffff,d0
	move.l	d0,replay_frequency
	;; compute size of audio buffer
	move.w	CONFIG,d0
	move.w	#50,d1
	and.w	#VIDTYPE,d0
	beq.s	.ok_frq
	move.w	#60,d1
.ok_frq:
	move.l	replay_frequency,d0
	divu.w	d1,d0
	and.l	#$ffff,d0	; number of samples per vbl
	addq.l	#1,d0
	cmp.l	#MAX_BUFSIZE,d0
	bmi.s	.ok_size
	move.l	#MAX_BUFSIZE,d0
.ok_size:
	move.l	d0,SOUND_DRIVER_PARAM+SOUND_DRIVER_BUFSIZE
	;; set DSP for interrupts
	move.l	#REGPAGE,D_FLAGS
	;; launch the driver
	move.l	#SOUND_DRIVER_PARAM+SOUND_DRIVER_LOCK,a0
	move.l	#$ffffffff,(a0)
	move.l	#SOUND_DRIVER_INIT,D_PC
	move.l	#DSPGO,D_CTRL
	bsr	compute_amiga_frequencies ; does not modify a0
.wait_init:
	tst.l	(a0)
	bne.s	.wait_init
	move.l	replay_frequency,d0
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
	dsp_interrupt
	;;
	move.l	0+8(sp),VOICE_CONTROL(a0)
	move.l	0+12(sp),VOICE_START(a0)
	move.l	0+12+4(sp),VOICE_LENGTH(a0)
	;;
	or.l	#$80000000,d1
	wait_dma	DMA_CONTROL(a1)
	move.l	d1,DMA_CONTROL(a1) ; enable voice
	dsp_interrupt
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
	dsp_interrupt
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
	.long
volume_table:
	dc.b	0, 6, 12, 17, 22, 28, 32, 37
	dc.b	41, 46, 51, 55, 60, 64, 68, 72
	dc.b	77, 81, 85, 89, 93, 97, 101, 105
	dc.b	109, 112, 117, 120, 124, 128, 132, 136
	dc.b	140, 143, 147, 152, 155, 158, 163, 166
	dc.b	169, 173, 176, 180, 184, 187, 191, 195
	dc.b	199, 203, 207, 209, 213, 218, 220, 224
	dc.b	227, 231, 233, 238, 241, 245, 248, 253

	.data
	.even
	dc.b	"Paula Emulator by Seb/The Removers"
	.even

	.bss
	.long
replay_frequency:
	ds.l	1

	.long
_amiga_frequencies:
	ds.w	MAX_PERIOD
	.long


