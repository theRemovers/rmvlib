include ../Makefile.config

INCL+=-I../include
MACFLAGS+=-i../include

SRCC=
SRCS=interrupt.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCS) $(SRCH)
INSTALLLIB=interrupt.o

include ../Makefile.template
