include Makefile.config

SRCS=
SRCC=
SRCH=
OBJS=$(SRCC:.c=.o) $(SRCS:.s=.o)
NASUBDIRS=interrupt display collision fb2d sound render
ASUBDIRS=sprite screen joypad blit console skunkboard 
OSUBDIRS=doc
SUBDIRS=$(NASUBDIRS) $(ASUBDIRS) $(OSUBDIRS)

PROJECT=rmvlib
# also change in Doxyfile!!!
PROJECT_NUMBER=1.3.5

export PROJECT_NUMBER

PROJECT_NAME=$(PROJECT)-$(PROJECT_NUMBER)

DISTFILES=Makefile Makefile.config
DISTFILES+=main.h jaguar.inc routine.s risc.s
DISTFILES+=ChangeLog LICENSE build.sh 

INSTALLH=
INSTALLLIB=$(PROJECT).a

all: subdirs $(OBJS) $(PROJECT).a

$(PROJECT).a: Makefile subdirs $(OBJS)
	for dir in $(ASUBDIRS); do $(AR) rvs $(PROJECT).a $$dir/*.o; done
	$(AR) rvs $(PROJECT).a display/n_display.o

.PHONY: subdirs $(SUBDIRS) all clean dist list-headers list-objects install

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
	mkdir -p $(PROJECT_NAME); \
	cp $(DISTFILES) $(PROJECT_NAME); \
	for dir in $(SUBDIRS); do \
	  for file in `$(MAKE) -s dist-files -C $$dir`; do \
	    mkdir -p "$(PROJECT_NAME)/$$dir"; \
	    cp "$$dir/$$file" "$(PROJECT_NAME)/$$dir"; \
	  done; \
	done; \
	tar cfvz $(PROJECT_NAME).tar.gz $(PROJECT_NAME); \
	rm -rf $(PROJECT_NAME)

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
