"""points: models and rlgl's batch drawn as points, as both draw them between scene.c.in's and Main.hx.in's DrawGrid and EndMode3D
(shared/gen.py's syntax): an unindexed cloud whose count isn't whole triangles, an indexed fan with a vertex no index names, generated
indexed meshes, point mode with culling on, the batch's triangles as points and its lines as lines, and wire mode replacing point mode.
cloud, fan, plane, cube and sphere are made there."""

CASES = [
    'DrawModelPoints(cloud, V3(0, 0, 0), 1, WHITE);',
    'DrawModelPoints(fan, V3(-3, 0.5, 2), 1.5, WHITE);',
    'DrawModelPointsEx(plane, V3(3, 0.5, 0), V3(1, 0, 0), 30, V3(1.5, 1, 1.5), RED);',
    'DrawModelPoints(cube, V3(0, 1.5, -3), 1, BLUE);',
    'rlEnablePointMode(); DrawModel(sphere, V3(-3, 1, -2), 1, PURPLE); rlDisableWireMode();',
    'rlEnablePointMode(); DrawCube(V3(3, 0.5, 3), 1, 1, 1, ORANGE); DrawLine3D(V3(-4, 0.1, 4), V3(4, 0.1, 4), DARKGREEN); rlDrawRenderBatchActive(); rlDisableWireMode();',
    'rlEnablePointMode(); rlEnableWireMode(); DrawModel(cube, V3(0, 0.5, 3), 1, MAROON); rlDisableWireMode();',
]
