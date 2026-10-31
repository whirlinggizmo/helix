#ifndef HELIX_FONTS_H
#define HELIX_FONTS_H
#ifdef __cplusplus
extern "C" {
#endif
/* A font read by stb_truetype from a copy of its file's bytes; NULL when it can't be. */
void *helix_font_open(const void *data, int size);
/* The font's ascent, descent and line gap at a pixel height, into metrics[0..2]. */
void helix_font_metrics(const void *font, float size, float *metrics);
/* Rasterizes a codepoint at a pixel height, coverage or (sdf) signed distances, into box[0..4]: found, width, height, offset x and y;
   its advance into *advance. The bitmap, width * height bytes, is NULL when it is empty; free it with helix_font_free_bitmap. */
unsigned char *helix_font_glyph(const void *font, float size, int codepoint, int sdf, int *box, float *advance);
void helix_font_copy(const unsigned char *bitmap, int length, void *dest);
void helix_font_free_bitmap(unsigned char *bitmap, int sdf);
void helix_font_close(void *font);
#ifdef __cplusplus
}
#endif
#endif
