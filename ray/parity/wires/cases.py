"""wires: rlgl's render state across the batch, as both draw it between scene.c.in's and Main.hx.in's DrawGrid and EndMode3D
(shared/gen.py's syntax): models drawn as wires, culling off and on, wire mode, the front face culled, the depth mask and the depth test off.
camera, sphere, cube and torus (generated meshes as models) are made there."""

CASES = [
    'DrawModelWires(sphere, V3(-3, 1, 0), 1, RED);',
    'DrawModelWiresEx(cube, V3(0, 1, 0), V3(0, 1, 0), 30, V3(1.5, 1.5, 1.5), BLUE);',
    'rlDisableBackfaceCulling(); DrawModelWires(torus, V3(3, 1, 0), 1, DARKGREEN); rlEnableBackfaceCulling();',
    'rlEnableWireMode(); DrawSphere(V3(-3, 1, 3), 0.8, PURPLE); DrawCube(V3(0, 0.5, 3), 1, 1, 1, ORANGE); rlDisableWireMode();',
    'rlSetCullFace(RL_CULL_FACE_FRONT); DrawCube(V3(3, 0.5, 3), 1, 1, 1, MAROON); rlSetCullFace(RL_CULL_FACE_BACK);',
    'rlDisableDepthMask(); DrawCube(V3(-3, 0.5, -3), 1.2, 1.2, 1.2, SKYBLUE); rlEnableDepthMask(); DrawSphere(V3(-3, 0.5, -3), 0.5, GOLD);',
    'rlDisableDepthTest(); DrawCube(V3(3, 0.5, -3), 1, 1, 1, LIME); rlEnableDepthTest();',
]
