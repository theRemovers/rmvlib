#ifndef __SKUNK_H
#define __SKUNK_H

void skunkRESET();

void skunkNOP();

void skunkCONSOLEWRITE(char *buf);

void skunkCONSOLECLOSE();

void skunkCONSOLEREAD(char *buf, int length);

void skunkFILEOPEN(char *filename, int mode);

char *skunkFILEWRITE(char *buf, int length);

int skunkFILEREAD(int length);

void skunkFILECLOSE();

#endif
