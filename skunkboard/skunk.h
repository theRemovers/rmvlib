#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

#define SKUNK_WRITE_STDERR 1
#define SKUNK_READ_STDIN 2

typedef struct {
  unsigned short int length;
  short int kind;
} SkunkMessageHeader;

typedef struct {
  SkunkMessageHeader header;
  char content[];
} SkunkMessage;

#define MAX_SKUNK_MSG_LENGTH (4060-sizeof(SkunkMessageHeader))

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);

#endif
