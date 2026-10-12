#ifndef HELIX_HOST_H
#define HELIX_HOST_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void hy_run(void (*init)(void),void (*frame)(float),void (*cleanup)(void));
void hy_quit(void);int hy_width(void);int hy_height(void);float hy_pixel_ratio(void);
#ifdef __cplusplus
}
#endif
#endif
