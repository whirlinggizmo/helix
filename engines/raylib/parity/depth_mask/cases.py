"""depth_mask: the depth mask turned off and on within a frame, frame after frame, as a game draws ground decals and sparks, drawn
between scene.c.in's and Main.hx.in's BeginMode3D and EndMode3D (shared/gen.py's syntax): the ground, translucent decals on it and
additive sparks over it with the mask off, then a model and a cube below the ground drawn after them, which the ground hides."""

CASES = [
    'DrawCube(V3(0, -0.05, 0), 8, 0.1, 8, GRAY);',
    'rlDisableDepthMask(); DrawCube(V3(-1, 0.02, 0), 2, 0.01, 2, Fade(RED, 0.5)); DrawCube(V3(1.5, 0.02, 1), 1.5, 0.01, 1.5, Fade(BLUE, 0.5)); rlEnableDepthMask();',
    'BeginBlendMode(BLEND_ADDITIVE); rlDisableDepthMask(); DrawCube(V3(0.5, 1.5, -1), 0.6, 0.6, 0.6, ORANGE); DrawCube(V3(-1.5, 1, 1), 0.5, 0.5, 0.5, PURPLE); rlEnableDepthMask(); EndBlendMode();',
    'DrawModel(cube, V3(0, 0.5, 0), 1, MAROON);',
    'DrawCube(V3(2, -1, -2), 2, 1, 2, GREEN);',
]
