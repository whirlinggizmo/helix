// greenman drawn by raylib 6.2: CPU-skinned (UpdateModelAnimation, the default shader) on the left, GPU-skinned (the example's
// skinning shader) on the right, a third copy blended (UpdateModelAnimationEx) behind, and a fourth blended and GPU-skinned behind on
// the right; its third frame saved as ref.png.
#include "raylib.h"
#include "rlgl.h"
int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(640, 360, "anim");
    Camera camera = { { 4, 3.5f, 5 }, { 0, 1, 0 }, { 0, 1, 0 }, 45, CAMERA_PERSPECTIVE };
    Model cpu = LoadModel("web/greenman.glb"), gpu = LoadModel("web/greenman.glb"), mixed = LoadModel("web/greenman.glb"),
          mixedGpu = LoadModel("web/greenman.glb");
    Shader skinning = LoadShader("web/skinning.vs", "web/skinning.fs");
    gpu.materials[1].shader = skinning;
    mixedGpu.materials[1].shader = skinning;
    int count = 0;
    ModelAnimation *anims = LoadModelAnimations("web/greenman.glb", &count);
    for (int frame = 0; frame < 3; frame++) {
        UpdateModelAnimation(cpu, anims[1], 30.5f + frame);
        UpdateModelAnimation(gpu, anims[2], 20.25f + frame);
        UpdateModelAnimationEx(mixed, anims[1], 12 + frame, anims[3], 25, 0.4f);
        UpdateModelAnimationEx(mixedGpu, anims[2], 8.5f + frame, anims[1], 30, 0.7f);
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);
        DrawGrid(10, 1);
        DrawModel(cpu, (Vector3){ -1.3f, 0, 0 }, 1, WHITE);
        DrawModel(gpu, (Vector3){ 1.3f, 0, 0 }, 1, WHITE);
        DrawModel(mixed, (Vector3){ 0, 0, -2 }, 1, WHITE);
        DrawModel(mixedGpu, (Vector3){ 2.6f, 0, -2.2f }, 1, WHITE);
        EndMode3D();
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
