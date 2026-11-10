# rmodels: 3D shapes, models, meshes and rays

[Back to the library](README.md)


```haxe
static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void
static function DrawPoint3D(position:Vector3, color:Color):Void
static function DrawCircle3D(center:Vector3, radius:Float, rotationAxis:Vector3, rotationAngle:Float, color:Color):Void
static function DrawTriangle3D(v1:Vector3, v2:Vector3, v3:Vector3, color:Color):Void
static function DrawTriangleStrip3D(points:Array<Vector3>, pointCount:Int, color:Color):Void
static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeV(position:Vector3, size:Vector3, color:Color):Void
static function DrawCubeWires(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void
static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void
static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawCylinder(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void
static function DrawCylinderEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void
static function DrawCylinderWires(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void
static function DrawCylinderWiresEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void
static function DrawCapsule(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void
static function DrawCapsuleWires(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void
static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void
static function DrawRay(ray:Ray, color:Color):Void
static function DrawGrid(slices:Int, spacing:Float):Void
static function DrawBoundingBox(box:BoundingBox, color:Color):Void
static function DrawBillboard(camera:Camera, texture:Texture2D, position:Vector3, scale:Float, tint:Color):Void
static function DrawBillboardRec(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, size:Vector2, tint:Color):Void
static function DrawBillboardPro(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, up:Vector3, size:Vector2, origin:Vector2, rotation:Float, tint:Color):Void
static function LoadModelFromMesh(mesh:Mesh):Model
static function IsModelValid(model:Model):Bool
static function UnloadModel(model:Model):Void
static function DrawModel(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawModelWires(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelWiresEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawModelPoints(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelPointsEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void
static function DrawMeshInstanced(mesh:Mesh, material:Material, transforms:Array<Matrix>, instances:Int):Void
static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void
static function UpdateMeshBuffer(mesh:Mesh, index:Int, data:Dynamic, dataSize:Int, offset:Int):Void
static function UnloadMesh(mesh:Mesh):Void
static function GenMeshPoly(sides:Int, radius:Float):Mesh
static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh
static function GenMeshCube(width:Float, height:Float, length:Float):Mesh
static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh
static function GenMeshHemiSphere(radius:Float, rings:Int, slices:Int):Mesh
static function GenMeshCylinder(radius:Float, height:Float, slices:Int):Mesh
static function GenMeshCone(radius:Float, height:Float, slices:Int):Mesh
static function GenMeshTorus(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh
static function GenMeshKnot(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh
static function GenMeshHeightmap(heightmap:Image, size:Vector3):Mesh
static function GenMeshCubicmap(cubicmap:Image, cubeSize:Vector3):Mesh
static function GenMeshTangents(mesh:Mesh):Void
static function UpdateModelAnimationBones(model:Model, anim:ModelAnimation, frame:Float):Void
static function UpdateModelAnimation(model:Model, anim:ModelAnimation, frame:Float):Void
static function UpdateModelAnimationEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void
static function UnloadModelAnimation(anim:ModelAnimation):Void
static function UnloadModelAnimations(animations:Array<ModelAnimation>, animCount:Int):Void
static function IsModelAnimationValid(model:Model, anim:ModelAnimation):Bool
static function LoadMaterialDefault():Material
static function IsMaterialValid(material:Material):Bool
static function UnloadMaterial(material:Material):Void
static function SetMaterialTexture(material:Material, mapType:Int, texture:Texture2D):Void
static function SetModelMeshMaterial(model:Model, meshId:Int, materialId:Int):Void
static function GetMeshBoundingBox(mesh:Mesh):BoundingBox
static function GetModelBoundingBox(model:Model):BoundingBox
static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool
static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool
static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool
static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision
static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision
static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision
static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision
static function GetRayCollisionQuad(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3, p4:Vector3):RayCollision
```

- `DrawLine3D`: Draws a line in 3D.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawPoint3D`: Draws a point in 3D as a line 0.1 long toward +z, as raylib's does.
  - `position`: The point.
  - `color`: The color.
- `DrawCircle3D`: Draws a circle's outline in 3D as 36 lines, on the XY plane turned about an axis.
  - `center`: Its center.
  - `radius`: Its radius.
  - `rotationAxis`: The axis of the turn.
  - `rotationAngle`: The angle, in degrees.
  - `color`: The color.
- `DrawTriangle3D`: Draws a filled triangle in 3D, its corners counterclockwise from the side it faces.
  - `v1`: A corner.
  - `v2`: The next.
  - `v3`: The last.
  - `color`: The color.
- `DrawTriangleStrip3D`: Draws a strip of triangles in 3D, each point after the second making a triangle with the two before it.
  - `points`: The points.
  - `pointCount`: How many of them. Fewer than 3 draws nothing.
  - `color`: The color.
- `DrawCube`: Draws a filled box, each face with its normal.
  - `position`: Its center.
  - `width`: Its size along x.
  - `height`: Along y.
  - `length`: Along z.
  - `color`: The color.
- `DrawCubeV`: Draws a filled box.
  - `position`: Its center.
  - `size`: Its size.
  - `color`: The color.
- `DrawCubeWires`: Draws a box's edges.
  - `position`: Its center.
  - `width`: Its size along x.
  - `height`: Along y.
  - `length`: Along z.
  - `color`: The color.
- `DrawCubeWiresV`: Draws a box's edges.
  - `position`: Its center.
  - `size`: Its size.
  - `color`: The color.
- `DrawSphere`: Draws a filled sphere of 16 rings and 16 slices. See `DrawSphereEx` for choosing the rings and slices.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `color`: The color.
- `DrawSphereEx`: Draws a filled sphere of `rings` bands and `slices` slices from the top, each vertex with its normal.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Bands top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawSphereWires`: Draws a sphere's wires, `rings` bands and `slices` slices from the top, with each face's longitude, latitude and diagonal lines.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Bands top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawCylinder`: Draws a filled cylinder standing on the XZ plane, or a cone when its top's radius is 0.
  - `position`: Its base's center.
  - `radiusTop`: Its top's radius.
  - `radiusBottom`: Its base's.
  - `height`: Its height.
  - `sides`: Its sides, raised to 3 when fewer.
  - `color`: The color.
- `DrawCylinderEx`: Draws a filled cylinder from one point to another, or a cone when a radius is 0.
  - `startPos`: Its base's center.
  - `endPos`: Its top's.
  - `startRadius`: Its base's radius.
  - `endRadius`: Its top's.
  - `sides`: Its sides, raised to 3 when fewer.
  - `color`: The color.
- `DrawCylinderWires`: Draws a cylinder's wires standing on the XZ plane, or a cone's when its top's radius is 0.
  - `position`: Its base's center.
  - `radiusTop`: Its top's radius.
  - `radiusBottom`: Its base's.
  - `height`: Its height.
  - `sides`: Its sides, raised to 3 when fewer.
  - `color`: The color.
- `DrawCylinderWiresEx`: Draws a cylinder's wires from one point to another, or a cone's when a radius is 0.
  - `startPos`: Its base's center.
  - `endPos`: Its top's.
  - `startRadius`: Its base's radius.
  - `endRadius`: Its top's.
  - `sides`: Its sides, raised to 3 when fewer.
  - `color`: The color.
- `DrawCapsule`: Draws a filled capsule, a cylinder with half a sphere on each end, the two points their centers.
  - `startPos`: One end's center.
  - `endPos`: The other's.
  - `radius`: Its radius.
  - `slices`: Slices around, raised to 3 when fewer.
  - `rings`: Rings in each half sphere, raised to 1 when fewer.
  - `color`: The color.
- `DrawCapsuleWires`: Draws a capsule's wires, a cylinder with half a sphere on each end, the two points their centers.
  - `startPos`: One end's center.
  - `endPos`: The other's.
  - `radius`: Its radius.
  - `slices`: Slices around, raised to 3 when fewer.
  - `rings`: Rings in each half sphere, raised to 1 when fewer.
  - `color`: The color.
- `DrawPlane`: Draws a flat rectangle on the XZ plane, facing up.
  - `centerPos`: Its center.
  - `size`: Its size along x and z.
  - `color`: The color.
- `DrawRay`: Draws a ray as a line 10000 long.
  - `ray`: The ray.
  - `color`: The color.
- `DrawGrid`: Draws a grid on the XZ plane centered on the origin, its center lines darker.
  - `slices`: The lines each way.
  - `spacing`: The space between them.
- `DrawBoundingBox`: Draws a bounding box's edges.
  - `box`: The box.
  - `color`: The color.
- `DrawBillboard`: Draws a texture facing the camera and turning about y alone, `scale` high in the texture's own proportions.
  - `camera`: The camera.
  - `texture`: The texture.
  - `position`: Its center.
  - `scale`: Its height.
  - `tint`: The tint.
- `DrawBillboardRec`: Draws part of a texture facing the camera, turning about y alone.
  - `camera`: The camera.
  - `texture`: The texture.
  - `source`: The part, in its pixels.
  - `position`: Its center.
  - `size`: Its size; a negative one flips it.
  - `tint`: The tint.
- `DrawBillboardPro`: Draws part of a texture facing the camera's right and an up of its own, turned about the way it faces.
  - `camera`: The camera.
  - `texture`: The texture.
  - `source`: The part, in its pixels.
  - `position`: Where its origin is.
  - `up`: Its up.
  - `size`: Its size; a negative one flips it.
  - `origin`: The point of it at the position, from its bottom left, in the size's units.
  - `rotation`: How far it turns about its origin, in degrees.
  - `tint`: The tint.
- `LoadModelFromMesh`: Returns a model of one mesh with the default material.
  - `mesh`: The mesh.
  - returns: The model.

  The model takes over the program's hold on the mesh. `UnloadModel` frees the mesh, and a later `UnloadMesh` does nothing.

  The model has no bones. Once the program sets its `bones`, `bindPose` and `boneCount`, and the mesh's `boneIds` and `boneWeights`, `UpdateModelAnimation` and the other animation calls pose it as they pose a loaded model.
- `IsModelValid`: Returns whether a model has meshes.
  - `model`: The model.
  - returns: True when the model has meshes.
- `UnloadModel`: Lets go of a model's meshes and materials, freeing each that nothing else holds.
  - `model`: The model.

  Frees a mesh's GPU buffers, and a material's maps' textures and its shader, once nothing else holds them. Another load of the same file, another model and the program each hold them.

  Leaves the default shader and texture.

  Copying a texture or shader out of a material (`var t = map.texture`) doesn't hold it, so the copy is freed with the model.

  Frees a material or mesh shared between models once, when the last model lets go of it.

  Leaves the model empty, so unloading it again does nothing.
- `DrawModel`: Draws a model at a position and a scale, its materials' colors times a tint.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.
- `DrawModelEx`: Draws a model scaled, turned about an axis and moved, after its own transform.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.
- `DrawModelWires`: Draws a model's triangles as their edges, as `DrawModel` places it, through rlgl's wire mode.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.
- `DrawModelWiresEx`: Draws a model's triangles as their edges, as `DrawModelEx` places it, through rlgl's wire mode.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.
- `DrawModelPoints`: Draws a model's triangles' corners as points one pixel each, placed as `DrawModel` places a model.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.

  Draws a point at each index of a mesh's triangles, or at each vertex when the mesh has no indices. A cloud of points is a mesh of vertices alone.

  Turns backface culling off through rlgl's point mode and on after, as raylib leaves it.
- `DrawModelPointsEx`: Draws a model's triangles' corners as points one pixel each, placed as `DrawModelEx` places a model.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.

  Draws a point at each index of a mesh's triangles, or at each vertex when the mesh has no indices.

  Turns backface culling off through rlgl's point mode and on after, as raylib leaves it.
- `DrawMesh`: Draws a mesh with a material and a transform.
  - `mesh`: The mesh.
  - `material`: The material.
  - `transform`: The transform.

  Binds the material's maps as raylib does:

  - The first three at `texture0` to `texture2`. - Each other map with a texture at the sampler `shader.locs[SHADER_LOC_MAP_DIFFUSE + index]` names, or at a sampler set to the map's index with `SetShaderValue`. raylib's skybox sets its `samplerCube` to `MATERIAL_MAP_CUBEMAP`.

  Binds a cubemap (`LoadTextureCubemap`) to a `samplerCube` for `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` and `MATERIAL_MAP_PREFILTER`, and a 2D texture to a `sampler2D` for the rest. A texture of the other kind binds nothing.
- `DrawMeshInstanced`: Draws a mesh many times in one draw, each instance placed by its own transform, as raylib 5.5's does.
  - `mesh`: The mesh.
  - `material`: Its material: the shader, the diffuse color and the textures.
  - `transforms`: The instances' transforms.
  - `instances`: How many instances, at most the transforms given.

  The material's shader takes each transform as a `mat4` attribute at `shader.locs[SHADER_LOC_MATRIX_MODEL]` and applies it itself. raylib's instancing example sets that location with `GetShaderLocationAttrib(shader, "instanceTransform")`.

  A mesh posed by `UpdateModelAnimation` draws in that pose through a shader that includes `<helix/raylib/shaders/skinning.glsl>`.

  Draws nothing, with a warning, when the shader has no `mat4` attribute there.

  Sets `mvp` to the camera's alone and `matNormal` to the identity.

  Sends the mesh's attributes and the transforms as a buffer each, eight at most. A shader reading every one of raylib's attributes besides the transforms can't be drawn.
- `UploadMesh`: Sends a mesh's vertices to the GPU, so the mesh can be drawn.
  - `mesh`: The mesh.
  - `isDynamic`: Whether the mesh will change. Ignored, as `UpdateMeshBuffer` can change any mesh here. raylib names it `dynamic`, a Haxe keyword.

  A mesh not sent this way is sent when first drawn, as `LoadModelAsync`'s meshes and the `GenMesh*` meshes are.

  An attribute the mesh has no array for reads a default in a shader:

  - Texture coordinates 0, 0. - Normals 0, 0, 1. - Colors white. - Tangents 1, 0, 0, 1. - Second texture coordinates, bone ids and bone weights 0.
- `UpdateMeshBuffer`: Changes part of one of a mesh's buffers on the GPU, leaving the mesh's own arrays unchanged, as raylib's does.
  - `mesh`: The mesh, uploaded by `UploadMesh` or drawn once. One that isn't changes nothing.
  - `index`: The buffer: 0 positions, 1 texture coordinates, 2 normals, 3 colors, 4 tangents, 5 second texture coordinates, 6 indices. One the mesh has no array for changes nothing.
  - `data`: The new values: raylib's bytes (`haxe.io.Bytes`: 32-bit floats, colors a byte each, indices 16-bit), or an array of the numbers (colors 0 to 255).
  - `dataSize`: How many bytes they are, as raylib counts them.
  - `offset`: Where they go in the buffer, in raylib's bytes.

  Draws asked for before the call keep the old values, and those after see the change.
- `UnloadMesh`: Lets go of the program's hold on a mesh, freeing its GPU buffers unless a model still holds it.
  - `mesh`: The mesh.

  Does nothing for a mesh given to `LoadModelFromMesh`, which its model frees, or for one already freed.
- `GenMeshPoly`: Returns a flat regular polygon mesh on the XZ plane, facing up and centered on the origin.
  - `sides`: Its sides. Fewer than 3 make an empty mesh.
  - `radius`: Its corners' distance from the center.
  - returns: The mesh.

  Makes a triangle a side, with no indices and texture coordinates 0.
- `GenMeshPlane`: Returns a flat mesh on the XZ plane, facing up and centered on the origin, a grid of vertices shared by its cells' triangles.
  - `width`: Along x.
  - `length`: Along z.
  - `resX`: Cells along x.
  - `resZ`: Cells along z.
  - returns: The mesh.
- `GenMeshCube`: Returns a box mesh centered on the origin, four vertices a face, each face textured by the whole texture.
  - `width`: Along x.
  - `height`: Along y.
  - `length`: Along z.
  - returns: The mesh.
- `GenMeshSphere`: Returns a sphere mesh centered on the origin with its poles on z, as raylib's (par_shapes') does.
  - `radius`: Its radius.
  - `rings`: Rings pole to pole, at least 3.
  - `slices`: Slices around, at least 3.
  - returns: The mesh, empty for fewer rings or slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshHemiSphere`: Returns a half sphere mesh, open at its base, on the +y side of the origin.
  - `radius`: Its radius. A negative one is 0.
  - `rings`: Rings from the pole, at least 3.
  - `slices`: Slices around, at least 3.
  - returns: The mesh, empty for fewer rings or slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshCylinder`: Returns a closed cylinder mesh standing on the XZ plane at the origin.
  - `radius`: Its radius.
  - `height`: Its height.
  - `slices`: Slices around, at least 3.
  - returns: The mesh, empty for fewer slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshCone`: Returns a closed cone mesh standing on the XZ plane at the origin.
  - `radius`: Its base's radius.
  - `height`: Its height.
  - `slices`: Slices around, at least 3.
  - returns: The mesh, empty for fewer slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshTorus`: Returns a torus mesh on the XY plane, centered on the origin.
  - `radius`: The tube's radius against the ring's, clamped to 0.1 to 1.
  - `size`: The torus's width, out to the ring's middle on each side.
  - `radSeg`: Slices around the ring, at least 3.
  - `sides`: Slices around the tube, at least 3.
  - returns: The mesh, empty for fewer slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshKnot`: Returns a trefoil knot mesh centered on the origin.
  - `radius`: The tube's radius in tenths, clamped to 0.5 to 3.
  - `size`: The knot's scale.
  - `radSeg`: Slices along the knot, at least 3.
  - `sides`: Slices around the tube, at least 3.
  - returns: The mesh, empty for fewer slices.

  Makes three vertices a triangle, with no indices.
- `GenMeshHeightmap`: Returns a terrain mesh from an image, a vertex a pixel from the origin along +x and +z, each the height of its pixel's gray.
  - `heightmap`: The image.
  - `size`: The terrain's size: x and z across the image, y the height of white.
  - returns: The mesh.

  Takes a pixel's gray as its red, green and blue averaged.

  Makes two triangles a cell, each with a flat normal, and three vertices a triangle, with no indices.
- `GenMeshCubicmap`: Returns a maze mesh of cubes from an image, a cube a pixel, each centered on its pixel's place from the origin.
  - `cubicmap`: The image.
  - `cubeSize`: A cube's size: x along the image's width, z along its height, y the walls' height.
  - returns: The mesh.

  Makes a white pixel a wall, with faces where its neighbors are black or the map ends, and a top and a bottom.

  Makes a black pixel a floor and a ceiling, facing in.

  Splits the texture in four:

  - Walls' right and front faces from its top left. - Walls' left and back faces from its top right. - Tops from its bottom left. - Bottoms from its bottom right.

  Makes three vertices a triangle, with no indices.
- `GenMeshTangents`: Computes a mesh's tangents from its positions, texture coordinates and normals.
  - `mesh`: The mesh. One without positions, texture coordinates or normals is unchanged.

  Sums each triangle's direction of u at each of its vertices, by its indices when the mesh has them. Then makes each sum square to the vertex's normal and of length 1, with w the side the summed direction of v is on.

  Gives a vertex whose tangent comes out near length 0, or along its normal, a tangent square to the normal: x when the normal is mostly z, else (-y, x, 0) of the normal, with w 1.
- `UpdateModelAnimationBones`: Poses a model's bones by a frame of an animation, as raylib 6.2's does, leaving its vertices where they are. See `UpdateModelAnimation` for posing the meshes under any shader.
  - `model`: The model.
  - `anim`: The animation, of the model's skeleton (`IsModelAnimationValid`).
  - `frame`: The frame, from 0.

  Mixes the frame's whole part and the next by its fraction, each wrapped to the animation's frames. A whole frame poses that frame, as in raylib 5.5.

  Writes each bone's matrix, its bind pose's inverse then the pose, to each mesh's `boneMatrices`.

  A shader of the program's own that reads the bones draws the pose. Such a shader reads raylib's `skinning.vs`'s `boneMatrices`, or includes `<helix/raylib/shaders/skinning.glsl>`.

  Under raylib's default shader, the lit and PBR ones, or a shader without the bones, the mesh draws unposed, as raylib's does.

  Does nothing for a model without bones or an animation without frames.
- `UpdateModelAnimation`: Poses a model by a frame of an animation, as raylib 6.2's does, each skinned mesh drawing in that pose until the next call.
  - `model`: The model.
  - `anim`: The animation, of the model's skeleton.
  - `frame`: The frame, from 0, fractional.

  Poses the bones as `UpdateModelAnimationBones` does.

  Draws asked for before the call keep the pose they were asked with, so one model can be posed and drawn many times in a frame.

  Moves a mesh by its material's shader:

  - Under raylib's default shader, on the GPU by a skinned version of that shader. - Under a shader of the program's own that declares the bone inputs as raylib's `skinning.vs` does (`vertexBoneIds`, `vertexBoneWeights` and `uniform mat4 boneMatrices[N]`), or includes `<helix/raylib/shaders/skinning.glsl>`, on the GPU by that shader. - Under a shader of the program's own without them, on the CPU, every vertex each call.

  Moving on the CPU is slow for many vertices or many models. A lighting shader of the program's own draws an animated model fastest when it declares `skinning.vs`'s inputs or includes `skinning.glsl`.

  `skinning.glsl` declares:

  - The bone inputs and the frame's bone palette. - `mat4 helixSkin()`, the vertex's skin matrix, as in `gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);`. - `vec3 helixSkinNormal(vec3 normal)`, a normal moved as raylib moves one.

  `animVertices` and `animNormals` hold the moved positions and normals, worked out on the CPU when first read. Each normal is moved by its bones' matrices inverted and transposed, not normalized.

  Leaves a mesh whose shader moves it as raylib leaves it.
- `UpdateModelAnimationEx`: Poses a model by two animations mixed by a blend, raylib 6.2's own call.
  - `model`: The model.
  - `animA`: The first animation.
  - `frameA`: Its frame, fractional.
  - `animB`: The second animation.
  - `frameB`: Its frame, fractional.
  - `blend`: How much of the second: 0 the first alone, 1 the second alone.

  Takes each animation at its frame as `UpdateModelAnimation` takes one, then mixes the two by the blend.

  Moves the bones and the vertices on the GPU or the CPU as `UpdateModelAnimation` does.

  Wraps a frame to its animation's frames before taking its fraction, as raylib's does, so a frame past the last holds the frame it wrapped to.

  Does nothing for a blend outside 0 to 1.
- `UnloadModelAnimation`: Frees an animation's frames, letting go of its poses and bones and setting its counts to 0.
  - `anim`: The animation.
- `UnloadModelAnimations`: Frees animations' frames, each as `UnloadModelAnimation` frees one.
  - `animations`: The animations.
  - `animCount`: How many of them.
- `IsModelAnimationValid`: Returns whether an animation moves a model's skeleton, by whether they have as many bones, as raylib 6.2 checks.
  - `model`: The model.
  - `anim`: The animation.
  - returns: True when their bone counts match.
- `LoadMaterialDefault`: Returns raylib's default material, which the program holds until `UnloadMaterial`.
  - returns: The material.

  The material has:

  - The default shader. - A diffuse map of raylib's default texture, a 1x1 white pixel. - White diffuse and specular colors. - Empty other maps.

  A model the material is put in holds it too.
- `IsMaterialValid`: Returns whether a material has maps and a shader, so it can draw.
  - `material`: The material.
  - returns: True when its maps aren't null and its shader's id is above 0.
- `UnloadMaterial`: Lets go of a material, freeing what nothing else holds.
  - `material`: The material.

  Releases the program's hold from `LoadMaterialDefault`, or for a model's material the model's.

  Once nothing else holds the material, unloads its shader unless it is the default one, and releases its maps' textures.

  Frees each texture once nothing else holds it. Leaves a texture the program still holds, or one another load of its file shares.

  Releasing the material again does nothing.
- `SetMaterialTexture`: Sets a texture on a material's map, which holds it from then on (`MaterialMap.texture`).
  - `material`: The material.
  - `mapType`: The map (`MATERIAL_MAP_*`).
  - `texture`: The texture.
- `SetModelMeshMaterial`: Sets the material a model's mesh draws with.
  - `model`: The model.
  - `meshId`: The mesh.
  - `materialId`: The material.
- `GetMeshBoundingBox`: Returns a mesh's bounds, the least and the most of its positions.
  - `mesh`: The mesh.
  - returns: The box.

  Returns a box of zeros for a mesh without positions.
- `GetModelBoundingBox`: Returns a model's bounds, its meshes' boxes together with the least and most corners moved by its transform, as raylib's does.
  - `model`: The model.
  - returns: The box.

  A turned model's box is not its bounds. Transforming its eight corners gives those.
- `CheckCollisionBoxes`: Returns whether two boxes overlap, touching included.
  - `box1`: One.
  - `box2`: The other.
  - returns: True when they overlap.
- `CheckCollisionSpheres`: Returns whether two spheres overlap, touching included.
  - `center1`: One's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionBoxSphere`: Returns whether a box and a sphere overlap, touching included.
  - `box`: The box.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: True when they overlap.
- `GetRayCollisionSphere`: Returns where a ray meets a sphere, the near side from outside and the far side from inside.
  - `ray`: The ray.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: The hit.

  From inside, the hit's normal points in.

  Misses a sphere wholly behind the ray. On a miss the point, normal and distance are 0.

  Expects the ray's direction to be of length 1.
- `GetRayCollisionBox`: Returns where a ray meets a box, as raylib's does.
  - `ray`: The ray.
  - `box`: The box.
  - returns: The hit.

  From inside the box, returns the way out, its distance negative and its normal pointing in.

  Sets the hit's point, distance and normal even on a miss.
- `GetRayCollisionMesh`: Returns where a ray first meets a mesh moved by a transform, at the nearest of the mesh's triangles.
  - `ray`: The ray.
  - `mesh`: The mesh, with its positions.
  - `transform`: The transform.
  - returns: The hit.
- `GetRayCollisionTriangle`: Returns where a ray meets a triangle from either side, its normal that of the corners taken counterclockwise.
  - `ray`: The ray.
  - `p1`: A corner.
  - `p2`: The next.
  - `p3`: The last.
  - returns: The hit.

  Uses Möller and Trumbore's test, as raylib's does.
- `GetRayCollisionQuad`: Returns where a ray meets a quad, as two triangles: p1, p2 and p4, then p2, p3 and p4.
  - `ray`: The ray.
  - `p1`: A corner.
  - `p2`: The next, counterclockwise.
  - `p3`: The next.
  - `p4`: The last.
  - returns: The hit.
