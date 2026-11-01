"""meshes: raylib 5.5's generated meshes (GenMesh*) and their bounds, against helix-ray's, vertex for vertex (GenMeshTangents is 6.2's, in
meshes_62). One list for both sides (shared/gen.py's syntax): height (a 5 x 4 image of varied grays) and cubic (a 4 x 3 map of walls, a
red cell among them) are made in ref.c.in and MeshBits.hx.in."""

CASES = [
    'mesh("poly", GenMeshPoly(5, 2.5));',
    'mesh("plane", GenMeshPlane(3, 4, 3, 2));',
    'mesh("cube", GenMeshCube(1, 2, 3));',
    'mesh("hemisphere", GenMeshHemiSphere(2, 6, 8));',
    'mesh("sphere", GenMeshSphere(1.5, 8, 12));',
    'mesh("hemisphere2", GenMeshHemiSphere(2, 6, 8));',
    'mesh("sphere3", GenMeshSphere(1, 3, 3));',
    'mesh("cylinder", GenMeshCylinder(1, 2, 9));',
    'mesh("cone", GenMeshCone(1.5, 3, 7));',
    'mesh("torus", GenMeshTorus(0.4, 2, 10, 6));',
    'mesh("knot", GenMeshKnot(1.2, 1.5, 12, 6));',
    'mesh("heightmap", GenMeshHeightmap(height, V3(8, 3, 6)));',
    'mesh("cubicmap", GenMeshCubicmap(cubic, V3(1, 1.5, 2)));',
    'box("bounds", GetMeshBoundingBox(GenMeshTorus(0.4, 2, 10, 6)));',
]
