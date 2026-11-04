// One greenman drawn by raylib 6.2 in 240 poses in one frame, as a game draws a crowd: UpdateModelAnimation then DrawModel for each,
// a 16 x 15 grid, each its own frame of the walk; the last two rows' through the example's skinning shader (a model of their own, posed
// and drawn the same way), where helix-raylib's harness draws the second last through a shader including its skinning.glsl; and a
// model through that shader never posed, in its bind pose. Its third frame saved as ref.png.
#include "raylib.h"
#include "rlgl.h"
int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(640, 360, "crowd");
    Camera camera = { { 0, 14, 16 }, { 0, 0, 1 }, { 0, 1, 0 }, 45, CAMERA_PERSPECTIVE };
    Model model = LoadModel("web/greenman.glb"), gpu = LoadModel("web/greenman.glb"), still = LoadModel("web/greenman.glb");
    Shader skinning = LoadShader("web/skinning.vs", "web/skinning.fs");
    gpu.materials[1].shader = skinning;
    still.materials[1].shader = skinning;
    int count = 0;
    ModelAnimation *anims = LoadModelAnimations("web/greenman.glb", &count);
    for (int frame = 0; frame < 3; frame++) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);
        for (int i = 0; i < 240; i++) {
            int row = i / 16, column = i % 16;
            Model m = row >= 13 ? gpu : model;
            UpdateModelAnimation(m, anims[1 + i % 3], 0.75f * i + frame);
            DrawModel(m, (Vector3){ (column - 7.5f) * 1.2f, 0, (row - 7) * 1.2f }, 0.6f, WHITE);
        }
        // Never posed: its bind pose, the skinning shader given its identity bones.
        DrawModel(still, (Vector3){ 0, 0, 9 }, 0.6f, WHITE);
        EndMode3D();
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
