"""meshes_62: raylib 6.2's GenMeshTangents (#4937: by a mesh's indices, summed at each vertex, made square to its normal) and ExportMesh
(#4496: positions and texture coordinates to 6 places, normals to 4) against helix-ray's. One list for both sides (shared/gen.py's
syntax): height and cubic are made in ref.c.in and MeshBits62.hx.in, as meshes' are, and ExportMesh's text goes to a SaveFileText
callback there that prints it a line at a time, each led by exported."""

CASES = [
    # Without indices, as meshes had them.
    'LET(t, Mesh, GenMeshSphere(1, 4, 5)); GenMeshTangents(OUT(t)); mesh("tangents", t);',
    'LET(k, Mesh, GenMeshKnot(1, 1, 5, 4)); GenMeshTangents(OUT(k)); mesh("knottangents", k);',
    'LET(hm, Mesh, GenMeshHeightmap(height, V3(8, 3, 6))); GenMeshTangents(OUT(hm)); mesh("heightmaptangents", hm);',
    'LET(cm, Mesh, GenMeshCubicmap(cubic, V3(1, 1.5, 2))); GenMeshTangents(OUT(cm)); mesh("cubicmaptangents", cm);',
    # With indices, which 5.5 read three vertices at a time as if there were none.
    'LET(cu, Mesh, GenMeshCube(1, 2, 3)); GenMeshTangents(OUT(cu)); mesh("cubetangents", cu);',
    'LET(pl, Mesh, GenMeshPlane(3, 4, 3, 2)); GenMeshTangents(OUT(pl)); mesh("planetangents", pl);',
    # Texture coordinates all one point: every tangent falls back to one square to the normal.
    {'c': 'Mesh flat = GenMeshCube(1, 1, 1); for (int i = 0; i < flat.vertexCount * 2; i++) flat.texcoords[i] = 0.5f; GenMeshTangents(&flat); mesh("flattangents", flat);',
     'hx': 'var flat = GenMeshCube(1, 1, 1); for (i in 0...flat.vertexCount * 2) flat.texcoords[i] = 0.5; GenMeshTangents(flat); mesh("flattangents", flat);'},
    # Positions and normals that 5.5's 2 and 3 places lost.
    {'c': 'exported = "objcube"; ExportMesh(GenMeshCube(1.234567, 2.5, 3.25), "cube.obj");',
     'hx': 'exported = "objcube"; ExportMeshAsync(GenMeshCube(1.234567, 2.5, 3.25), "cube.obj");'},
    {'c': 'exported = "objknot"; ExportMesh(GenMeshKnot(0.7, 0.9, 4, 3), "knot.obj");',
     'hx': 'exported = "objknot"; ExportMeshAsync(GenMeshKnot(0.7, 0.9, 4, 3), "knot.obj");'},
]
