#ifndef __SKUNK_H
#define __SKUNK_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SKUNK_WRITE_STDERR 1
#define SKUNK_READ_STDIN 2

#define SKUNK_FOPEN 3
#define SKUNK_FCLOSE 4
#define SKUNK_FREAD 5
#define SKUNK_FWRITE 6
#define SKUNK_FPUTC 7
#define SKUNK_FEOF 8
#define SKUNK_FFLUSH 9
#define SKUNK_FGETS 10
#define SKUNK_FGETC 11
#define SKUNK_FSEEK 12
#define SKUNK_FTELL 13

typedef struct {
  unsigned short int length;
  int abstract;
  char *content;
} SkunkMessage;

#define SKUNKMSGLENMAX (4060-6)

void skunk_init();

int skunk_asynchronous_request(SkunkMessage *request);
int skunk_synchronous_request(SkunkMessage *request, SkunkMessage *reply);

FILE *skunk_stdin();
FILE *skunk_stderr();
FILE *skunk_fopen(const char *path, const char *mode);

#ifdef __cplusplus
}
#endif

#endif
