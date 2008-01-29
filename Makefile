JAGPATH=$(HOME)/Jaguar
CROSSPATH=/usr/local/m68k-aout/m68k-aout
MADMAC=$(JAGPATH)/bin/mac
CC=$(CROSSPATH)/bin/gcc
AR=$(CROSSPATH)/bin/ar

MACFLAGS=-fb -v
CFLAGS=-mc68000 -Wall -fomit-frame-pointer -O2 -msoft-float 
SRCS=
SRCC=
SRCH=
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)
NASUBDIRS=interrupt display collision fb2d sound
ASUBDIRS=sprite screen joypad blit memalign console
OSUBDIRS=doc
SUBDIRS=$(NASUBDIRS) $(ASUBDIRS) $(OSUBDIRS)

PROJECT=rmvlib
# also change in Doxyfile!!!
PROJECT_NUMBER=1.1.6

TARFILE=$(PROJECT)-$(PROJECT_NUMBER).tar

DISTFILES=Makefile main.h jaguar.inc LICENSE build.sh

INSTALLH=
INSTALLLIB=$(PROJECT).a

TARGET=$(HOME)/tmp/rmvlib

all: subdirs $(OBJS) $(PROJECT).a

$(PROJECT).a: Makefile subdirs $(OBJS)
	for dir in $(ASUBDIRS); do $(AR) rvs $(PROJECT).a $$dir/*.o; done
	$(AR) rvs $(PROJECT).a display/n_display.o

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

%.o: %.s
	$(MADMAC) $(MACFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	for dir in $(SUBDIRS); do $(MAKE) clean -C $$dir; done
	rm -f *~ $(OBJS) $(PROJECT).a

dist:
	tar cfv $(TARFILE) $(DISTFILES); \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s dist-files -C $$dir`; do \
	    tar rfv $(TARFILE) "$$dir/$$file"; \
	  done; \
	done;
	gzip $(TARFILE)

list-headers:
	for file in $(INSTALLH); do \
	  echo "$$file"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-h -C $$dir`; do \
	    echo "$$dir/$$file"; \
	  done; \
	done

list-objects:
	for file in $(INSTALLLIB); do \
	  echo "$$file"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-lib -C $$dir`; do \
	    echo "$$dir/$$file"; \
	  done; \
	done

install:
	mkdir -p "$(TARGET)/include"; \
	mkdir -p "$(TARGET)/lib"; \
	for file in $(INSTALLH); do \
	  install -m "u+rw,go+r" "$$file" "$(TARGET)/include"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-h -C $$dir`; do \
	    install -m "u+rw,go+r" "$$dir/$$file" "$(TARGET)/include"; \
	  done; \
	done; \
	for file in $(INSTALLLIB); do \
	  install -m "u+rw,go+r" "$$file" "$(TARGET)/lib"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-lib -C $$dir`; do \
	    install -m "u+rw,go+r" "$$dir/$$file" "$(TARGET)/lib"; \
	  done; \
	done
