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

	.if	^^defined	__PAULA_DEF_H
	.print	"paula_def.s already included"
	end
	.endif
__PAULA_DEF_H	equ	1

	.globl	SOUND_DMA
	.globl	SOUND_VOICES

	.globl	_amiga_frequencies
	
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
; STATE (read/written by DSP) is stored in R18 (IT register bank)
; -----
; 00000000 00000000 00000000 OOOOOOOO
; O: voice on/off
	
	.offset	0
DMA_CONTROL:	ds.l	1
DMA_SIZEOF:	ds.l	0

	.text
	
.macro	wait_dma
.wait\~:
	tst.l	\1
	bne.s	.wait\~
.endm

.macro	dsp_interrupt
	move.l	#DSPGO|DSPINT0,D_CTRL ; generate DSP interrupt
.endm

