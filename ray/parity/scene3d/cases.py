"""scene3d: the 3D scene both draw, between scene.c.in's and Main.hx.in's DrawGrid and EndMode3D (shared/gen.py's syntax): camera, checks
(a 64 x 64 checked texture), strip (six points), models (eleven generated meshes, textured), shaded (a knot with tangents, drawn by a shader
of its own) and shader (that shader, reading vertexTangent and vertexTexCoord2) are made there."""

CASES = [
    'DrawCube(V3(-4, 0.5, -3), 1, 1, 1, RED); DrawCubeWires(V3(-4, 0.5, -3), 1.02, 1.02, 1.02, MAROON);',
    'DrawSphere(V3(-2.5, 0.6, -3), 0.6, GREEN); DrawSphereWires(V3(-2.5, 0.6, -3), 0.62, 6, 8, DARKGREEN);',
    'DrawCylinder(V3(-1, 0, -3), 0.3, 0.6, 1.2, 10, SKYBLUE); DrawCylinderWires(V3(-1, 0, -3), 0.3, 0.6, 1.2, 10, DARKBLUE);',
    'DrawCylinder(V3(0.4, 0, -3), 0, 0.5, 1.2, 8, VIOLET);',
    'DrawCapsule(V3(1.6, 0.4, -3), V3(2.4, 1.4, -3), 0.35, 8, 4, ORANGE);',
    'DrawCapsuleWires(V3(1.6, 0.4, -3), V3(2.4, 1.4, -3), 0.36, 8, 4, BROWN);',
    'DrawCylinderEx(V3(3.5, 0, -3), V3(4, 1.5, -2.5), 0.4, 0.1, 8, PURPLE);',
    'DrawCylinderWiresEx(V3(3.5, 0, -3), V3(4, 1.5, -2.5), 0.41, 0.11, 8, DARKPURPLE);',
    'DrawPlane(V3(-4, 0.01, 0), V2(1.5, 1), LIME);',
    'DrawTriangle3D(V3(-2.5, 0, 0), V3(-1.5, 0, 0.5), V3(-2, 1.2, 0.2), GOLD);',
    'DrawTriangleStrip3D(strip, 6, PINK);',
    'DrawCircle3D(V3(0.5, 0.6, 0), 0.5, V3(0, 1, 0), 30, BLACK);',
    'DrawPoint3D(V3(1.3, 0.5, 0), BLACK);',
    'DrawLine3D(V3(1.5, 0, 0), V3(2, 1.2, 0.4), DARKGRAY);',
    'DrawRay(NEW(Ray, V3(2.5, 0.2, 0), V3(0, 0.8, 0.6)), RED);',
    'DrawBoundingBox(NEW(BoundingBox, V3(3, 0, -0.5), V3(4, 0.8, 0.5)), BLUE);',
    'DrawBillboard(camera, checks, V3(4.8, 0.8, 0), 1, WHITE);',
    'DrawBillboardPro(camera, checks, R(8, 8, 32, 24), V3(-5.5, 0.8, 1), V3(0, 1, 0), V2(1.2, 0.9), V2(0.6, 0.45), 25, WHITE);',
    {'c': 'for (int i = 0; i < 11; i++) DrawModel(models[i], V3(-5 + i * 1.1f, (i == 8 ? 0.6f : 0), 2.8f), i == 8 ? 0.35f : 0.9f, WHITE);',
     'hx': 'for (i => m in models) DrawModel(m, V3(-5 + i * 1.1, i == 8 ? 0.6 : 0, 2.8), i == 8 ? 0.35 : 0.9, WHITE);'},
    'DrawModel(shaded, V3(5.5, 0.6, -1), 0.4, WHITE);',
    'BeginShaderMode(shader); DrawCube(V3(5.5, 0.3, 1.5), 0.6, 0.6, 0.6, WHITE); EndShaderMode();',
]
