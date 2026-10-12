#ifndef HELIX_CODEC_H
#define HELIX_CODEC_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int hy_codec_memory(const void *data,int bytes);
int hy_codec_file(const char *path);double hy_codec_frames(int id);
int hy_codec_read(int id,void *destination,int frames);int hy_codec_rewind(int id);
void hy_codec_close(int id);const char *hy_codec_version(void);
#ifdef __cplusplus
}
#endif
#endif
