JAGPATH=$(HOME)/Jaguar
CROSSPATH=/usr/local/m68k-aout/m68k-aout
MADMAC=$(JAGPATH)/bin/mac
CC=$(CROSSPATH)/bin/gcc
AR=$(CROSSPATH)/bin/ar

MACFLAGS=-fb -v -dDISPLAY_LOG_NB_STRIPS=3
CFLAGS=-mc68000 -Wall -fomit-frame-pointer -O2 -msoft-float

SRCC=n_display.c
SRCS=display.s
SRCH=display.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) display_def.s display_cfg.s
INSTALLH=display.h
INSTALLLIB=display.o

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
