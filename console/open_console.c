#include <stdlib.h>
#include <console.h>

// CONSOLE_WIDTH should be a multiple of 8
#define DFLT_CONSOLE_WIDTH 40
#define DFLT_CONSOLE_HEIGHT 25
#define DFLT_CONSOLE_LAYER 0

FILE *open_console(display *d, int x, int y, int idx) {
  return open_custom_console(d,x,y,idx,DFLT_CONSOLE_WIDTH,DFLT_CONSOLE_HEIGHT,DFLT_CONSOLE_LAYER);
}
