// raylib 5.5's shadowmap example (shaders_shadowmap.c, its shadowmap.vs and shadowmap.fs), built against 6.2, UpdateModelAnimation's
// oracle, whose copies of the shaders differ in spacing and comments alone: a cube floor, a cube and the robot, animated,
// drawn into a render texture of depth alone from an orthographic camera at the light, then drawn again by the camera, each fragment
// shadowed where the shadow map's depth is nearer the light. Deterministic for the comparison: the camera where the example starts it,
// turned a little each frame as CAMERA_ORBITAL turns it at 60 frames a second, the robot at a fixed frame of its first animation, the
// light turned as the arrow keys turn it, and no multisampling. Its third frame saved as ref.png.
#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"
#define SHADOWMAP_RESOLUTION 1024
// The example's own two functions, as it writes them.
static RenderTexture2D LoadShadowmapRenderTexture(int width, int height)
{
    RenderTexture2D target = { 0 };
    target.id = rlLoadFramebuffer();
    target.texture.width = width;
    target.texture.height = height;
    if (target.id > 0)
    {
        rlEnableFramebuffer(target.id);
        target.depth.id = rlLoadTextureDepth(width, height, false);
        target.depth.width = width;
        target.depth.height = height;
        target.depth.format = 19;
        target.depth.mipmaps = 1;
        rlFramebufferAttach(target.id, target.depth.id, RL_ATTACHMENT_DEPTH, RL_ATTACHMENT_TEXTURE2D, 0);
        rlFramebufferComplete(target.id);
        rlDisableFramebuffer();
    }
    return target;
}
static void UnloadShadowmapRenderTexture(RenderTexture2D target)
{
    if (target.id > 0) rlUnloadFramebuffer(target.id);
}
static void DrawScene(Model cube, Model robot)
{
    DrawModelEx(cube, Vector3Zero(), (Vector3){ 0.0f, 1.0f, 0.0f }, 0.0f, (Vector3){ 10.0f, 1.0f, 10.0f }, BLUE);
    DrawModelEx(cube, (Vector3){ 1.5f, 1.0f, -1.5f }, (Vector3){ 0.0f, 1.0f, 0.0f }, 0.0f, Vector3One(), WHITE);
    DrawModelEx(robot, (Vector3){ 0.0f, 0.5f, 0.0f }, (Vector3){ 0.0f, 1.0f, 0.0f }, 0.0f, (Vector3){ 1.0f, 1.0f, 1.0f }, RED);
}
int main(void)
{
    SetTraceLogLevel(LOG_WARNING);
    const int screenWidth = 800, screenHeight = 450;
    InitWindow(screenWidth, screenHeight, "shadowmap");
    Camera3D cam = { 0 };
    cam.position = (Vector3){ 10.0f, 10.0f, 10.0f };
    cam.target = Vector3Zero();
    cam.projection = CAMERA_PERSPECTIVE;
    cam.up = (Vector3){ 0.0f, 1.0f, 0.0f };
    cam.fovy = 45.0f;
    Shader shadowShader = LoadShader("web/shadowmap.vs", "web/shadowmap.fs");
    shadowShader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shadowShader, "viewPos");
    Vector3 lightDir = Vector3Normalize((Vector3){ 0.35f, -1.0f, -0.35f });
    Color lightColor = WHITE;
    Vector4 lightColorNormalized = ColorNormalize(lightColor);
    int lightDirLoc = GetShaderLocation(shadowShader, "lightDir");
    int lightColLoc = GetShaderLocation(shadowShader, "lightColor");
    SetShaderValue(shadowShader, lightDirLoc, &lightDir, SHADER_UNIFORM_VEC3);
    SetShaderValue(shadowShader, lightColLoc, &lightColorNormalized, SHADER_UNIFORM_VEC4);
    int ambientLoc = GetShaderLocation(shadowShader, "ambient");
    float ambient[4] = { 0.1f, 0.1f, 0.1f, 1.0f };
    SetShaderValue(shadowShader, ambientLoc, ambient, SHADER_UNIFORM_VEC4);
    int lightVPLoc = GetShaderLocation(shadowShader, "lightVP");
    int shadowMapLoc = GetShaderLocation(shadowShader, "shadowMap");
    int shadowMapResolution = SHADOWMAP_RESOLUTION;
    SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "shadowMapResolution"), &shadowMapResolution, SHADER_UNIFORM_INT);
    Model cube = LoadModelFromMesh(GenMeshCube(1.0f, 1.0f, 1.0f));
    cube.materials[0].shader = shadowShader;
    Model robot = LoadModel("web/robot.glb");
    for (int i = 0; i < robot.materialCount; i++) robot.materials[i].shader = shadowShader;
    int animCount = 0;
    ModelAnimation *robotAnimations = LoadModelAnimations("web/robot.glb", &animCount);
    RenderTexture2D shadowMap = LoadShadowmapRenderTexture(SHADOWMAP_RESOLUTION, SHADOWMAP_RESOLUTION);
    Camera3D lightCam = { 0 };
    lightCam.position = Vector3Scale(lightDir, -15.0f);
    lightCam.target = Vector3Zero();
    lightCam.projection = CAMERA_ORTHOGRAPHIC;
    lightCam.up = (Vector3){ 0.0f, 1.0f, 0.0f };
    lightCam.fovy = 20.0f;
    for (int frame = 0; frame < 3; frame++)
    {
        // CAMERA_ORBITAL's turn of a frame at 60 frames a second, and the left key's turn of the light.
        Vector3 cameraPos = cam.position;
        SetShaderValue(shadowShader, shadowShader.locs[SHADER_LOC_VECTOR_VIEW], &cameraPos, SHADER_UNIFORM_VEC3);
        Matrix rotation = MatrixRotate(cam.up, -0.5f/60.0f);
        cam.position = Vector3Add(Vector3Transform(Vector3Subtract(cam.position, cam.target), rotation), cam.target);
        UpdateModelAnimation(robot, robotAnimations[0], 20 + 7*frame);
        if (lightDir.x < 0.6f) lightDir.x += 0.05f;
        lightDir = Vector3Normalize(lightDir);
        lightCam.position = Vector3Scale(lightDir, -15.0f);
        SetShaderValue(shadowShader, lightDirLoc, &lightDir, SHADER_UNIFORM_VEC3);
        BeginDrawing();
        Matrix lightView;
        Matrix lightProj;
        BeginTextureMode(shadowMap);
        ClearBackground(WHITE);
        BeginMode3D(lightCam);
            lightView = rlGetMatrixModelview();
            lightProj = rlGetMatrixProjection();
            DrawScene(cube, robot);
        EndMode3D();
        EndTextureMode();
        Matrix lightViewProj = MatrixMultiply(lightView, lightProj);
        ClearBackground(RAYWHITE);
        SetShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);
        rlEnableShader(shadowShader.id);
        int slot = 10;
        rlActiveTextureSlot(10);
        rlEnableTexture(shadowMap.depth.id);
        rlSetUniform(shadowMapLoc, &slot, SHADER_UNIFORM_INT, 1);
        BeginMode3D(cam);
            DrawScene(cube, robot);
        EndMode3D();
        DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, GRAY);
        DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, RED);
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    UnloadShader(shadowShader);
    UnloadModel(cube);
    UnloadModel(robot);
    UnloadModelAnimations(robotAnimations, animCount);
    UnloadShadowmapRenderTexture(shadowMap);
    CloseWindow();
    return 0;
}
