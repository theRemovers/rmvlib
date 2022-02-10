include Makefile.config

INCL+=-I./include

SRCS=
SRCC=
SRCH=
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)
NASUBDIRS=interrupt display collision fb2d sound render lz77
ASUBDIRS=sprite screen joypad blit console skunkboard
OSUBDIRS=doc
SUBDIRS=$(NASUBDIRS) $(ASUBDIRS) $(OSUBDIRS)

PROJECT=rmvlib
# also change in Doxyfile!!!
PROJECT_NUMBER=1.3.6

export PROJECT_NUMBER

PROJECT_NAME=$(PROJECT)-$(PROJECT_NUMBER)

DISTFILES=Makefile Makefile.config Makefile.template
DISTFILES+=main.h jaguar.inc routine.s risc.s
DISTFILES+=ChangeLog LICENSE

INSTALLLIB=$(PROJECT).a

all: lib

$(PROJECT).a: Makefile subdirs $(OBJS)
	for dir in $(ASUBDIRS); do $(AR) rvs $(PROJECT).a $$dir/*.o; done
	$(AR) rvs $(PROJECT).a display/n_display.o

.PHONY: subdirs $(SUBDIRS) all clean dist list-objects install lib uninstall

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

%.o: %.s
	$(MADMAC) $(MACFLAGS) $<

%.o: %.c
	$(CC) $(CFLAGS) -c $<

lib: subdirs $(OBJS) $(PROJECT).a
	mkdir -p lib; \
	rm -f lib/*; \
	for file in $(INSTALLLIB); do \
	  install -m "u+rw,go+r" "$$file" "lib"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-lib -C $$dir`; do \
	    install -m "u+rw,go+r" "$$dir/$$file" "lib"; \
	  done; \
	done

clean:
	for dir in $(SUBDIRS); do $(MAKE) clean -C $$dir; done
	rm -f *~ $(OBJS) $(PROJECT).a

dist:
	mkdir -p $(PROJECT_NAME); \
	cp $(DISTFILES) $(PROJECT_NAME); \
	for file in include/*.h include/*.inc; do \
	  mkdir -p "$(PROJECT_NAME)/include"; \
	  cp "$$file" "$(PROJECT_NAME)/include"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s dist-files -C $$dir`; do \
	    mkdir -p "$(PROJECT_NAME)/$$dir"; \
	    cp "$$dir/$$file" "$(PROJECT_NAME)/$$dir"; \
	  done; \
	done; \
	tar cfvz $(PROJECT_NAME).tar.gz $(PROJECT_NAME); \
	rm -rf $(PROJECT_NAME)

list-objects:
	for file in $(INSTALLLIB); do \
	  echo "$$file"; \
	done; \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s install-lib -C $$dir`; do \
	    echo "$$dir/$$file"; \
	  done; \
	done

install: lib
	mkdir -p "$(TARGET)/include"; \
	mkdir -p "$(TARGET)/lib"; \
	for file in include/*.h include/*.inc; do \
	  install -m "u+rw,go+r" "$$file" "$(TARGET)/include"; \
	done; \
	for file in lib/*; do \
	  install -m "u+rw,go+r" "$$file" "$(TARGET)/lib"; \
	done

uninstall:
	for file in include/*.h include/*.inc; do \
	  rm -f "$(TARGET)/$$file"; \
	done; \
	for file in lib/*; do \
	  rm -f "$(TARGET)/$$file"; \
	done
