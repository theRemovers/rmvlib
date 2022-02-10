#include <stdlib.h>
#include "console.h"

FILE *open_custom_console(display *d, int x, int y, int idx, int width, int height, int layer) {
  sprite *s;
  FILE *fp = new_custom_console(&s, x, y, idx, width, height);
  attach_sprite_to_display_at_layer(s,d,layer);
  return fp;
}
