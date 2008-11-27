#include <stdio.h>
#include <string.h>
#include <skunk.h>
#include <stdlib.h>

#define TRUE 1
#define FALSE 0

typedef struct {
  int fd;
  SkunkMessage request;
  SkunkMessage reply;
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
  wrapper->request.length = 0;
  wrapper->request.abstract = SKUNK_FEOF;
  wrapper->request.content = wrapper->buf;
  putInt16(&(wrapper->request), wrapper->fd);
  wrapper->reply.content = wrapper->buf; // not really needed but just to be sure
  skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
  return wrapper->reply.abstract;
}

static int flush(FILE *fp) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->request.length = 0;
  wrapper->request.abstract = SKUNK_FFLUSH;
  wrapper->request.content = wrapper->buf;
  putInt16(&(wrapper->request), wrapper->fd);
  wrapper->reply.content = wrapper->buf; // not really needed but just to be sure
  skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
  return wrapper->reply.abstract;
}

static int close(FILE *fp) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return EOF;
  }
  wrapper->request.length = 0;
  wrapper->request.abstract = SKUNK_FCLOSE;
  wrapper->request.content = wrapper->buf;
  putInt16(&(wrapper->request), wrapper->fd);
  wrapper->reply.content = wrapper->buf; // not really needed but just to be sure
  skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
  int res = wrapper->reply.abstract;
  free(wrapper);
  fp->data = NULL;
  return res;
}

static int read(FILE *fp, void *ptr, size_t size, size_t nmemb) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return 0;
  }
  int total = size*nmemb;
  int maxlen = SKUNKMSGLENMAX;
  while(total > 0) {
    int nbbytes = (total<=maxlen)?total:maxlen;
    wrapper->request.length = 0;
    wrapper->request.abstract = SKUNK_FREAD;
    wrapper->request.content = wrapper->buf;
    putInt32(&(wrapper->request), 1);              // size = 1 byte
    putInt32(&(wrapper->request), nbbytes);        // nmemb = nbbytes
    putInt16(&(wrapper->request), wrapper->fd);
    wrapper->reply.content = ptr; 
    skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
    int got = wrapper->reply.abstract;
    ptr += got;
    total -= got;
    if(got < nbbytes) {
      break;
    }
  }
  return (nmemb - (total+size-1)/size);
}

static int write(FILE *fp, const void *ptr, size_t size, size_t nmemb) {
  SkunkWrapper *wrapper = fp->data;
  if(wrapper == NULL) {
    return 0;
  }
  int total = size*nmemb;
  int maxlen = SKUNKMSGLENMAX-10;
  while(total > 0) {
    int nbbytes = (total<=maxlen)?total:maxlen;
    wrapper->request.length = 0;
    wrapper->request.abstract = SKUNK_FWRITE;
    wrapper->request.content = wrapper->buf;
    putInt32(&(wrapper->request), 1);                // size = 1 byte
    putInt32(&(wrapper->request), nbbytes);          // nmemb = nbbytes
    putInt16(&(wrapper->request), wrapper->fd);
    memcpy(wrapper->buf + 10, ptr, nbbytes);
    wrapper->request.length += nbbytes;
    wrapper->reply.content = wrapper->buf; // not really needed but just to be sure
    skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
    int wrote = wrapper->reply.abstract;
    ptr += wrote;
    total -= wrote;
    if(wrote < nbbytes) {
      break;
    }
  }
  return (nmemb - (total+size-1)/size);
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
  wrapper->request.length = 0;
  wrapper->request.abstract = SKUNK_FPUTC;
  wrapper->request.content = wrapper->buf;
  putInt16(&(wrapper->request), c);
  putInt16(&(wrapper->request), wrapper->fd);
  wrapper->reply.content = wrapper->buf; // not really needed but just to be sure
  skunk_synchronous_request(&(wrapper->request), &(wrapper->reply));
  return wrapper->reply.abstract;
}

FILE *open_skunk_file(int fd) {
  SkunkWrapper *wrapper = malloc(sizeof(SkunkWrapper));
  wrapper->fd = fd;
  FILE *fp = malloc(sizeof(FILE));
  fp->data = wrapper;
  // input actions
  fp->getc = NULL;
  fp->gets = NULL;
  fp->read = read;
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
