#ifndef HELIX_CODEC_H
#define HELIX_CODEC_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int helix_codec_memory(const void *data,int bytes);
int helix_codec_file(const char *path);double helix_codec_frames(int id);
int helix_codec_arriving(const void *data,int bytes,int length);int helix_codec_arrive(int id,const void *data,int bytes);
int helix_codec_position(int id);
int helix_codec_read(int id,void *destination,int frames);int helix_codec_rewind(int id);
void helix_codec_close(int id);const char *helix_codec_version(void);
#ifdef __cplusplus
}
#endif
#endif
