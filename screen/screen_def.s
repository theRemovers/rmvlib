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

	.if	^^defined	__SCREEN_H
	.print	"screen_def.s already included"
	end
	.endif
__SCREEN_H	equ	1
	
.macro  wait_blitter
.wait_\~:
	move.l  B_CMD,\1
	btst    #0,\1
	beq.s   .wait_\~
.endm
	
	.offset	0
SCREEN_FLAGS:	ds.l	1
SCREEN_H:	ds.w	1
SCREEN_W:	ds.w	1
SCREEN_Y:	ds.w	1
SCREEN_X:	ds.w	1
SCREEN_IWIDTH:	ds.w	1
SCREEN_DWIDTH:	ds.w	1
SCREEN_DATA:	ds.l	1
SCREEN_CLUT_TYPE:	ds.b	1
SCREEN_CLUT_INDEX:	ds.b	1
SCREEN_CLUT_SIZE:	ds.w	1
SCREEN_CLUT:	ds.l	1

	.text

