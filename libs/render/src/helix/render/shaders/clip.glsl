// helix-render's clip planes: up to 4, each a, b, c and d, a point on the side where a x + b y + c z + d < 0 cut away, and how many are
// set (Batch3D.clipPlanes). helix-render cuts a fragment stage by them itself, where its vertex stage writes worldPosition; a program's
// own stage that reads them includes this, never declaring them itself, so the two are one declaration.
#ifndef HELIX_RENDER_CLIP_GLSL
#define HELIX_RENDER_CLIP_GLSL
uniform vec4 clipPlanes[4];
uniform int clipPlaneCount;
#endif
