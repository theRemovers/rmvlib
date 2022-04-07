include ../Makefile.config

INCL+=-I../include
MACFLAGS+=-i../include

SRCC=a_1_buf.c a_2_buf.c a_z_buf.c n_screen.c s_1_buf.c scr2spr.c
SRCS+=cl_screen.s cl_z_screen.s
SRCS+=f_screen.s f_z_screen.s
SRCS+=p_pixel.s p_pixels.s
SRCS+=hline.s vline.s line.s
SRCS+=scr_copy.s scr_rotate.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH) screen_inline.c
INSTALLLIB=

include ../Makefile.template
