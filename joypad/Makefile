include ../Makefile.config

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
