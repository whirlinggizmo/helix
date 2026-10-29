#ifndef HELIX_SURFACE_H
#define HELIX_SURFACE_H
/* The drawing surface a native window gives its graphics adapter: the window's framebuffer. For the GL adapter, framebuffer 0 of the GL
   context the window made current, in RGBA8 with a depth buffer (24 bits, and 8 of stencil), shown by helix_surface_present. For SDL_GPU's,
   the SDL3 window, which the adapter claims and presents to. SDL3's shared C (shared/sdl3) implements these. */
#ifdef __cplusplus
extern "C" {
#endif
/** The framebuffer's width in pixels. */
int helix_surface_width(void);
/** The framebuffer's height in pixels. */
int helix_surface_height(void);
/** The samples a pixel the window asked for (1 without multisampling): what pipelines drawing to the screen are made for. */
int helix_surface_samples(void);
/** Shows the GL frame drawn to framebuffer 0 and waits for the display: the window's swap (the GL graphics adapter's present). */
void helix_surface_present(void);
/** The window an adapter that presents for itself claims (the SDL3 host's SDL_Window, made without a GL context for it); only that host
    implements it. */
void *helix_surface_window(void);
#ifdef __cplusplus
}
#endif
#endif
