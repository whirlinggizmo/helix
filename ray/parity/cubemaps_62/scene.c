// Cubemaps drawn by raylib 6.2: raylib's skybox example's skybox.png (a 4 x 3 cross, its layout detected) behind, drawn as the example
// draws it (its shaders, culling and the depth mask off); in front, cubes sampling a cubemap by their positions, two of each (one turned
// to show +X, +Y and +Z, the other -X, -Y and -Z), from faces painted in each layout, a column and a row read as they are, and an image
// read as a layout it isn't; each cubemap's fields printed. Its third frame saved as ref.png.
#include "raylib.h"
#include "rlgl.h"

static const char *CUBE_VS =
    "#version 330\n"
    "in vec3 vertexPosition;\n"
    "uniform mat4 mvp;\n"
    "out vec3 fragPosition;\n"
    "void main() {\n"
    "    fragPosition = vertexPosition;\n"
    "    gl_Position = mvp*vec4(vertexPosition, 1.0);\n"
    "}\n";

static const char *CUBE_FS =
    "#version 330\n"
    "in vec3 fragPosition;\n"
    "uniform samplerCube cubeMap;\n"
    "uniform vec4 colDiffuse;\n"
    "out vec4 finalColor;\n"
    "void main() {\n"
    "    finalColor = texture(cubeMap, fragPosition)*colDiffuse;\n"
    "}\n";

// Face i painted at (x, y): its color, and a white bar along its top from its left, so a face turned or mirrored shows.
static void Paint(Image *image, int x, int y, int size, int i) {
    Color colors[6] = { RED, LIME, BLUE, GOLD, PURPLE, ORANGE };
    ImageDrawRectangle(image, x, y, size, size, colors[i]);
    ImageDrawRectangle(image, x + 1, y + 1, size/2, size/5, WHITE);
    ImageDrawRectangle(image, x + size - 3, y + size - 3, 2, 2, BLACK);
}

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(640, 360, "cubemaps");
    Camera camera = { { 0, 0, 12 }, { 0, 0, 0 }, { 0, 1, 0 }, 45, CAMERA_PERSPECTIVE };
    int s = 16;
    // A column and a row, +X, -X, +Y, -Y, +Z, -Z; the row in grayscale.
    Image column = GenImageColor(s, s*6, BLANK), row = GenImageColor(s*6, s, BLANK);
    for (int i = 0; i < 6; i++) {
        Paint(&column, 0, s*i, s, i);
        Paint(&row, s*i, 0, s, i);
    }
    ImageFormat(&row, PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
    // The crosses, in each one's places; the 4 x 3's -Z half translucent, blended over magenta.
    int threeByFour[6][2] = { { 1, 1 }, { 1, 3 }, { 1, 0 }, { 1, 2 }, { 0, 1 }, { 2, 1 } };
    int fourByThree[6][2] = { { 2, 1 }, { 0, 1 }, { 1, 0 }, { 1, 2 }, { 1, 1 }, { 3, 1 } };
    Image tall = GenImageColor(s*3, s*4, DARKGRAY), wide = GenImageColor(s*4, s*3, DARKGRAY);
    for (int i = 0; i < 6; i++) {
        Paint(&tall, threeByFour[i][0]*s, threeByFour[i][1]*s, s, i);
        Paint(&wide, fourByThree[i][0]*s, fourByThree[i][1]*s, s, i);
    }
    ImageDrawRectangle(&wide, 3*s, s, s, s/2, (Color){ 0, 200, 255, 128 });
    Image sky = LoadImage("web/skybox.png");
    ImageFormat(&sky, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
    Image square = GenImageColor(32, 32, RED);
    TextureCubemap cubes[6] = {
        LoadTextureCubemap(column, CUBEMAP_LAYOUT_LINE_VERTICAL),
        LoadTextureCubemap(row, CUBEMAP_LAYOUT_AUTO_DETECT),
        LoadTextureCubemap(tall, CUBEMAP_LAYOUT_AUTO_DETECT),
        LoadTextureCubemap(wide, CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE),
        LoadTextureCubemap(wide, CUBEMAP_LAYOUT_LINE_VERTICAL),
        LoadTextureCubemap(tall, CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE),
    };
    TextureCubemap skyCube = LoadTextureCubemap(sky, CUBEMAP_LAYOUT_AUTO_DETECT);
    TextureCubemap none = LoadTextureCubemap(square, CUBEMAP_LAYOUT_AUTO_DETECT);
    // The skybox, as raylib's example makes it.
    Model skybox = LoadModelFromMesh(GenMeshCube(1, 1, 1));
    skybox.materials[0].shader = LoadShader("web/skybox.vs", "web/skybox.fs");
    SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, "environmentMap"), (int[1]){ MATERIAL_MAP_CUBEMAP }, SHADER_UNIFORM_INT);
    SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, "doGamma"), (int[1]){ 0 }, SHADER_UNIFORM_INT);
    SetShaderValue(skybox.materials[0].shader, GetShaderLocation(skybox.materials[0].shader, "vflipped"), (int[1]){ 0 }, SHADER_UNIFORM_INT);
    skybox.materials[0].maps[MATERIAL_MAP_CUBEMAP].texture = skyCube;
    // The cubes: the sampler found through the shader's locations, as DrawMesh sets it to the cubemap map's unit.
    Shader sampling = LoadShaderFromMemory(CUBE_VS, CUBE_FS);
    sampling.locs[SHADER_LOC_MAP_CUBEMAP] = GetShaderLocation(sampling, "cubeMap");
    Model models[6];
    for (int i = 0; i < 6; i++) {
        models[i] = LoadModelFromMesh(GenMeshCube(1.6f, 1.6f, 1.6f));
        models[i].materials[0].shader = sampling;
        models[i].materials[0].maps[MATERIAL_MAP_CUBEMAP].texture = cubes[i];
    }
    for (int frame = 0; frame < 3; frame++) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);
        rlDisableBackfaceCulling();
        rlDisableDepthMask();
        DrawModel(skybox, (Vector3){ 0, 0, 0 }, 1, WHITE);
        rlEnableBackfaceCulling();
        rlEnableDepthMask();
        for (int i = 0; i < 6; i++) {
            float x = -6.5f + 2.6f*i;
            DrawModelEx(models[i], (Vector3){ x, 1.4f, 0 }, (Vector3){ 1, -1, 0 }, 54.7356f, (Vector3){ 1, 1, 1 }, WHITE);
            DrawModelEx(models[i], (Vector3){ x, -1.4f, 0 }, (Vector3){ 1, -1, 0 }, -125.2644f, (Vector3){ 1, 1, 1 }, WHITE);
        }
        EndMode3D();
        for (int i = 0; i < 8; i++) {
            TextureCubemap c = i < 6 ? cubes[i] : i == 6 ? skyCube : none;
            DrawText(TextFormat("%i %i %i %i %i", c.id > 0, c.width, c.height, c.mipmaps, c.format), 8 + 78*i, 340, 10, BLACK);
        }
        rlDrawRenderBatchActive();
        if (frame == 2) ExportImage(LoadImageFromScreen(), "ref.png");
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
