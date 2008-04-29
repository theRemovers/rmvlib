JAGPATH=$(HOME)/Jaguar
CROSSPATH=/usr/local/m68k-aout/m68k-aout
MADMAC=$(JAGPATH)/bin/mac
CC=$(CROSSPATH)/bin/gcc
AR=$(CROSSPATH)/bin/ar

MACFLAGS=-fb -v
CFLAGS=-mc68000 -Wall -fomit-frame-pointer -O2 -msoft-float 

SRCC=
SRCC+=
SRCC+=
SRCS=joypad.s
SRCH=joypad.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH)
INSTALLH=joypad.h
INSTALLLIB=

# all: .depend $(OBJS)
all: $(OBJS)

%.o: %.s
	$(MADMAC) $(MACFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

dist-files:
	@echo $(DISTFILES)

install-h:
	@echo $(INSTALLH)

install-lib:
	@echo $(INSTALLLIB)

clean:
	rm -f *~ $(OBJS) .depend

# .depend: $(SRCC)
# 	$(CC) -MM $(SRCC) > .depend

# -include .depend
