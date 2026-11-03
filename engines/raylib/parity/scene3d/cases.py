"""scene3d: raylib 5.5's 3D scene both draw, between scene.c.in's and Main.hx.in's DrawGrid and EndMode3D (shared/gen.py's syntax); the
spheres, capsules, billboards and a knot given tangents by GenMeshTangents are 6.2's (scene3d_62). camera, checks (a 64 x 64 checked
texture), strip (six points), models (eleven generated meshes, textured) and shader (reading vertexTangent and vertexTexCoord2) are made
there."""

CASES = [
    'DrawCube(V3(-4, 0.5, -3), 1, 1, 1, RED); DrawCubeWires(V3(-4, 0.5, -3), 1.02, 1.02, 1.02, MAROON);',
    'DrawCylinder(V3(-1, 0, -3), 0.3, 0.6, 1.2, 10, SKYBLUE); DrawCylinderWires(V3(-1, 0, -3), 0.3, 0.6, 1.2, 10, DARKBLUE);',
    'DrawCylinder(V3(0.4, 0, -3), 0, 0.5, 1.2, 8, VIOLET);',
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
    {'c': 'for (int i = 0; i < 11; i++) DrawModel(models[i], V3(-5 + i * 1.1f, (i == 8 ? 0.6f : 0), 2.8f), i == 8 ? 0.35f : 0.9f, WHITE);',
     'hx': 'for (i => m in models) DrawModel(m, V3(-5 + i * 1.1, i == 8 ? 0.6 : 0, 2.8), i == 8 ? 0.35 : 0.9, WHITE);'},
    'BeginShaderMode(shader); DrawCube(V3(5.5, 0.3, 1.5), 0.6, 0.6, 0.6, WHITE); EndShaderMode();',
]
