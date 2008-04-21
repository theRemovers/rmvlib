/* \file main.h
 */

/*! \mainpage The Removers Library Documentation
*
* \section intro_sec Introduction
*
* The library is intended to help programmers to write cool games
* for the <a href="http://en.wikipedia.org/wiki/Atari_Jaguar">Atari
* Jaguar</a>.
*
* Actually, the library is quite different from the first version
* we released in June 2006. The only common point is that the author
* of this library is Seb/The Removers.
*
* Indeed, I have worked hard to give a nice C interface to my
* library. Thus, it should now be easy to interface your own code
* (written in ASM or C) with my library. I will get into details of
* interfacing below.
*
* \section philo_sec General philosophy
*
* The library is essentially devoted to graphics operation. With it,
* you will be able to manipulate easily the OP sprites but you will
* also be able to do some nice effects with the blitter (this last
* part is still work in progress). You will also be able to easily
* manage the 8 joypads. On the sound side, I have adapted a ProTracker
* replay routine that is able to play modules up to 8 voices.  It also
* allows to play samples simulteanously.
*
* I will now go quickly through * the library to introduce it to you.
*
* \subsection display_subsec Display, GPU & sprite manager
* 
* The core of the library is composed of display.h and sprite.h. 
*
* The ::display structure is an essential component of the library. A
* ::display is a ::sprite container which is organized in layer. The
* maximal number of layers is 16. The layer are displayed on screen in
* ascending order so that layer 0 corresponds to the background and
* layer 15 corresponds to the foreground. A display have coordinates
* on screens (display::x and display::y). At most one ::display may be
* viewed at a time.
* 
* You can put ::sprite in a ::display at the layer you wish.  The
* ::sprite structure is a convenient way to manipulate OP sprites. A
* ::sprite can have arbitrary coordinates (sprite::x and sprite::y)
* relative to the ::display they belong to.
*
* The sprite can be unscaled or scaled (sprite::scaled), visible or
* not (sprite::visible), animated or not (sprite::animated). They may
* have a "hot spot" different from the left upper corner
* (sprite::use_hotspot, sprite::hx and sprite::hy). An animated sprite
* is described by a simple array of ::animation_chunk.
*
* All the tedious details of the sprites are managed by the display
* manager. The display manager uses a GPU routine for maximal
* performance. It includes also a simple yet practical GPU subroutine
* manager. The display manager should be initialised before use by
* calling the function ::init_display_driver. You can then create a
* ::display with the function ::new_display. You can then fill the
* freshly created display with sprites with
* ::attach_sprite_to_display_at_layer. To show the display, you then
* simply have to call ::show_display. It is also possible to remove
* easily a sprite from a display with ::detach_sprite_from_display,
* change the layer of a sprite in a display with
* ::change_sprite_layer. You can even sort a layer of a display with
* ::sort_display_layer so that you control the order of display in a
* same layer.
*
* \subsection coll_subsec Pixel precise collision
* 
* One common thing when you manipulate sprites is to check if two
* sprites collides. The file collision.h provides you this
* functionnality. This collision routine has some limitations but this
* should not be too annoying. Indeed, it only manages unscaled
* ::sprite that are not horizontally flipped and whose sprite::depth
* is ::DEPTH16. However, the sprites can be animated or not and use a
* hot spot or not.
*
* To use the collision routine, you have first to use the display
* manager. Then, you have to initialise this routine with the function
* ::init_collision_routine. This last function copies the GPU
* subroutine in GPU ram at the address you give (for example
* &::_GPU_FREE_RAM).  You can then launch a collision test with
* ::launch_collision_routine and asynchrounously get the result of the
* test with ::get_collision_result. The collision routine not only
* determines if the two transparent ::sprite collide but also if their
* bounding box intersect.
*
* \subsection fb2d_subsec Frame Buffers
*
* The file screen.h provides several facilities to allocate frame
* buffers (either simple buffer with ::alloc_simple_screen, or double
* buffered with ::alloc_double_buffered_screens, or double buffered
* with Z buffer with ::alloc_z_double_buffered_screens). A ::screen is
* a structure that allows you to consider a part of memory as a frame
* buffer. You can display a screen by building a corresponding
* ::sprite with ::sprite_of_screen and then add it to the current
* display with ::attach_sprite_to_display_at_layer.
*
* To manipulate the frame buffers, some 2D operations are implemented
* in fb2d.h.  The 2D frame buffer manager is still ongoing work. With
* this manager, you can copy a rectangular area of a screen into
* another screen with the desired copy ::mode. This is done achieved
* with the function ::fb2d_copy_straight. You can also apply an
* ::affine_transform while doing a transformed copy with
* ::fb2d_copy_transformed. Thus, you can easily rotate a part of a
* screen by setting a rotation (with ::fb2d_set_rotation) as the
* considered affine transform. You can also compose transformation
* with ::fb2d_compose_linear_transform. It is easy to make a point
* match in the source screen and the target screen with the function
* ::fb2d_set_matching_point.
*
* Before using all these functionnalities, you should first initialise
* the display manager and then the 2D frame buffer manager with
* ::init_fb2d_manager. Similarly to the collision routine, it takes the
* address in DSP ram where the DSP subroutine should be copied.
*
* Note that now there is a sound manager implemented (with v 1.1 of
* the library), the fb2d manager has moved to DSP ram.
*
* \subsection joy_subsec Joypad management
*
* The library offer you in joypad.h a simple function to read the 8
* joypad states. You simply have to call the function
* ::read_joypad_state and this will update the ::joypad_state structure
* given.
*
* \subsection inter_subsec Interrupts
*
* Let me say a few words about the interrupt manager (of file
* interrupt.h) despite this part is still under ongoing work. For the
* moment, you can just initialise interrupts with ::init_interrupts.
* This installs a generic interrupt manager that allows you to put
* several ::irq_handler to be run at each VBL. You simply have to put
* the address of the handler in the ::VblQueue array. You can also
* then wait for the next VBL to occur with ::vsync.
*
* \subsection modplay_subsec Sound manager
*
* The major improvement of version 1.1 of the library is the sound
* driver which implements functions described in sound.h. It offers
* you an 8 voices mixer which can play either 8 bits or 16 bits (big
* endian, signed) samples. Each voice can have its own volume,
* balance, frequency and quality. In addition, I have also worked on a
* Protracker replay routine that I have taken from the Amiga world and
* adapted so that it uses the above described mixer (which in spirit
* works like Paula) and optimised; it should be able to replay every
* 4/6/8 channels amiga module without any problem.
*
* Note finally that it is now easy to share the DSP between several
* tasks.
* 
* \subsection console_subsec Console
*
* Another improvement of version 1.1 is the addition of the console
* (see console.h).
*
* \section inter_sec Interfacing your own program with the library
* 
* First you have to know that almost all the functions of my library
* requires that the structures given as arguments should be aligned at
* least on a long word (32 bits) boundary. The graphical data must
* even be aligned on a phrase (64 bits) boundary.
*
* Then you also have to know that some part of my library assumes that
* you use the jlibc (Jaguar C library) I have also written.
*
* If you are using a C compiler to generate 68k code like gcc, it
* should be really easy. The only thing you need to know is that the
* type int stands for 32 bits integers. Thus, every parameter that is
* pushed on the stack when calling a function is 32 bits long.
*
* If you are using 68k ASM code, then the additionnal thing you need to
* know is that all registers but d0/d1/a0/a1 are preserved by function
* calls.
*
* \section Installation
*
* The easiest way to install this library is to get your hands on a
* binary distribution of it. Then copy the header files in a directory
* where your C compiler will look after (include directory) and the
* objects and archive files in a directory where your linker will look
* after (lib directory).
*
* Provided that your compilation environment is correctly set up, you
* can also alternatively build the library with the 'make' command and
* then install it where you want with the 'make install' command. You
* might have to change the TARGET variable of the Makefile to indicate
* where you want all the files to be copied.
*
* \section license_sec License
*
* The following license applies to every file of the distribution
* except the file jaguar.inc.
*
* Copyright (C) 2006 Seb/The Removers
* http://removers.atari.org/
*
* This library is free software; you can redistribute it and/or 
* modify it under the terms of the GNU Lesser General Public 
* License as published by the Free Software Foundation; either 
* version 2.1 of the License, or (at your option) any later version. 
*
* This library is distributed in the hope that it will be useful, 
* but WITHOUT ANY WARRANTY; without even the implied warranty of 
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
* Lesser General Public License for more details. 
*
* You should have received a copy of the GNU Lesser General Public 
* License along with this library; if not, write to the Free Software 
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA 
*
* \section greet_sec Greetings
*
* I would like to send some greetings to the Jagware Team (especially
* to Azrael, Fredifredo, GT Turbo, Mariaud, MetalKnuckles, Orion_,
* SCPCD, Zerosquare), Patrice Mandin, Fadest, Pocket, Odie One, Rajah
* Lone, Arethius, Vince, Mathias Domin, TNG (Symmetry & Mr Spock),
* Starcat, Nick Harlow, Songbird, Jaysmith 2000 and of course to my
* good friend Stabylo.
*/

