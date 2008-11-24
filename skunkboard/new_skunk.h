#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

typedef struct {
  unsigned short int length;
  short int kind;
  char content[];
} SkunkMessage;

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);

#endif
