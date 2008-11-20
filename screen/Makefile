include ../Makefile.config

SRCC=a_1_buf.c a_2_buf.c a_z_buf.c n_screen.c s_1_buf.c scr2spr.c
SRCS=cl_screen.s cl_z_screen.s p_pixel.s p_pixels.s hline.s vline.s
SRCH=screen.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH) screen_def.s screen_inline.c
INSTALLH=screen.h
INSTALLLIB=

all: .depend $(OBJS) 

%.o: %.s
	$(MADMAC) $(MACFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *~ $(OBJS) .depend

dist-files:
	@echo $(DISTFILES)

install-h:
	@echo $(INSTALLH)

install-lib:
	@echo $(INSTALLLIB)

.depend: $(SRCC)
	$(CC) -MM $(SRCC) > .depend

-include .depend
