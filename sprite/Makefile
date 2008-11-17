# JAGPATH=$(HOME)/Jaguar
# CROSSPATH=/usr/local/m68k-aout/m68k-aout
MADMAC=$(JAGPATH)/bin/mac
CC=$(CROSSPATH)/bin/gcc
AR=$(CROSSPATH)/bin/ar

MACFLAGS=-fb -v 
CFLAGS=-mc68000 -Wall -fomit-frame-pointer -O2 -msoft-float 

SRCC=a_sprite.c c_layer.c d_sprite.c iter_all.c iter_one.c 
SRCC+=n_sprite.c s_sprite.c so_layer.c 
SRCC+=m_layer.c h_layer.c s_layer.c
SRCS=
SRCH=sprite.h op.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH)

INSTALLH=sprite.h op.h
INSTALLLIB=

all: .depend $(OBJS) 

%.o: %.s
	$(MADMAC) $(MACFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *~ $(OBJS) .depend

.depend: $(SRCC)
	$(CC) -MM $(SRCC) > .depend

dist-files:
	@echo $(DISTFILES)

install-h:
	@echo $(INSTALLH)

install-lib:
	@echo $(INSTALLLIB)

-include .depend
