// The Adventurer woman of Quaternius' Ultimate Modular Women drawn by raylib 6.2: her head, body, legs and feet and the sword, each a
// model of its own, CPU-skinned (UpdateModelAnimation) at frame 20 of Sword_Slash, read from Animations.glb; its third frame saved as
// ref.png.
#include "raylib.h"
#include "rlgl.h"
#include <string.h>
int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(640, 360, "modular");
    Camera camera = { { 2.2f, 1.6f, 3.2f }, { 0, 0.9f, 0 }, { 0, 1, 0 }, 45, CAMERA_PERSPECTIVE };
    const char *files[5] = { "web/Adventurer_Head.glb", "web/Adventurer_Body.glb", "web/Adventurer_Legs.glb", "web/Adventurer_Feet.glb",
        "web/Sword.glb" };
    Model parts[5];
    for (int i = 0; i < 5; i++) parts[i] = LoadModel(files[i]);
    int count = 0, clip = 0;
    ModelAnimation *anims = LoadModelAnimations("web/Animations.glb", &count);
    for (int a = 0; a < count; a++) if (!strcmp(anims[a].name, "CharacterArmature|Sword_Slash")) clip = a;
    for (int frame = 0; frame < 3; frame++) {
        for (int i = 0; i < 5; i++) UpdateModelAnimation(parts[i], anims[clip], 20);
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);
        DrawGrid(10, 0.5f);
        for (int i = 0; i < 5; i++) DrawModel(parts[i], (Vector3){ 0, 0, 0 }, 1, WHITE);
        EndMode3D();
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
