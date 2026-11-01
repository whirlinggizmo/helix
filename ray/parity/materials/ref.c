// raylib 5.5's materials, printed for tools/ray_parity.py: LoadMaterialDefault's maps, IsMaterialValid on it and on materials without
// maps or a shader, and what UnloadMaterial leaves: the default texture, a map's own texture freed (GL takes its name again for the next
// texture made), and the default shader; a texture taken from a model still there after UnloadModel (the next texture made takes another
// name); and a model's texture read from a second load of its file after UnloadMaterial frees the first load's material.
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

// A texture's pixels, read back and made RGBA.
static void pixels(const char *key, Texture2D t) {
    Image im = LoadImageFromTexture(t);
    ImageFormat(&im, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
    image(key, im);
    UnloadImage(im);
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

    // A texture taken from a model, the model unloaded: its first texture made, so GL would take its name first were it freed.
    Model taken = LoadModel("web/materials.gltf");
    Texture2D kept = taken.materials[1].maps[MATERIAL_MAP_ALBEDO].texture;
    UnloadModel(taken);
    pixels("taken", kept);
    Texture2D next = LoadTextureFromImage(checked);
    printf("taken kept %d\n", next.id != kept.id);

    // Two loads of the file: the first's material unloaded, the second's textures read after.
    Model first = LoadModel("web/materials.gltf");
    Model second = LoadModel("web/materials.gltf");
    UnloadMaterial(first.materials[1]);
    pixels("shared albedo", second.materials[1].maps[MATERIAL_MAP_ALBEDO].texture);
    pixels("shared normal", second.materials[1].maps[MATERIAL_MAP_NORMAL].texture);
    CloseWindow();
    return 0;
}
