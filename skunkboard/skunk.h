#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

#define SKUNK_WRITE_STDERR 1
#define SKUNK_READ_STDIN 2

#define SKUNK_FOPEN 3
#define SKUNK_FCLOSE 4
#define SKUNK_FREAD 5
#define SKUNK_FWRITE 6
#define SKUNK_FPUTC 7
#define SKUNK_FEOF 8
#define SKUNK_FFLUSH 9

typedef struct {
  unsigned short int length;
  int abstract;
  char *content;
} SkunkMessage;

#define SKUNKMSGLENMAX (4060-6)

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);
int skunk_synchronous_request(SkunkMessage *request, SkunkMessage *reply);

FILE *open_skunk_file(int fd);

#endif