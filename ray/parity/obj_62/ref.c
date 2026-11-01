// raylib 6.2's OBJ models, printed for tools/ray_parity.py: each model LoadModel reads (makeobj.py's, and raylib's own cube.obj), its
// meshes' vertices, texture coordinates, normals and colors, each mesh's material, and its materials' maps (as materials_62's ref.c
// prints them), each texture's pixels as RGBA.
#include "raylib.h"
#include "rlgl.h"
#include "parity.h"
#include <stdio.h>

#define MAX_MATERIAL_MAPS 12  // rmodels.c's, from config.h

// A texture: none (id 0), raylib's default one, or its own, its size, mipmaps, format and pixels, read back and made RGBA.
static void texture(const char *key, Texture2D t) {
    if (t.id == 0) { printf("%s none\n", key); return; }
    if (t.id == rlGetTextureIdDefault()) { printf("%s default %d %d %d %d\n", key, t.width, t.height, t.mipmaps, t.format); return; }
    printf("%s own %d %d %d %d\n", key, t.width, t.height, t.mipmaps, t.format);
    Image im = LoadImageFromTexture(t);
    ImageFormat(&im, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
    image(key, im);
    UnloadImage(im);
}

static void materials(const char *name, Material *ms, int count) {
    char key[96];
    for (int i = 0; i < count; i++) {
        Material *m = &ms[i];
        printf("%s material %d default %d\n", name, i, m->shader.id == rlGetShaderIdDefault());
        for (int k = 0; k < MAX_MATERIAL_MAPS; k++) {
            MaterialMap *map = &m->maps[k];
            printf("%s map %d %d color %d %d %d %d value %.9g\n", name, i, k, map->color.r, map->color.g, map->color.b, map->color.a, map->value);
            sprintf(key, "%s texture %d %d", name, i, k);
            texture(key, map->texture);
        }
    }
}

static void model(const char *name, const char *file) {
    Model model = LoadModel(file);
    printf("%s model %d %d\n", name, model.meshCount, model.materialCount);
    char key[96];
    for (int i = 0; i < model.meshCount; i++) {
        printf("%s meshmaterial %d %d\n", name, i, model.meshMaterial[i]);
        sprintf(key, "%s %d", name, i);
        mesh(key, model.meshes[i]);
        Mesh m = model.meshes[i];
        printf("%s %d colors %d", name, i, m.colors ? m.vertexCount * 4 : -1);
        if (m.colors) for (int k = 0; k < m.vertexCount * 4; k++) printf(" %d", m.colors[k]);
        printf("\n");
    }
    materials(name, model.materials, model.materialCount);
    UnloadModel(model);
}

int main(void) {
    SetTraceLogLevel(LOG_NONE);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "obj");
    model("shapes", "web/obj/shapes.obj");
    model("nolib", "web/obj/nolib.obj");
    model("plain", "web/obj/plain.obj");
    model("cube", "web/obj/cube.obj");
    CloseWindow();
    return 0;
}
