/* The Removers'Library */
/* Copyright (C) 2006 Seb/The Removers */
/* http://removers.atari.org/ */

/* This library is free software; you can redistribute it and/or */
/* modify it under the terms of the GNU Lesser General Public */
/* License as published by the Free Software Foundation; either */
/* version 2.1 of the License, or (at your option) any later version. */

/* This library is distributed in the hope that it will be useful, */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU */
/* Lesser General Public License for more details. */

/* You should have received a copy of the GNU Lesser General Public */
/* License along with this library; if not, write to the Free Software */
/* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA */

/** \file sound.h
 * \brief Sound driver.
 */
#ifndef _SOUND_H
#define _SOUND_H

#ifdef __cplusplus
extern "C" {
#endif

/** Initialises the display driver and the DSP subroutine manager. It
    returns back the real replay frequency. */
int init_sound_driver(/** desired replay frequency */ 
		      int frequency);

/** 16 bits sound */
#define VOICE_16 (1<<31)

/** Balance [0..16] */
#define VOICE_BALANCE(r) (r << 24)

/** Volume [0..64] */
#define VOICE_VOLUME(v) (v << 16)

/** Frequency increment [0..0xffff] */
#define VOICE_FREQ(replay_freq,freq) (((freq * 4096) / replay_freq) & 0xffff)

/** Play a sample */
void set_voice(/** voice */
	       int voice_num, 
	       /** voice control (i.e. 8/16 bits, panning, volume, frequency) */
	       int control, 
	       /** start of sample */
	       char *start, 
	       /** length in bytes */
	       int len, 
	       /** re-start address of sample (or NULL if no re-play) */
	       char *loop_start, 
	       /** lenght in bytes of the loop */
	       int loop_len);

/** Set voice panning */
void set_panning(/** voice */
		 int voice_num,
		 /** panning */
		 int panning);

/** Set voice volume */
void set_volume(/** voice */
		int voice_num,
		/** volume */
		int volume);

/** Clear the given voice */
void clear_voice(/** voice */
		 int voice_num);

/** Initialise the Protracker player. The length in bytes of the
    module is not checked and is thus assumed correct. For safety
    reasons, you should add a buffer of 31*2 bytes at the end of the
    module since some values are fixed in the module by this
    function. It returns the number of voices of the music. */
int init_module(/** address of the music */
		char *module,
		/** enable/disable tempo commands */
		/** enable/disable replay */
		int flags);

/** Protracker routine to be called each VBL (50 or 60 Hz) */
void play_module();

/** Clear the module */
void clear_module();

/** Play/Pause the replay of the current music */
void pause_module();

/** Set specific postiont to start playback from. */
void set_song_position(/** Position in song to play */
			 int position);

/** Set modules voices mask. It returns the mask set. */
int enable_module_voices(/** Mask to enable/disable voice of a
			     module. Bit 0 = Voice 0, Bit 1 = Voice 1,
			     ... */
			 int mask);

/** Call a DSP subroutine in DSP ram. */
void jump_dsp_subroutine(/** Address of the subroutine */
			 void *addr);

/** Free DSP ram is available at &_DSP_FREE_RAM. */
extern long _DSP_FREE_RAM;

#define MAX_PERIOD 1024

/** Amiga period to frequencies increment. Initialised by
    ::init_sound_driver since it depends on the replay frequency. */
extern short int amiga_frequencies[MAX_PERIOD];

#ifdef __cplusplus
}
#endif

#endif
