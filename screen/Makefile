include ../Makefile.config

INCL+=-I../include

SRCC=a_1_buf.c a_2_buf.c a_z_buf.c n_screen.c s_1_buf.c scr2spr.c
SRCS=cl_screen.s cl_z_screen.s p_pixel.s p_pixels.s hline.s vline.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH) screen_def.s screen_inline.c
INSTALLLIB=

include ../Makefile.template
