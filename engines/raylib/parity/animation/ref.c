// raylib 6.2's own skeletal animation, printed for tools/raylib_parity.py: each model's bones, bind pose and skinned meshes, each
// animation's frames, and the bone matrices and skinned vertices UpdateModelAnimationBones, UpdateModelAnimation and UpdateModelAnimationEx give.
#include "raylib.h"
#include "raymath.h"
#include <stdio.h>
#include <string.h>

void UpdateModelAnimationBones(Model model, ModelAnimation anim, float frame);
void UpdateModelAnimationBonesEx(Model model, ModelAnimation animA, float frameA, ModelAnimation animB, float frameB, float blend);

static void tr(const char *key, Transform t) {
    printf("%s %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g\n", key, t.translation.x, t.translation.y, t.translation.z, t.rotation.x,
        t.rotation.y, t.rotation.z, t.rotation.w, t.scale.x, t.scale.y, t.scale.z);
}

static void matrices(const char *key, Model m) {
    for (unsigned int b = 0; b < m.skeleton.boneCount; b++) {
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
    InitWindow(64, 64, "anim");
    const char *files[3] = { "web/greenman.glb", "web/robot.glb", "web/rig.gltf" };
    for (int f = 0; f < 3; f++) {
        char key[128];
        printf("file %d\n", f);
        Model model = LoadModel(files[f]);
        printf("model %d %d %u\n", model.meshCount, model.materialCount, model.skeleton.boneCount);
        for (unsigned int b = 0; b < model.skeleton.boneCount; b++) {
            printf("bone %u %s %d\n", b, model.skeleton.bones[b].name, model.skeleton.bones[b].parent);
            sprintf(key, "bind %u", b); tr(key, model.skeleton.bindPose[b]);
        }
        for (int i = 0; i < model.meshCount; i++) {
            Mesh *m = &model.meshes[i];
            printf("mesh %d %d %d %d %d\n", i, m->vertexCount, m->boneCount, m->boneIndices != NULL, m->boneWeights != NULL);
            if (m->boneIndices) {
                int step = m->vertexCount / 20 + 1;
                for (int v = 0; v < m->vertexCount; v += step)
                    printf("ids %d %d %d %d %d %d %.9g %.9g %.9g %.9g\n", i, v, m->boneIndices[v*4], m->boneIndices[v*4+1], m->boneIndices[v*4+2],
                        m->boneIndices[v*4+3], m->boneWeights[v*4], m->boneWeights[v*4+1], m->boneWeights[v*4+2], m->boneWeights[v*4+3]);
            }
        }
        int count = 0;
        ModelAnimation *anims = LoadModelAnimations(files[f], &count);
        if (anims == NULL) count = 0;
        printf("anims %d\n", count);
        for (int a = 0; a < count; a++) {
            ModelAnimation *an = &anims[a];
            printf("anim %d %s %d %u %d\n", a, an->name, an->keyframeCount, an->boneCount, IsModelAnimationValid(model, *an));
            int frames[5] = { 0, 1, 7, 30, an->keyframeCount - 1 };
            for (int k = 0; k < 5; k++) {
                if (frames[k] >= an->keyframeCount) continue;
                for (unsigned int b = 0; b < an->boneCount; b++) {
                    sprintf(key, "pose %d %d %u", a, frames[k], b); tr(key, an->keyframePoses[frames[k]][b]);
                }
            }
            float at[4] = { 0, 7.5f, 30, an->keyframeCount + 3 };
            for (int k = 0; k < 4; k++) {
                UpdateModelAnimationBones(model, *an, at[k]);
                sprintf(key, "bones %d %g", a, at[k]); matrices(key, model);
            }
        }
        if (count > 0) {
            int a = count > 1 ? 1 : 0;
            float at[2] = { 10, 22.25f };
            for (int k = 0; k < 2; k++) {
                UpdateModelAnimation(model, anims[a], at[k]);
                sprintf(key, "skin %d %g", a, at[k]); vertices(key, model);
                sprintf(key, "skinbones %d %g", a, at[k]); matrices(key, model);
            }
            int b = count > 2 ? 2 : 0;
            UpdateModelAnimationEx(model, anims[a], 5.5f, anims[b], 12.25f, 0.3f);
            sprintf(key, "ex %d %d", a, b); vertices(key, model);
            sprintf(key, "exbones %d %d", a, b); matrices(key, model);
            UpdateModelAnimationEx(model, anims[a], anims[a].keyframeCount + 2.5f, anims[b], 3.75f, 0.8f);
            sprintf(key, "exwrap %d %d", a, b); matrices(key, model);
        }
        UnloadModelAnimations(anims, count);
        UnloadModel(model);
    }
    CloseWindow();
    return 0;
}
