// raylib 6.2's glTF materials, printed for tools/ray_parity.py: each material LoadModel reads from web/materials.gltf (makematerials.py),
// its twelve maps' colors, values and textures, each texture's pixels as RGBA, and IsMaterialValid; then a texture two loads of the file
// share, after UnloadMaterial frees one load's.
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

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "materials");
    Model model = LoadModel("web/materials.gltf");
    printf("model %d %d\n", model.meshCount, model.materialCount);
    for (int i = 0; i < model.meshCount; i++) printf("meshmaterial %d %d\n", i, model.meshMaterial[i]);
    char key[64];
    for (int i = 0; i < model.materialCount; i++) {
        Material *m = &model.materials[i];
        printf("material %d valid %d default %d\n", i, IsMaterialValid(*m), m->shader.id == rlGetShaderIdDefault());
        for (int k = 0; k < MAX_MATERIAL_MAPS; k++) {
            MaterialMap *map = &m->maps[k];
            printf("map %d %d color %d %d %d %d value %.9g\n", i, k, map->color.r, map->color.g, map->color.b, map->color.a, map->value);
            sprintf(key, "texture %d %d", i, k);
            texture(key, map->texture);
        }
    }
    Material empty = { 0 };
    printf("empty valid %d\n", IsMaterialValid(empty));
    // Two loads of the file: one's first material freed, the other's textures read after.
    Model other = LoadModel("web/materials.gltf");
    UnloadMaterial(model.materials[1]);
    for (int k = 0; k < MAX_MATERIAL_MAPS; k++) {
        sprintf(key, "shared %d", k);
        texture(key, other.materials[1].maps[k].texture);
    }
    CloseWindow();
    return 0;
}
