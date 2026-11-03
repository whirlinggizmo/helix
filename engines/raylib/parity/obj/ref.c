// raylib 5.5's MTL materials, printed for tools/ray_parity.py: the materials LoadMaterials reads from lib.mtl (obj_62's makeobj.py), each
// one's maps (as materials_62's ref.c prints them), each texture's pixels as RGBA; and how many it reads from a missing .mtl file and from
// a file that isn't one.
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
    SetTraceLogLevel(LOG_NONE);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "obj");
    int count = 0;
    Material *ms = LoadMaterials("lib.mtl", &count);
    printf("lib count %d\n", count);
    char key[96];
    for (int i = 0; i < count; i++) {
        Material *m = &ms[i];
        printf("lib material %d default %d valid %d\n", i, m->shader.id == rlGetShaderIdDefault(), IsMaterialValid(*m));
        for (int k = 0; k < MAX_MATERIAL_MAPS; k++) {
            MaterialMap *map = &m->maps[k];
            printf("lib map %d %d color %d %d %d %d value %.9g\n", i, k, map->color.r, map->color.g, map->color.b, map->color.a, map->value);
            sprintf(key, "lib texture %d %d", i, k);
            texture(key, map->texture);
        }
    }
    count = -1;
    LoadMaterials("nothere.mtl", &count);
    printf("missing count %d\n", count);
    count = -1;
    LoadMaterials("web/obj/shapes.obj", &count);
    printf("other count %d\n", count);
    CloseWindow();
    return 0;
}
