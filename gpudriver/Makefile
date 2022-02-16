include ../Makefile.config

INCL+=-I../include
MACFLAGS+=-i../include

SRCC=
SRCS=gpudriver.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS)
INSTALLLIB=gpudriver.o

include ../Makefile.template
