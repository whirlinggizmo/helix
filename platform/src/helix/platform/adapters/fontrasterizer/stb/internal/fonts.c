#include "fonts.h"
#include <stdlib.h>
#include <string.h>
#define STB_TRUETYPE_IMPLEMENTATION
#define STBTT_STATIC
#include "stb_truetype.h"

/* stb_truetype reads the file where it is, so the font keeps its own copy. Nothing is shared between fonts, so each may be read on its
   own thread. */
typedef struct {
    stbtt_fontinfo info;
    unsigned char *data;
} helix_font;

void *helix_font_open(const void *data, int size)
{
    helix_font *font = malloc(sizeof *font);
    if (!font) return NULL;
    font->data = malloc((size_t)size);
    if (!font->data) { free(font); return NULL; }
    memcpy(font->data, data, (size_t)size);
    if (!stbtt_InitFont(&font->info, font->data, 0)) { free(font->data); free(font); return NULL; }
    return font;
}

void helix_font_metrics(const void *font, float size, float *metrics)
{
    const stbtt_fontinfo *info = &((const helix_font *)font)->info;
    float scale = stbtt_ScaleForPixelHeight(info, size);
    int ascent, descent, gap;
    stbtt_GetFontVMetrics(info, &ascent, &descent, &gap);
    metrics[0] = ascent * scale;
    metrics[1] = descent * scale;
    metrics[2] = gap * scale;
}

unsigned char *helix_font_glyph(const void *font, float size, int codepoint, int sdf, int *box, float *advance)
{
    const stbtt_fontinfo *info = &((const helix_font *)font)->info;
    float scale = stbtt_ScaleForPixelHeight(info, size);
    int width = 0, height = 0, x = 0, y = 0, advanceWidth = 0;
    unsigned char *bitmap = NULL;
    memset(box, 0, 5 * sizeof *box);
    *advance = 0;
    if (stbtt_FindGlyphIndex(info, codepoint) == 0) return NULL;
    /* raylib's settings for signed distances: 4 pixels of padding, 128 on the outline, 64 a pixel. */
    if (sdf) bitmap = stbtt_GetCodepointSDF(info, scale, codepoint, 4, 128, 64.0f, &width, &height, &x, &y);
    else bitmap = stbtt_GetCodepointBitmap(info, scale, scale, codepoint, &width, &height, &x, &y);
    stbtt_GetCodepointHMetrics(info, codepoint, &advanceWidth, NULL);
    box[0] = 1;
    box[1] = bitmap ? width : 0;
    box[2] = bitmap ? height : 0;
    box[3] = x;
    box[4] = y;
    *advance = advanceWidth * scale;
    return bitmap;
}

void helix_font_copy(const unsigned char *bitmap, int length, void *dest) { memcpy(dest, bitmap, (size_t)length); }

void helix_font_free_bitmap(unsigned char *bitmap, int sdf)
{
    if (!bitmap) return;
    if (sdf) stbtt_FreeSDF(bitmap, NULL);
    else stbtt_FreeBitmap(bitmap, NULL);
}

void helix_font_close(void *font)
{
    if (!font) return;
    free(((helix_font *)font)->data);
    free(font);
}
