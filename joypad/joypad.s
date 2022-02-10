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
		
	;; xxxxxxxxOFCEBDAP369#2580147*RLDU

	;; Standard Controller
JOYPAD_UP	equ	0
JOYPAD_DOWN	equ	1
JOYPAD_LEFT	equ	2
JOYPAD_RIGHT	equ	3
JOYPAD_STAR	equ	4
JOYPAD_7	equ	5
JOYPAD_4	equ	6
JOYPAD_1	equ	7
JOYPAD_0	equ	8
JOYPAD_8	equ	9
JOYPAD_5	equ	10
JOYPAD_2	equ	11
JOYPAD_SHARP	equ	12
JOYPAD_9	equ	13
JOYPAD_6	equ	14
JOYPAD_3	equ	15
JOYPAD_PAUSE	equ	16
JOYPAD_A	equ	17
JOYPAD_D	equ	18
JOYPAD_B	equ	19
JOYPAD_E	equ	20
JOYPAD_C	equ	21
JOYPAD_F	equ	22
JOYPAD_OPTION	equ	23

	;; Pro Controller
JOYPAD_L	equ	JOYPAD_4
JOYPAD_R	equ	JOYPAD_6
JOYPAD_X	equ	JOYPAD_9
JOYPAD_Y	equ	JOYPAD_8
JOYPAD_Z	equ	JOYPAD_7

	.offset	0
	
	;; joypad
	;; le joueur 1 est le premier joy sur le premier team tap
	;; le joueur 2 est le premier joy sur le second team tap
j1_state:	ds.l	1
j3_state:	ds.l	1
j4_state:	ds.l	1
j5_state:	ds.l	1
j2_state:	ds.l	1
j6_state:	ds.l	1
j7_state:	ds.l	1
j8_state:	ds.l	1

	.text
	.68000

	.globl	_read_joypad_state
				
_read_joypad_state:
	move.l	4(sp),a0
	movem.l	d2-d5/a2,-(sp)
	lea	j2_state-j1_state(a0),a1
	move.l	#JOYSTICK,a2
	move.l	#$0f000003,d4	; masque pour le port 1
	move.l	#$f000000c,d5	; masque pour le port 2
	;; lecture joypad 1 et 2
	move.w	#($81 << 8)|(%0111 << 4)|(%1110),(a2) ; (A Pause) + (Right Left Down Up)
	move.l	(a2),d0
	move.l	d0,d1
	and.l	d4,d0		; port 1
	and.l	d5,d1		; port 2
	swap	d0
	ror.w	#8,d0		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	ror.w	#2,d1
	swap	d1
	rol.w	#4,d1		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	move.w	#($81 << 8)|(%1011 << 4)|(%1101),(a2) ; (B D) + (1 4 7 *)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#2,d2
	swap	d2
	ror.w	#4,d2
	or.l	d2,d0		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	swap	d3
	rol.w	#8,d3
	or.l	d3,d1		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	move.w	#($81 << 8)|(%1101 << 4)|(%1011),(a2) ; (C E) + (2 5 8 0)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#4,d2
	swap	d2
	or.l	d2,d0		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	rol.w	#2,d3
	swap	d3
	ror.w	#4,d3
	or.l	d3,d1		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	move.w	#($81 << 8)|(%1110 << 4)|(%0111),(a2) ; (Option F) + (3 6 9 #)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2
	and.l	d5,d3
	rol.w	#6,d2
	swap	d2
	rol.w	#4,d2
	or.l	d2,d0		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	rol.w	#4,d3
	swap	d3
	or.l	d3,d1		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	not.l	d0
	move.l	d0,(a0)+
	not.l	d1
	move.l	d1,(a1)+
	;; lecture joypad 3 et 6
	move.w	#($81 << 8)|(%0000 << 4)|(%0000),(a2) ; (A Pause) + (Right Left Down Up)
	move.l	(a2),d0
	move.l	d0,d1
	and.l	d4,d0		; port 1
	and.l	d5,d1		; port 2
	swap	d0
	ror.w	#8,d0		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	ror.w	#2,d1
	swap	d1
	rol.w	#4,d1		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	move.w	#($81 << 8)|(%1000 << 4)|(%0001),(a2) ; (B D) + (1 4 7 *)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#2,d2
	swap	d2
	ror.w	#4,d2
	or.l	d2,d0		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	swap	d3
	rol.w	#8,d3
	or.l	d3,d1		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	move.w	#($81 << 8)|(%0100 << 4)|(%0010),(a2) ; (C E) + (2 5 8 0)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#4,d2
	swap	d2
	or.l	d2,d0		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	rol.w	#2,d3
	swap	d3
	ror.w	#4,d3
	or.l	d3,d1		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	move.w	#($81 << 8)|(%1100 << 4)|(%0011),(a2) ; (Option F) + (3 6 9 #)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2
	and.l	d5,d3
	rol.w	#6,d2
	swap	d2
	rol.w	#4,d2
	or.l	d2,d0		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	rol.w	#4,d3
	swap	d3
	or.l	d3,d1		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	not.l	d0	
	move.l	d0,(a0)+
	not.l	d1	
	move.l	d1,(a1)+
	;; lecture joypad 4 et 7
	move.w	#($81 << 8)|(%0010 << 4)|(%0100),(a2) ; (A Pause) + (Right Left Down Up)
	move.l	(a2),d0
	move.l	d0,d1
	and.l	d4,d0		; port 1
	and.l	d5,d1		; port 2
	swap	d0
	ror.w	#8,d0		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	ror.w	#2,d1
	swap	d1
	rol.w	#4,d1		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	move.w	#($81 << 8)|(%1010 << 4)|(%0101),(a2) ; (B D) + (1 4 7 *)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#2,d2
	swap	d2
	ror.w	#4,d2
	or.l	d2,d0		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	swap	d3
	rol.w	#8,d3
	or.l	d3,d1		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	move.w	#($81 << 8)|(%0110 << 4)|(%0110),(a2) ; (C E) + (2 5 8 0)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#4,d2
	swap	d2
	or.l	d2,d0		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	rol.w	#2,d3
	swap	d3
	ror.w	#4,d3
	or.l	d3,d1		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	move.w	#($81 << 8)|(%0001 << 4)|(%1000),(a2) ; (Option F) + (3 6 9 #)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2
	and.l	d5,d3
	rol.w	#6,d2
	swap	d2
	rol.w	#4,d2
	or.l	d2,d0		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	rol.w	#4,d3
	swap	d3
	or.l	d3,d1		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	not.l	d0	
	move.l	d0,(a0)+
	not.l	d1
	move.l	d1,(a1)+
	;; lecture joypad 5 et 8
	move.w	#($81 << 8)|(%1001 << 4)|(%1001),(a2) ; (A Pause) + (Right Left Down Up)
	move.l	(a2),d0
	move.l	d0,d1
	and.l	d4,d0		; port 1
	and.l	d5,d1		; port 2
	swap	d0
	ror.w	#8,d0		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	ror.w	#2,d1
	swap	d1
	rol.w	#4,d1		; xxxxxxxxxxxxxxAPxxxxxxxxxxxxRLDU
	move.w	#($81 << 8)|(%0101 << 4)|(%1010),(a2) ; (B D) + (1 4 7 *)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#2,d2
	swap	d2
	ror.w	#4,d2
	or.l	d2,d0		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	swap	d3
	rol.w	#8,d3
	or.l	d3,d1		; xxxxxxxxxxxxBDAPxxxxxxxx147*RLDU
	move.w	#($81 << 8)|(%0011 << 4)|(%1100),(a2) ; (C E) + (2 5 8 0)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2		; port 1
	and.l	d5,d3		; port 2
	rol.w	#4,d2
	swap	d2
	or.l	d2,d0		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	rol.w	#2,d3
	swap	d3
	ror.w	#4,d3
	or.l	d3,d1		; xxxxxxxxxxCEBDAPxxxx2580147*RLDU
	move.w	#($81 << 8)|(%1111 << 4)|(%1111),(a2) ; (Option F) + (3 6 9 #)
	move.l	(a2),d2
	move.l	d2,d3
	and.l	d4,d2
	and.l	d5,d3
	rol.w	#6,d2
	swap	d2
	rol.w	#4,d2
	or.l	d2,d0		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	rol.w	#4,d3
	swap	d3
	or.l	d3,d1		; xxxxxxxxOFCEBDAP369#2580147*RLDU
	not.l	d0
	move.l	d0,(a0)+
	not.l	d1
	move.l	d1,(a1)+
	;; et voila!
	movem.l	(sp)+,d2-d5/a2
	rts

