include ../Makefile.config

INCL+=-I../include
MACFLAGS+=-i../include

SRCC=
SRCS=sound.s paula.s protracker.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) pt-play.s paula_def.s
INSTALLLIB=sound.o paula.o protracker.o

include ../Makefile.template
