include ../Makefile.config

SRCC=
SRCS=render.s
SRCH=render.h
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) render_def.s
INSTALLH=render.h
INSTALLLIB=render.o

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
