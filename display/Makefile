include ../Makefile.config

INCL+=-I../include

MACFLAGS:=$(MACFLAGS) -dDISPLAY_LOG_NB_STRIPS=3 -i../include

SRCC=n_display.c
SRCS=display.s
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)

DISTFILES=Makefile $(SRCC) $(SRCH) $(SRCS) display_cfg.s
INSTALLLIB=display.o

include ../Makefile.template
