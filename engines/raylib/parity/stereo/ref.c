// raylib 5.5's VR stereo config and rlgl's stereo state, printed for tools/raylib_parity.py: LoadVrStereoConfig for the Oculus Rift CV1
// (core_vr_simulator's parameters), for the DK2 and with other clip planes; rlgl's stereo flag, and its matrices as set and read back.
#include "raylib.h"
#include "rlgl.h"
#include "raymath.h"
#include "parity.h"
#include <stdio.h>

static void matrix(const char *name, Matrix m) {
    printf("%s matrix %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g %.9g\n", name, m.m0, m.m1, m.m2, m.m3,
        m.m4, m.m5, m.m6, m.m7, m.m8, m.m9, m.m10, m.m11, m.m12, m.m13, m.m14, m.m15);
}

static void pair(const char *name, const char *label, const float *v) { printf("%s %s %.9g %.9g\n", name, label, v[0], v[1]); }

static void config(const char *name, VrStereoConfig c) {
    matrix(name, c.projection[0]);
    matrix(name, c.projection[1]);
    matrix(name, c.viewOffset[0]);
    matrix(name, c.viewOffset[1]);
    pair(name, "leftLensCenter", c.leftLensCenter);
    pair(name, "rightLensCenter", c.rightLensCenter);
    pair(name, "leftScreenCenter", c.leftScreenCenter);
    pair(name, "rightScreenCenter", c.rightScreenCenter);
    pair(name, "distortionScale", c.scale);
    pair(name, "distortionScaleIn", c.scaleIn);
}

static void stereo(const char *name) {
    printf("%s enabled %d\n", name, rlIsStereoRenderEnabled() ? 1 : 0);
    matrix(name, rlGetMatrixProjectionStereo(0));
    matrix(name, rlGetMatrixProjectionStereo(1));
    matrix(name, rlGetMatrixViewOffsetStereo(0));
    matrix(name, rlGetMatrixViewOffsetStereo(1));
}

int main(void) {
    parity_open();
    VrDeviceInfo cv1 = {
        .hResolution = 2160, .vResolution = 1200, .hScreenSize = 0.133793f, .vScreenSize = 0.0669f, .eyeToScreenDistance = 0.041f,
        .lensSeparationDistance = 0.07f, .interpupillaryDistance = 0.07f,
        .lensDistortionValues = { 1.0f, 0.22f, 0.24f, 0.0f }, .chromaAbCorrection = { 0.996f, -0.004f, 1.014f, 0.0f },
    };
    VrDeviceInfo dk2 = {
        .hResolution = 1280, .vResolution = 800, .hScreenSize = 0.14976f, .vScreenSize = 0.09356f, .eyeToScreenDistance = 0.041f,
        .lensSeparationDistance = 0.0635f, .interpupillaryDistance = 0.064f,
        .lensDistortionValues = { 1.0f, 0.22f, 0.24f, 0.02f }, .chromaAbCorrection = { 0.996f, -0.004f, 1.014f, 0.0f },
    };
    stereo("start");
    VrStereoConfig a = LoadVrStereoConfig(cv1);
    config("cv1", a);
    config("dk2", LoadVrStereoConfig(dk2));
    rlSetClipPlanes(0.5, 50);
    config("clipped", LoadVrStereoConfig(cv1));
    rlSetClipPlanes(0.01, 1000);
    BeginVrStereoMode(a);
    stereo("begun");
    EndVrStereoMode();
    stereo("ended");
    rlEnableStereoRender();
    rlSetMatrixProjectionStereo(MatrixTranslate(1, 2, 3), MatrixScale(2, 3, 4));
    rlSetMatrixViewOffsetStereo(MatrixRotateY(0.5f), MatrixPerspective(1, 1.5, 0.1, 10));
    stereo("set");
    rlDisableStereoRender();
    stereo("disabled");
    UnloadVrStereoConfig(a);
    parity_close();
    return 0;
}
