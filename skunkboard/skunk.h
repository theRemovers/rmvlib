#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

#define SKUNK_WRITE_STDERR 1
#define SKUNK_READ_STDIN 2
#define SKUNK_FOPEN 3

typedef struct {
  unsigned short int length;
  short int kind;
  char *content;
} SkunkMessage;

#define MAX_SKUNK_MSG_LENGTH (4060-4);

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);
int skunk_synchronous_request(SkunkMessage *request, SkunkMessage *reply);

#endif
