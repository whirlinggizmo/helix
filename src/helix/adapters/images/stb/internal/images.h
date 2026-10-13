#ifndef HELIX_IMAGES_H
#define HELIX_IMAGES_H
#ifdef __cplusplus
extern "C" {
#endif
/* An image decoded by stb_image to 8-bit RGBA, rows top to bottom; NULL when it couldn't be (hy_image_error says why, on this thread). */
void *hy_image_decode(const void *data, int size);
int hy_image_width(const void *image);
int hy_image_height(const void *image);
/* Copies the pixels (width * height * 4 bytes) into dest. */
void hy_image_copy(const void *image, void *dest);
void hy_image_free(void *image);
const char *hy_image_error(void);
#ifdef __cplusplus
}
#endif
#endif
