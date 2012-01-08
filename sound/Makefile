include ../Makefile.config

SRCC=
SRCS=sound.s paula.s
SRCH=sound.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) pt-play.s 
INSTALLH=sound.h
INSTALLLIB=sound.o paula.o

# all: .depend $(OBJS)
all: $(OBJS)

sound.o: pt-play.s

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


