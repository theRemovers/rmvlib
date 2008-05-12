; The Removers'Library 
; Copyright (C) 2006-2008 Seb/The Removers
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

	.offset	0
VERTEX_Y:	ds.l	1
VERTEX_X:	ds.l	1
VERTEX_I:	ds.l	1
VERTEX_Z:	ds.l	1
VERTEX_U:	ds.l	1
VERTEX_V:	ds.l	1
VERTEX_SIZEOF:	ds.l	0
	
	.offset	0
POLY_NEXT:	ds.l	1
POLY_FLAGS:	ds.w	1
POLY_SIZE:	ds.w	1
POLY_PARAM:	ds.l	1
POLY_TEXTURE:	ds.l	1
POLY_VERTICES:	ds.l	0

GRDSHADING	equ	0
TXTMAPPING	equ	1
ZBUFFERING	equ	2
