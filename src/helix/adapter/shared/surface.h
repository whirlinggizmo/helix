#ifndef HELIX_SURFACE_H
#define HELIX_SURFACE_H
/* The drawing surface a native host gives its graphics adapter: the window's framebuffer. For the GL adapter, framebuffer 0 of the GL context
   the host made current, in RGBA8 with a depth buffer (24 bits, and 8 of stencil); each native host implements these (sokol_app's or SDL's),
   so it draws in either. For SDL_GPU's, the SDL3 host's window, which the adapter claims and presents to. */
#ifdef __cplusplus
extern "C" {
#endif
/** The framebuffer's width in pixels. */
int helix_surface_width(void);
/** The framebuffer's height in pixels. */
int helix_surface_height(void);
/** The samples a pixel the window asked for (1 without multisampling): what pipelines drawing to the screen are made for. */
int helix_surface_samples(void);
/** The window an adapter that presents for itself claims (the SDL3 host's SDL_Window, made without a GL context for it); only that host
    implements it. */
void *helix_surface_window(void);
#ifdef __cplusplus
}
#endif
#endif
