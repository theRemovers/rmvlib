include ../Makefile.config

SRCC=open_console.c open_custom_console.c
SRCS=
SRCH=console.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH)
INSTALLH=console.h
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
