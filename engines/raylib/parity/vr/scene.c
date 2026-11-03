// raylib 5.5's core_vr_simulator, drawn by raylib: the Oculus Rift CV1's stereo config, both eyes drawn into a 2160 x 1200 render
// texture, then onto the 800 x 450 screen through raylib's distortion330.fs (its uniforms' initializers, then the config's values). A
// sphere is drawn too, so a mesh's stereo path is in it beside the batch's. The example's camera input, cursor and DrawFPS are left out,
// so each frame is the same. Its third frame saved as ref.png.
#include "raylib.h"
#include "rlgl.h"

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(800, 450, "vr");
    VrDeviceInfo device = {
        .hResolution = 2160,
        .vResolution = 1200,
        .hScreenSize = 0.133793f,
        .vScreenSize = 0.0669f,
        .eyeToScreenDistance = 0.041f,
        .lensSeparationDistance = 0.07f,
        .interpupillaryDistance = 0.07f,
        .lensDistortionValues[0] = 1.0f,
        .lensDistortionValues[1] = 0.22f,
        .lensDistortionValues[2] = 0.24f,
        .lensDistortionValues[3] = 0.0f,
        .chromaAbCorrection[0] = 0.996f,
        .chromaAbCorrection[1] = -0.004f,
        .chromaAbCorrection[2] = 1.014f,
        .chromaAbCorrection[3] = 0.0f,
    };
    VrStereoConfig config = LoadVrStereoConfig(device);
    Shader distortion = LoadShader(0, "web/distortion330.fs");
    SetShaderValue(distortion, GetShaderLocation(distortion, "leftLensCenter"), config.leftLensCenter, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "rightLensCenter"), config.rightLensCenter, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "leftScreenCenter"), config.leftScreenCenter, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "rightScreenCenter"), config.rightScreenCenter, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "scale"), config.scale, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "scaleIn"), config.scaleIn, SHADER_UNIFORM_VEC2);
    SetShaderValue(distortion, GetShaderLocation(distortion, "deviceWarpParam"), device.lensDistortionValues, SHADER_UNIFORM_VEC4);
    SetShaderValue(distortion, GetShaderLocation(distortion, "chromaAbParam"), device.chromaAbCorrection, SHADER_UNIFORM_VEC4);
    RenderTexture2D target = LoadRenderTexture(device.hResolution, device.vResolution);
    Rectangle sourceRec = { 0.0f, 0.0f, (float)target.texture.width, -(float)target.texture.height };
    Rectangle destRec = { 0.0f, 0.0f, (float)GetScreenWidth(), (float)GetScreenHeight() };
    Camera camera = { 0 };
    camera.position = (Vector3){ 5.0f, 2.0f, 5.0f };
    camera.target = (Vector3){ 0.0f, 2.0f, 0.0f };
    camera.up = (Vector3){ 0.0f, 1.0f, 0.0f };
    camera.fovy = 60.0f;
    camera.projection = CAMERA_PERSPECTIVE;
    Vector3 cubePosition = { 0.0f, 0.0f, 0.0f };
    Model sphere = LoadModelFromMesh(GenMeshSphere(0.6f, 16, 16));
    for (int frame = 0; frame < 3; frame++) {
        BeginTextureMode(target);
        ClearBackground(RAYWHITE);
        BeginVrStereoMode(config);
        BeginMode3D(camera);
        DrawCube(cubePosition, 2.0f, 2.0f, 2.0f, RED);
        DrawCubeWires(cubePosition, 2.0f, 2.0f, 2.0f, MAROON);
        DrawGrid(40, 1.0f);
        DrawModel(sphere, (Vector3){ 0.0f, 2.5f, 1.0f }, 1.0f, BLUE);
        EndMode3D();
        EndVrStereoMode();
        EndTextureMode();
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginShaderMode(distortion);
        DrawTexturePro(target.texture, sourceRec, destRec, (Vector2){ 0.0f, 0.0f }, 0.0f, WHITE);
        EndShaderMode();
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    UnloadVrStereoConfig(config);
    UnloadRenderTexture(target);
    UnloadShader(distortion);
    CloseWindow();
    return 0;
}
