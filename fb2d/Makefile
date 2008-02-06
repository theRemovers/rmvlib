JAGPATH=$(HOME)/Jaguar
CROSSPATH=/usr/local/m68k-aout/m68k-aout
MADMAC=$(JAGPATH)/bin/mac
CC=$(CROSSPATH)/bin/gcc
AR=$(CROSSPATH)/bin/ar

MACFLAGS=-fb -v 
CFLAGS=-mc68000 -Wall -fomit-frame-pointer -O2 -msoft-float 

SRCC=
SRCS=fb2d.s render.s
SRCH=fb2d.h render.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) screen_def.s jaguar.inc
INSTALLH=fb2d.h
INSTALLLIB=fb2d.o

# all: .depend $(OBJS) 
all: $(OBJS) 

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

# .depend: $(SRCC)
# 	$(CC) -MM $(SRCC) > .depend

# -include .depend
