// The C side of a value suite (engines/raylib/parity/README.md): what raylib's own C gives, printed a line at a time, each line led by its case's
// name, as Parity.hx prints helix-raylib's. tools/raylib_parity.py compares the two.
#ifndef PARITY_H
#define PARITY_H
#include "raylib.h"
#include "rlgl.h"
#include <stdbool.h>
#include <stdio.h>

#define V2(x, y) ((Vector2){ (float)(x), (float)(y) })
#define V3(x, y, z) ((Vector3){ (float)(x), (float)(y), (float)(z) })
#define R(x, y, w, h) ((Rectangle){ (float)(x), (float)(y), (float)(w), (float)(h) })

// Whether a drawn vertex's z is printed: 2D vertices carry rlgl's batch depth, which helix-raylib keeps as draw order instead.
static bool parity_depth = true;
static rlRenderBatch parity_batch;

// A hidden window and a batch of parity's own, read back by shape.
static void parity_open(void) {
    SetTraceLogLevel(LOG_NONE);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "parity");
    parity_batch = rlLoadRenderBatch(1, 65536);
    rlSetRenderBatchActive(&parity_batch);
}

static void parity_close(void) { CloseWindow(); }

// What was drawn since the last shape: the vertex count, then each vertex with its mode (T a triangle's, L a line's; a quad's four as two
// triangles, 0 1 2 and 0 2 3), position, texture coordinates, normal and color. The batch is flushed after.
static void shape(const char *name) {
    rlVertexBuffer *b = &parity_batch.vertexBuffer[parity_batch.currentBuffer];
    int corners[6] = { 0, 1, 2, 0, 2, 3 }, total = 0;
    for (int d = 0; d < parity_batch.drawCounter; d++) {
        rlDrawCall *c = &parity_batch.draws[d];
        total += c->mode == RL_QUADS ? c->vertexCount / 4 * 6 : c->vertexCount;
    }
    printf("%s drawn %d\n", name, total);
    int at = 0;
    for (int d = 0; d < parity_batch.drawCounter; d++) {
        rlDrawCall *c = &parity_batch.draws[d];
        int n = c->mode == RL_QUADS ? c->vertexCount / 4 * 6 : c->vertexCount;
        for (int k = 0; k < n; k++) {
            int i = c->mode == RL_QUADS ? at + k / 6 * 4 + corners[k % 6] : at + k;
            printf("%s %c %.9g %.9g", name, c->mode == RL_LINES ? 'L' : 'T', b->vertices[i * 3], b->vertices[i * 3 + 1]);
            if (parity_depth) printf(" %.9g", b->vertices[i * 3 + 2]);
            printf(" %.9g %.9g %.9g %.9g %.9g %d %d %d %d\n", b->texcoords[i * 2], b->texcoords[i * 2 + 1], b->normals[i * 3], b->normals[i * 3 + 1],
                b->normals[i * 3 + 2], b->colors[i * 4], b->colors[i * 4 + 1], b->colors[i * 4 + 2], b->colors[i * 4 + 3]);
        }
        at += c->vertexCount + c->vertexAlignment;
    }
    rlDrawRenderBatch(&parity_batch);
}

static void parity_floats(const char *name, const char *label, const float *v, int n) {
    printf("%s %s %d", name, label, v ? n : -1);
    if (v) for (int i = 0; i < n; i++) printf(" %.9g", v[i]);
    printf("\n");
}

// A mesh's counts, then its vertices, texture coordinates, normals, tangents and indices (-1 for one it hasn't).
static void mesh(const char *name, Mesh m) {
    printf("%s mesh %d %d\n", name, m.vertexCount, m.triangleCount);
    parity_floats(name, "vertices", m.vertices, m.vertexCount * 3);
    parity_floats(name, "texcoords", m.texcoords, m.vertexCount * 2);
    parity_floats(name, "normals", m.normals, m.vertexCount * 3);
    parity_floats(name, "tangents", m.tangents, m.vertexCount * 4);
    printf("%s indices %d", name, m.indices ? m.triangleCount * 3 : -1);
    if (m.indices) for (int i = 0; i < m.triangleCount * 3; i++) printf(" %d", m.indices[i]);
    printf("\n");
}

static void hit(const char *name, RayCollision c) {
    printf("%s hit %d %.9g %.9g %.9g %.9g %.9g %.9g %.9g\n", name, c.hit, c.distance, c.point.x, c.point.y, c.point.z, c.normal.x, c.normal.y,
        c.normal.z);
}

static void flag(const char *name, bool b) { printf("%s flag %d\n", name, b ? 1 : 0); }
static void num(const char *name, float x) { printf("%s num %.9g\n", name, x); }
static void vec2(const char *name, Vector2 v) { printf("%s vec2 %.9g %.9g\n", name, v.x, v.y); }
static void rect(const char *name, Rectangle r) { printf("%s rect %.9g %.9g %.9g %.9g\n", name, r.x, r.y, r.width, r.height); }

static void color(const char *name, Color c) { printf("%s color %d %d %d %d\n", name, c.r, c.g, c.b, c.a); }

// An image's size, format and mipmaps, then its first level's bytes in hex, 48 to a line, each line a word compared whole.
static void image(const char *name, Image m) {
    int size = m.data ? GetPixelDataSize(m.width, m.height, m.format) : 0;
    printf("%s image %d %d %d %d %d\n", name, m.width, m.height, m.format, m.mipmaps, size);
    for (int i = 0; i < size; i += 48) {
        printf("%s data #", name);
        for (int k = i; k < size && k < i + 48; k++) printf("%02x", ((unsigned char *)m.data)[k]);
        printf("\n");
    }
}

// Text as raylib reads it to draw, a '?' for each byte it can't (as helix-raylib's String holds it): its UTF-8 bytes' count and the bytes in
// hex ("-" for none), or NULL.
static void str(const char *name, const char *s) {
    if (s == NULL) { printf("%s str NULL\n", name); return; }
    unsigned char out[8192];
    int n = 0;
    for (int i = 0; s[i] != '\0';) {
        int size = 0, bytes = 0;
        int cp = GetCodepointNext(s + i, &size);
        if (cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) cp = '?';
        const char *utf8 = CodepointToUTF8(cp, &bytes);
        for (int k = 0; k < bytes && n < (int)sizeof(out); k++) out[n++] = (unsigned char)utf8[k];
        i += size;
    }
    printf("%s str %d ", name, n);
    if (n == 0) printf("-");
    for (int k = 0; k < n; k++) printf("%02x", out[k]);
    printf("\n");
}

static void box(const char *name, BoundingBox b) {
    printf("%s box %.9g %.9g %.9g %.9g %.9g %.9g\n", name, b.min.x, b.min.y, b.min.z, b.max.x, b.max.y, b.max.z);
}
#endif
