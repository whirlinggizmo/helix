#ifndef HELIX_SURFACE_H
#define HELIX_SURFACE_H
/* The drawing surface a native host gives the GL graphics adapter: the window's framebuffer, framebuffer 0 of the GL context the host made
   current, in RGBA8 with a depth buffer (24 bits, and 8 of stencil). Each native host implements these (sokol_app's or SDL's), so the GL graphics
   adapter draws in either. */
#ifdef __cplusplus
extern "C" {
#endif
/** The framebuffer's width in pixels. */
int helix_surface_width(void);
/** The framebuffer's height in pixels. */
int helix_surface_height(void);
/** The samples a pixel the window asked for (1 without multisampling): what pipelines drawing to the screen are made for. */
int helix_surface_samples(void);
#ifdef __cplusplus
}
#endif
#endif
