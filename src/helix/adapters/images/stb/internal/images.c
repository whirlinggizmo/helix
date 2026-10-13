#include "images.h"
#include <stdlib.h>
#include <string.h>
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_STDIO
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
#define STBI_ONLY_BMP
#define STBI_ONLY_TGA
#define STBI_ONLY_GIF
#define STBI_FAILURE_USERMSG
#include "stb_image.h"

/* stb_image keeps its failure reason per thread (STBI_THREAD_LOCAL under C11), so decodes may run on several threads at once. */
typedef struct {
    int width, height;
    unsigned char *pixels;
} hy_image;

void *hy_image_decode(const void *data, int size)
{
    int width, height, channels;
    unsigned char *pixels = stbi_load_from_memory((const stbi_uc *)data, size, &width, &height, &channels, 4);
    if (!pixels) return NULL;
    hy_image *image = malloc(sizeof *image);
    if (!image) { stbi_image_free(pixels); return NULL; }
    image->width = width;
    image->height = height;
    image->pixels = pixels;
    return image;
}

int hy_image_width(const void *image) { return ((const hy_image *)image)->width; }
int hy_image_height(const void *image) { return ((const hy_image *)image)->height; }
void hy_image_copy(const void *image, void *dest)
{
    const hy_image *i = image;
    memcpy(dest, i->pixels, (size_t)i->width * (size_t)i->height * 4);
}
void hy_image_free(void *image)
{
    if (!image) return;
    stbi_image_free(((hy_image *)image)->pixels);
    free(image);
}
const char *hy_image_error(void) { const char *reason = stbi_failure_reason(); return reason ? reason : "unknown"; }
