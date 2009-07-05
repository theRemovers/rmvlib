include ../Makefile.config

SRCC=open_skunk_file.c
SRCS=skunk.s
SRCH=skunk.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) 
INSTALLH=skunk.h 
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


