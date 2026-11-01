// raylib 5.5's materials, printed for tools/ray_parity.py: LoadMaterialDefault's maps, IsMaterialValid on it and on materials without
// maps or a shader, and what UnloadMaterial leaves: the default texture, a map's own texture freed (GL takes its name again for the next
// texture made), and the default shader.
#include "raylib.h"
#include "rlgl.h"
#include "parity.h"
#include <stdio.h>
#include <stdlib.h>

#define MAX_MATERIAL_MAPS 12  // rmodels.c's, from config.h

static void texture(const char *key, Texture2D t) {
    if (t.id == 0) { printf("%s none\n", key); return; }
    printf("%s %s %d %d %d %d\n", key, t.id == rlGetTextureIdDefault() ? "default" : "own", t.width, t.height, t.mipmaps, t.format);
}

static void maps(const char *name, Material m) {
    char key[64];
    for (int k = 0; k < MAX_MATERIAL_MAPS; k++) {
        MaterialMap *map = &m.maps[k];
        printf("%s map %d color %d %d %d %d value %.9g\n", name, k, map->color.r, map->color.g, map->color.b, map->color.a, map->value);
        sprintf(key, "%s texture %d", name, k);
        texture(key, map->texture);
    }
}

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "materials");
    Material m = LoadMaterialDefault();
    printf("default valid %d shader %d params %.9g %.9g %.9g %.9g\n", IsMaterialValid(m), m.shader.id == rlGetShaderIdDefault(), m.params[0],
        m.params[1], m.params[2], m.params[3]);
    maps("default", m);
    Material empty = { 0 };
    printf("empty valid %d\n", IsMaterialValid(empty));
    Material noshader = LoadMaterialDefault();
    noshader.shader.id = 0;
    printf("noshader valid %d\n", IsMaterialValid(noshader));
    Material nomaps = LoadMaterialDefault();
    free(nomaps.maps);
    nomaps.maps = NULL;
    printf("nomaps valid %d\n", IsMaterialValid(nomaps));

    // A material with a texture of its own on two maps, unloaded.
    Image checked = GenImageChecked(4, 4, 1, 1, RED, BLUE);
    Texture2D own = LoadTextureFromImage(checked);
    Material u = LoadMaterialDefault();
    u.maps[MATERIAL_MAP_NORMAL].texture = own;
    u.maps[MATERIAL_MAP_EMISSION].texture = own;
    UnloadMaterial(u);
    printf("unloaded valid %d\n", IsMaterialValid(u));
    Image white = LoadImageFromTexture((Texture2D){ rlGetTextureIdDefault(), 1, 1, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 });
    image("unloaded default", white);
    Texture2D again = LoadTextureFromImage(checked);
    printf("unloaded freed %d\n", again.id == own.id);
    CloseWindow();
    return 0;
}
