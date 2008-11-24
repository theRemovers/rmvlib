#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

#define SKUNK_WRITE_STDERR 1

typedef struct {
  unsigned short int length;
  short int kind;
} SkunkMessageHeader;

typedef struct {
  unsigned short int length;
  short int kind;
  char content[];
} SkunkMessage;

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);

#endif
