#ifndef HELIX_CLIPBOARD_SDL3_H
#define HELIX_CLIPBOARD_SDL3_H
#ifdef __cplusplus
extern "C" {
#endif
/* SDL3's clipboard: its text, and an image as PNG, read into C and copied out by size. */
const char*helix_clipboard_text(void);int helix_clipboard_set_text(const char*text);
int helix_clipboard_image_size(void);void helix_clipboard_image_copy(void*out);int helix_clipboard_set_image(const void*png,int size);
void helix_clipboard_dispose(void);
#ifdef __cplusplus
}
#endif
#endif
