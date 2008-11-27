#include <stdio.h>
#include <string.h>
#include <skunk.h>
#include <stdlib.h>

#define TRUE 1
#define FALSE 0

typedef struct {
  int fd;
  SkunkMessage msg;
  char buf[SKUNKMSGLENMAX];
} SkunkWrapper;

static void putInt16(SkunkMessage *m, int n) {
  int i = m->length;
  m->content[i++] = (char)((n >> 8) & 0xff);
  m->content[i++] = (char)(n & 0xff);
  m->length = i;
}

static void putInt32(SkunkMessage *m, int n) {
  int i = m->length;
  m->content[i++] = (char)((n >> 24) & 0xff);
  m->content[i++] = (char)((n >> 16) & 0xff);
  m->content[i++] = (char)((n >> 8) & 0xff);
  m->content[i++] = (char)(n & 0xff);
  m->length = i;
}

static void putString(SkunkMessage *m, char *s) {
  int i = m->length;
  strcpy(m->content + i, s);
  m->length += 1+strlen(s);
}

static int eof(FILE *fp) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->msg.length = 0;
  wrapper->msg.abstract = SKUNK_FEOF;
  wrapper->msg.content = wrapper->buf;
  putInt16(&(wrapper->msg), wrapper->fd);
  skunk_synchronous_request(&(wrapper->msg), &(wrapper->msg));
  return wrapper->msg.abstract;
}

static int flush(FILE *fp) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->msg.length = 0;
  wrapper->msg.abstract = SKUNK_FFLUSH;
  wrapper->msg.content = wrapper->buf;
  putInt16(&(wrapper->msg), wrapper->fd);
  skunk_synchronous_request(&(wrapper->msg), &(wrapper->msg));
  return wrapper->msg.abstract;
}

static int close(FILE *fp) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->msg.length = 0;
  wrapper->msg.abstract = SKUNK_FCLOSE;
  wrapper->msg.content = wrapper->buf;
  putInt16(&(wrapper->msg), wrapper->fd);
  skunk_synchronous_request(&(wrapper->msg), &(wrapper->msg));
  int res = wrapper->msg.abstract;
  free(wrapper);
  fp->data = NULL;
  return res;
}

static int write(FILE *fp, const void *ptr, size_t size, size_t nmemb) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return 0;
  }
  int nb = 0;
  int total = size*nmemb;
  int maxlen = SKUNKMSGLENMAX-10;
  while(total > 0) {
    int out = (total<=maxlen)?total:maxlen;
    wrapper->msg.length = 0;
    wrapper->msg.abstract = SKUNK_FWRITE;
    wrapper->msg.content = wrapper->buf;
    putInt32(&(wrapper->msg), 1);
    putInt32(&(wrapper->msg), out);
    putInt16(&(wrapper->msg), wrapper->fd);
    memcpy(wrapper->buf + 10, ptr, out);
    wrapper->msg.length += out;
    skunk_synchronous_request(&(wrapper->msg), &(wrapper->msg));
    int res = wrapper->msg.abstract;
    ptr += res;
    total -= res;
    if(res < out) {
      break;
    }
  }
  return (nb - (total+size-1)/size);
}

static int puts(FILE *fp, const char *s) {
  int n = strlen(s);
  int res = write(fp, s, 1, n);
  return res-n;
}

static int putc(FILE *fp, int c) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->msg.length = 0;
  wrapper->msg.abstract = SKUNK_FPUTC;
  wrapper->msg.content = wrapper->buf;
  putInt16(&(wrapper->msg), c);
  putInt16(&(wrapper->msg), wrapper->fd);
  skunk_synchronous_request(&(wrapper->msg), &(wrapper->msg));
  return wrapper->msg.abstract;
}

FILE *open_skunk_file(int fd) {
  SkunkWrapper *wrapper = malloc(sizeof(SkunkWrapper));
  wrapper->fd = fd;
  FILE *fp = malloc(sizeof(FILE));
  fp->data = wrapper;
  // input actions
  fp->getc = NULL;
  fp->gets = NULL;
  fp->read = NULL;
  // output actions
  fp->putc = putc;
  fp->puts = puts;
  fp->write = write;
  // general purpose actions
  fp->eof = eof;
  fp->flush = flush;
  fp->close = close;
  //
  return fp;
}
