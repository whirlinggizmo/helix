// raylib 6.2's skeletal animation on Quaternius' Ultimate Modular Women, printed for tools/raylib_parity.py: the animations, read from a
// file of their own (Animations.glb, an armature without meshes), each outfit part (and the sword) checked against them, and for three
// clips at whole, fractional and wrapped frames the bone matrices (the body's) and each part's skinned vertices, a sample of them.
#include "raylib.h"
#include <stdio.h>
#include <string.h>

void UpdateModelAnimationBones(Model model, ModelAnimation anim, float frame);

static const char *PARTS[5] = { "Head", "Body", "Legs", "Feet", "Sword" };
static const char *FILES[5] = { "web/Adventurer_Head.glb", "web/Adventurer_Body.glb", "web/Adventurer_Legs.glb", "web/Adventurer_Feet.glb",
    "web/Sword.glb" };
static const char *CLIPS[3] = { "CharacterArmature|Idle", "CharacterArmature|Walk", "CharacterArmature|Sword_Slash" };

static void matrices(const char *key, Model m) {
    for (int b = 0; b < (int)m.skeleton.boneCount; b++) {
        Matrix x = m.boneMatrices[b];
        float *f = (float *)&x;
        printf("%s %d", key, b);
        for (int i = 0; i < 16; i++) printf(" %.9g", f[i]);
        printf("\n");
    }
}

static void vertices(const char *key, Model m) {
    for (int i = 0; i < m.meshCount; i++) {
        Mesh *mesh = &m.meshes[i];
        if (mesh->animVertices == NULL) { printf("%s %d none\n", key, i); continue; }
        int step = mesh->vertexCount / 40 + 1;
        for (int v = 0; v < mesh->vertexCount; v += step) {
            printf("%s %d %d %.9g %.9g %.9g", key, i, v, mesh->animVertices[v*3], mesh->animVertices[v*3+1], mesh->animVertices[v*3+2]);
            if (mesh->animNormals) printf(" %.9g %.9g %.9g", mesh->animNormals[v*3], mesh->animNormals[v*3+1], mesh->animNormals[v*3+2]);
            printf("\n");
        }
    }
}

int main(void) {
    SetTraceLogLevel(LOG_WARNING);
    InitWindow(64, 64, "modular");
    int count = 0;
    ModelAnimation *anims = LoadModelAnimations("web/Animations.glb", &count);
    if (anims == NULL) count = 0;
    printf("part Animations\n");
    printf("anims %d\n", count);
    int clips[3] = { -1, -1, -1 };
    for (int a = 0; a < count; a++) {
        printf("anim %d %s %d %d\n", a, anims[a].name, anims[a].keyframeCount, (int)anims[a].boneCount);
        for (int c = 0; c < 3; c++) if (!strcmp(anims[a].name, CLIPS[c])) clips[c] = a;
    }
    // The frames the fractional ones lie between, as LoadModelAnimations sampled them.
    for (int c = 0; c < 3; c++) {
        if (clips[c] < 0) continue;
        ModelAnimation an = anims[clips[c]];
        int frames[3] = { 7, 8, 3 };
        for (int k = 0; k < 3; k++)
            for (int b = 0; b < (int)an.boneCount; b++) {
                Transform t = an.keyframePoses[frames[k]][b];
                printf("pose %d %d %d %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g\n", c, frames[k], b, t.translation.x, t.translation.y,
                    t.translation.z, t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w, t.scale.x, t.scale.y, t.scale.z);
            }
    }
    for (int p = 0; p < 5; p++) {
        Model model = LoadModel(FILES[p]);
        printf("part %s\n", PARTS[p]);
        printf("model %d %d %d\n", model.meshCount, model.materialCount, (int)model.skeleton.boneCount);
        for (int i = 0; i < model.meshCount; i++)
            printf("mesh %d %d %d %d\n", i, model.meshes[i].vertexCount, model.meshes[i].boneIndices != NULL, model.meshes[i].boneWeights != NULL);
        for (int c = 0; c < 3; c++) {
            if (clips[c] < 0) continue;
            ModelAnimation an = anims[clips[c]];
            printf("valid %d %d\n", c, IsModelAnimationValid(model, an));
            float at[4] = { 0, 7.5f, 20, an.keyframeCount + 3.25f };
            char key[64];
            for (int k = 0; k < 4; k++) {
                if (p == 1) {
                    UpdateModelAnimationBones(model, an, at[k]);
                    sprintf(key, "bones %d %g", c, at[k]); matrices(key, model);
                }
                UpdateModelAnimation(model, an, at[k]);
                sprintf(key, "skin %d %g", c, at[k]); vertices(key, model);
            }
        }
        UnloadModel(model);
    }
    UnloadModelAnimations(anims, count);
    CloseWindow();
    return 0;
}
