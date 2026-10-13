/* Bakes a TrueType font's printable ASCII into a signed distance field atlas, for HeliX's built-in text.

   usage: bake <font.ttf> <pixel height> <padding> <atlas width> <out.r8> <out.json>

   Each glyph is rendered by stb_truetype as a distance field at the pixel height, with padding pixels around it; a value
   of 128 is the outline, 255 well inside, 0 well outside, falling 128/padding a pixel. Glyphs are packed in rows, left to
   right. out.r8 holds one byte a texel, row by row; out.json the atlas size and, per glyph, its place in the atlas and its
   placement and advance in pixels at the baked height. */
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FIRST 32
#define LAST 126

typedef struct {
    int x, y, width, height, xoff, yoff;
    float advance;
} glyph_t;

static unsigned char *read_file(const char *path, long *size)
{
    FILE *file = fopen(path, "rb");
    if (!file) return NULL;
    fseek(file, 0, SEEK_END);
    *size = ftell(file);
    fseek(file, 0, SEEK_SET);
    unsigned char *data = malloc((size_t)*size);
    if (data && fread(data, 1, (size_t)*size, file) != (size_t)*size) { free(data); data = NULL; }
    fclose(file);
    return data;
}

int main(int argc, char **argv)
{
    if (argc != 7) {
        fprintf(stderr, "usage: %s <font.ttf> <pixel height> <padding> <atlas width> <out.r8> <out.json>\n", argv[0]);
        return 2;
    }
    const float pixel_height = (float)atof(argv[2]);
    const int padding = atoi(argv[3]), atlas_width = atoi(argv[4]);
    long size = 0;
    unsigned char *ttf = read_file(argv[1], &size);
    stbtt_fontinfo font;
    if (!ttf || !stbtt_InitFont(&font, ttf, stbtt_GetFontOffsetForIndex(ttf, 0))) {
        fprintf(stderr, "cannot read %s\n", argv[1]);
        return 1;
    }
    const float scale = stbtt_ScaleForPixelHeight(&font, pixel_height);
    const unsigned char on_edge = 128;
    const float distance_scale = 128.0f / (float)padding;
    int ascent, descent, line_gap;
    stbtt_GetFontVMetrics(&font, &ascent, &descent, &line_gap);

    /* Render each glyph's field and lay the glyphs out in rows. */
    glyph_t glyphs[LAST - FIRST + 1];
    unsigned char *fields[LAST - FIRST + 1];
    int x = 0, y = 0, row_height = 0;
    for (int c = FIRST; c <= LAST; c++) {
        glyph_t *g = &glyphs[c - FIRST];
        int advance, bearing;
        stbtt_GetCodepointHMetrics(&font, c, &advance, &bearing);
        g->advance = (float)advance * scale;
        fields[c - FIRST] = stbtt_GetCodepointSDF(&font, scale, c, padding, on_edge, distance_scale, &g->width, &g->height, &g->xoff, &g->yoff);
        if (!fields[c - FIRST]) { g->width = g->height = g->xoff = g->yoff = 0; }
        if (x + g->width + 1 > atlas_width) { x = 0; y += row_height + 1; row_height = 0; }
        g->x = x; g->y = y;
        x += g->width + 1;
        if (g->height > row_height) row_height = g->height;
    }
    int atlas_height = 1;
    while (atlas_height < y + row_height) atlas_height *= 2;

    unsigned char *atlas = calloc((size_t)atlas_width * (size_t)atlas_height, 1);
    for (int c = FIRST; c <= LAST; c++) {
        const glyph_t *g = &glyphs[c - FIRST];
        for (int row = 0; row < g->height; row++)
            memcpy(atlas + (size_t)(g->y + row) * (size_t)atlas_width + (size_t)g->x, fields[c - FIRST] + (size_t)row * (size_t)g->width, (size_t)g->width);
        stbtt_FreeSDF(fields[c - FIRST], NULL);
    }
    FILE *raw = fopen(argv[5], "wb");
    if (!raw || fwrite(atlas, 1, (size_t)atlas_width * (size_t)atlas_height, raw) != (size_t)atlas_width * (size_t)atlas_height) return 1;
    fclose(raw);

    FILE *json = fopen(argv[6], "w");
    if (!json) return 1;
    fprintf(json, "{\"pixelHeight\":%g,\"padding\":%d,\"onEdge\":%d,\"width\":%d,\"height\":%d,\"ascent\":%g,\"descent\":%g,\"lineGap\":%g,\"first\":%d,\"glyphs\":[",
            pixel_height, padding, on_edge, atlas_width, atlas_height, ascent * scale, descent * scale, line_gap * scale, FIRST);
    for (int c = FIRST; c <= LAST; c++) {
        const glyph_t *g = &glyphs[c - FIRST];
        fprintf(json, "%s[%d,%d,%d,%d,%d,%d,%g]", c == FIRST ? "" : ",", g->x, g->y, g->width, g->height, g->xoff, g->yoff, g->advance);
    }
    fprintf(json, "]}\n");
    fclose(json);
    free(atlas);
    free(ttf);
    return 0;
}
