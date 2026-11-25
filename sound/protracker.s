	;; the following disable clear_dma commands in the mod replayer
PAULA	equ	1

	include	"jaguar.inc"
	
	include	"paula_def.s"

	.text

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

