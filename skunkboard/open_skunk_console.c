#include <stdio.h>
#include <string.h>
#include <skunk.h>
#include <stdlib.h>

#define MAXSIZE 4000

#define FALSE 0
#define TRUE 1

typedef struct {
  int i;
  SkunkMessage request;
  char buf[MAXSIZE+2];
} SkunkConsole;

static inline void flush_buffer(SkunkConsole *co) {
  if(co->i > 0) {
    co->buf[co->i] = '\0';
    co->request.length = co->i;
    co->request.abstract = SKUNK_WRITE_STDERR;
    co->request.content = co->buf;
    skunk_asynchronous_request(&(co->request));
/*     skunkCONSOLEWRITE(co->buf); */
/*     skunkNOP(); */
    co->i = 0;
  }
}

static inline void output_char(SkunkConsole *co, char c) {
  co->buf[co->i] = c;
  co->i++;
  if((co->i == MAXSIZE) || (c == '\n')) {
    flush_buffer(co);
  }
}


static inline void output_string(SkunkConsole *co, const char *s) {
  int n = strlen(s);
  while(n > 0) {
    int to_write = n;
    if(to_write > MAXSIZE - co->i) {
      to_write = MAXSIZE - co->i;
    }
    /** copy string */
    int flush = FALSE;
    char *dst = co->buf + co->i;
    int k;
    for(k = 0; k < to_write; k++) {
      char c = *s++;
      if(c == '\n') {
	flush = TRUE;
      }
      *dst++ = c;
    }
    n -= to_write;
    co->i += to_write;
    /** check for flush */
    if((co->i == MAXSIZE) || (flush)) {
      flush_buffer(co);
    }
  }
}

/* static size_t write(FILE *fp, const  void  *ptr,  size_t  size,  size_t  nmemb) { */
/*   SkunkConsole *co = fp->data; */
/*   if(co != NULL) { */
/*     int i; */
/*     char *s = (char *) ptr; */
/*     for(i = 0; i < nmemb * size; i++) { */
/*       output_char(co, *s++); */
/*     } */
/*     return nmemb; */
/*   } */
/*   return 0; */
/* } */

static int putc(FILE *fp, char c) {
  SkunkConsole *co = fp->data;
  if(co != NULL) {
    output_char(co, c);
    return c;
  }
  return EOF;
}

static int puts(FILE *fp, const char *s) {
  SkunkConsole *co = fp->data;
  if(co != NULL) {
    output_string(co, s);
    return 0;
  }
  return EOF;
}

static int eof(FILE *fp) {
  SkunkConsole *co = fp->data;
  return (co == NULL);
}

static int close(FILE *fp) {
  SkunkConsole *co = fp->data;
  if(co != NULL) {
    free(co);
    fp->data = NULL;
    return 0;
  }
  return EOF;
}

static int flush(FILE *fp) {
  SkunkConsole *co = fp->data;
  if(co != NULL) {
    flush_buffer(co);
    return 0;
  }
  return EOF;
}

FILE *open_skunk_console() {
  SkunkConsole *co;
  co = malloc(sizeof(SkunkConsole));
  co->i = 0;
  co->buf[MAXSIZE] = '\0';
  FILE *fp = malloc(sizeof(FILE));
  fp->data = co;
  // no input actions
  fp->getc = NULL;
  fp->gets = NULL;
  fp->read = NULL;
  // output actions
  fp->putc = putc;
  fp->puts = puts;
  fp->write = NULL; // use default implementation
  // general purpose actions
  fp->eof = eof;
  fp->flush = flush;
  fp->close = close;
  return fp;
}
