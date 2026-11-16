// raylib 6.2's lighting example's setup (rlights.h, lighting.vs and lighting.fs): a plane and a cube lit by four point lights, the
// lights drawn as spheres; and greenman under the same shader, posed by UpdateModelAnimation (skinned on the CPU, as raylib skins a
// mesh whose shader doesn't read the bones) and drawn in three poses, the third through a second load of the same shader, lit by the
// same lights, as helix-raylib's lights light every lit draw (rlights counts its lights per program, so the second's are set by name).
// Its third frame saved as ref.png.
#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"
#define RLIGHTS_IMPLEMENTATION
#include "rlights.h"
// Sets the second shader's light i to a light's values, as UpdateLightValues sets the first's.
static void SetOwnLight(Shader own, int i, Light light) {
    int enabled = light.enabled, type = light.type;
    SetShaderValue(own, GetShaderLocation(own, TextFormat("lights[%i].enabled", i)), &enabled, SHADER_UNIFORM_INT);
    SetShaderValue(own, GetShaderLocation(own, TextFormat("lights[%i].type", i)), &type, SHADER_UNIFORM_INT);
    SetShaderValue(own, GetShaderLocation(own, TextFormat("lights[%i].position", i)), (float[3]){ light.position.x, light.position.y, light.position.z }, SHADER_UNIFORM_VEC3);
    SetShaderValue(own, GetShaderLocation(own, TextFormat("lights[%i].target", i)), (float[3]){ light.target.x, light.target.y, light.target.z }, SHADER_UNIFORM_VEC3);
    SetShaderValue(own, GetShaderLocation(own, TextFormat("lights[%i].color", i)), (float[4]){ light.color.r/255.0f, light.color.g/255.0f, light.color.b/255.0f, light.color.a/255.0f }, SHADER_UNIFORM_VEC4);
}
int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(640, 360, "lighting");
    Camera camera = { { 2, 4, 6 }, { 0, 0.5f, 0 }, { 0, 1, 0 }, 45, CAMERA_PERSPECTIVE };
    Shader shader = LoadShader("web/lighting.vs", "web/lighting.fs");
    shader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shader, "viewPos");
    int ambientLoc = GetShaderLocation(shader, "ambient");
    SetShaderValue(shader, ambientLoc, (float[4]){ 0.1f, 0.1f, 0.1f, 1.0f }, SHADER_UNIFORM_VEC4);
    Shader own = LoadShader("web/lighting.vs", "web/lighting.fs");
    own.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(own, "viewPos");
    SetShaderValue(own, GetShaderLocation(own, "ambient"), (float[4]){ 0.2f, 0.2f, 0.3f, 1.0f }, SHADER_UNIFORM_VEC4);
    Light lights[MAX_LIGHTS] = { 0 };
    lights[0] = CreateLight(LIGHT_POINT, (Vector3){ -2, 1, -2 }, Vector3Zero(), YELLOW, shader);
    lights[1] = CreateLight(LIGHT_POINT, (Vector3){ 2, 1, 2 }, Vector3Zero(), RED, shader);
    lights[2] = CreateLight(LIGHT_POINT, (Vector3){ -2, 1, 2 }, Vector3Zero(), GREEN, shader);
    lights[3] = CreateLight(LIGHT_DIRECTIONAL, (Vector3){ 2, 3, -2 }, Vector3Zero(), BLUE, shader);
    Model plane = LoadModelFromMesh(GenMeshPlane(10, 10, 1, 1)), cube = LoadModelFromMesh(GenMeshCube(2, 4, 2));
    plane.materials[0].shader = shader;
    cube.materials[0].shader = shader;
    Model man = LoadModel("web/greenman.glb"), other = LoadModel("web/greenman.glb");
    for (int i = 0; i < man.materialCount; i++) man.materials[i].shader = shader;
    for (int i = 0; i < other.materialCount; i++) other.materials[i].shader = own;
    int count = 0;
    ModelAnimation *anims = LoadModelAnimations("web/greenman.glb", &count);
    for (int frame = 0; frame < 3; frame++) {
        float cameraPos[3] = { camera.position.x, camera.position.y, camera.position.z };
        SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], cameraPos, SHADER_UNIFORM_VEC3);
        SetShaderValue(own, own.locs[SHADER_LOC_VECTOR_VIEW], cameraPos, SHADER_UNIFORM_VEC3);
        lights[2].enabled = frame != 1;
        for (int i = 0; i < MAX_LIGHTS; i++) UpdateLightValues(shader, lights[i]);
        for (int i = 0; i < MAX_LIGHTS; i++) SetOwnLight(own, i, lights[i]);
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);
        DrawModel(plane, (Vector3){ 0, -0.02f, 0 }, 1, WHITE);
        DrawModel(cube, (Vector3){ -2.5f, 0, -1 }, 0.5f, WHITE);
        UpdateModelAnimation(man, anims[1], 10.5f + frame);
        DrawModel(man, (Vector3){ 0.6f, 0, 0.8f }, 0.8f, WHITE);
        UpdateModelAnimation(man, anims[2], 20.25f + frame);
        DrawModel(man, (Vector3){ 2.2f, 0, -0.6f }, 0.8f, WHITE);
        UpdateModelAnimation(other, anims[3], 5 + frame);
        DrawModel(other, (Vector3){ -0.8f, 0, 1.8f }, 0.8f, WHITE);
        for (int i = 0; i < MAX_LIGHTS; i++)
        {
            if (lights[i].enabled) DrawSphereEx(lights[i].position, 0.2f, 8, 8, lights[i].color);
            else DrawSphereWires(lights[i].position, 0.2f, 8, 8, ColorAlpha(lights[i].color, 0.3f));
        }
        DrawGrid(10, 1.0f);
        EndMode3D();
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
