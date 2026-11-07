# A retained-mode scene engine on helix-raylib: a sketch

`Scene3D.hx` is a three.js-shaped scene (`Object3D`, `Mesh3D` with a `Geometry3D` and a `Material3D`, `SkinnedMesh3D`, `Light3D`
nodes, `PerspectiveCamera3D`, `Renderer3D.render(scene, camera)` and `pick`). `Layer2D.hx` is a Pixi-shaped display list (`Container2D`,
`Sprite2D`, `Text2D`, `Graphics2D`). Both draw through `helix.raylib.Raylib`, `Raymath`, `Rlgl` and the extras alone. Each type-checks
on both targets. The brief's bare command stops in the library before the sketch (`sys/thread/Deque.hx: This class is not available on
this target`, no target given), so the check ran as `tools/check_types.py` runs its own: the same command with `-js
build/check_types.js`, and with `-cpp build/check_types-cpp`, four runs, all exit 0. A deliberate error in a copy was reported, so the
check reaches the module. Both files are laid out by the formatter.

## What raylib's API carries as it is

The 3D scene, nearly whole:

- The hierarchy and transforms: raymath. A node's local is `MatrixScale`, `QuaternionToMatrix` and `MatrixTranslate` through
  `MatrixMultiply`, the world its local then the parent's (`Object3D.updateMatrixWorld`).
- The camera: a node writes its world matrix into raylib's `Camera3D`, its near and far through `rlSetClipPlanes`.
- The camera's matrices: `rlGetMatrixModelview` and `rlGetMatrixProjection` inside the mode (Scene3D.hx line 337), where the walk
  runs, so "reading the camera's matrices back" is refuted. Outside it, `GetCameraMatrix` gives the view and the projection is rebuilt
  by raylib's own formula (`MatrixPerspective` with `rlGetCullDistanceNear` and `Far`).
- Culling: the engine's own planes from those two matrices (`Frustum3D`), against each mesh's `GetMeshBoundingBox` taken through its
  world matrix corner by corner.
- The sort: the engine's, on the lists it gathered. Meshes draw in the order `DrawMesh` is called, so "a draw order raylib's batch
  doesn't keep" is refuted for meshes. Immediate 3D shapes wait in rlgl's batch behind meshes called after them, rlgl's own rule, and
  `rlDrawRenderBatchActive` orders them when it matters.
- A material per draw: `DrawMesh(mesh, material, transform)`. Three nodes share one `GenMeshCube` under three `LoadMaterialDefault`
  materials, the PBR shader set on each. "A material or shader per draw without a `Model` copy" is refuted.
- The skinned model: `LoadModelAsync`, `LoadModelAnimationsAsync`, `UpdateModelAnimation` once a frame on the `Model`. Each mesh is a
  `SkinnedMesh3D` drawn by `DrawMesh` with a material of its own (`Material3D.copyOf`, a new `Material` over the same maps), since the
  pose rides on the `Mesh`.
- Lighting: `LoadPbrShader`, `ambient` and `locs[SHADER_LOC_VECTOR_VIEW]` through `SetShaderValue`, each slot through
  `UpdateLightValues` (line 411).
- Transparency: `rlDisableDepthMask` and `BeginBlendMode(BLEND_ALPHA)` around the back-to-front list, `rlEnableDepthMask` after.
- Picking: `GetScreenToWorldRay`, `GetRayCollisionBox` on each world box, `GetRayCollisionMesh` for the boxes hit (lines 429 to 438).
  "Picking without a ray test per mesh" has a door too: ids drawn into a `RenderTexture` and read by `LoadImageFromTextureAsync`, a
  frame late, as a raylib C program would.

The 2D layer, whole:

- The hierarchy with pivots, rotation, scale and alpha: raymath again, a 2D affine in raylib's `Matrix`.
- Each node draws in its own pixels between `rlPushMatrix`, `rlMultMatrixf(MatrixToFloatV(world))` and `rlPopMatrix` (Layer2D.hx line
  186). A pushed matrix flushes nothing, and a quad under it is still one sprite record, so the sheet's sprites through the whole
  hierarchy stay one run: `DrawTexturePro` for a sprite, `DrawTextEx` for text, `DrawRectangleRec` and `DrawCircleV` for the shape, in
  the list's order.
- One batch where raylib allows: a run breaks at a texture, as rlgl's batch starts a draw call at each. Text in a font's atlas starts a new
  run (line 126), as a raylib programmer expects. Shapes join the sheet's run through `SetShapesTexture` with a white texel of the sheet
  (line 178), raylib's own trick.

## What has no door

1. **Stable handles across a reload.** Confirmed. `Skeleton3D.reload` (Scene3D.hx lines 196 to 203): a second `LoadModelAsync` answers
   with a new `Model` whose meshes are new `Mesh` records, so every node holding the old one has to be found and swapped, a shared
   `Geometry3D` the same. raylib's records are the handles, and nothing refills one in place.
2. **More than rlights' four lights.** Confirmed. `Renderer3D.writeLights` (line 385): the shader has `MAX_LIGHTS` slots, so six light
   nodes light with the four nearest, chosen each frame. The count is baked into the shader's source.
3. **A light slot per shader.** Found. `CreateLight` counts the program's lights, as rlights does, so a scene whose materials use two lit
   shaders gets four slots in the first and none in the second, and a removed light's slot is never free again. The sketch fills
   rlights' `Light` records itself by the names `CreateLight` looks up (line 393, `slotOf`), copying `CreateLight`'s insides into the
   engine.
4. **Picking a skinned mesh as posed.** Found. `GetRayCollisionMesh` reads `vertices`, the bind pose. `SkinnedMesh3D.meshToPick` (line 223)
   hands it a scratch `Mesh` whose positions are `animVertices`, a CPU skin of every vertex at the first read after each pose, for a
   model the GPU skins. `GetModelBoundingBoxPosed` costs the same, so the sketch culls by the rest box.

## The extras that would open the doors

Each is an API alone, in `helix.raylib.extras`, named as raylib names the idea it stays close to.

**1. Reloading in place (`extras.Models`, `extras.Textures`).** raylib's `UpdateTexture` and `UpdateMeshBuffer` change what a handle shows
under every holder of it. A reload does the same for a file. `ReloadTextureAsync(texture, fileName, ?done, ?failed)` is its twin for a
texture, replacing the pixels, size and mipmaps under every draw and every material map holding it.

```haxe
/** Asynchronously reads a model's file again into the same `Model`: its meshes' buffers, its materials' maps and its bones replaced
	inside the records every holder has, as `UpdateTexture` changes a texture under every draw of it. See `LoadModelAsync` for loading a
	model.

	The model's `meshes`, `materials` and `meshMaterial` keep their records, so a node holding a mesh or a material draws the new file
	at the next frame. A pose the model held is dropped.

	@param model  The model, from `LoadModelAsync`.
	@param fileName  The file, as the program names it.
	@param done  Optional. Called once the model shows the new file, at a later poll.
	@param failed  Optional. Receives why it couldn't be read, the model unchanged; when omitted, it is logged. */
static function ReloadModelAsync(model:Model, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

**2 and 3. Lights by count and by slot (`extras.Lights`).** A raylib programmer raises `MAX_LIGHTS` by editing rlights.h's define. The
count goes on the load, and a slot on the light. `LoadLightingShaderEx(lightCount)` is the same for the examples' lighting shader.

```haxe
/** Returns helix-raylib's PBR shader built with a number of lights in place of rlights' `MAX_LIGHTS`, as editing the define does. See
	`LoadPbrShader` for the shader with four.

	`CreateLightAt` fills one of its slots.

	@param lightCount  The number of lights, 1 or more.
	@return  The shader, the program's until `UnloadShader`. */
static function LoadPbrShaderEx(lightCount:Int):Shader

/** Makes a light in one slot of a lit shader, as `CreateLight` makes one in the next: its locations are that slot's, and it is set in
	the shader. See `CreateLight` for taking the next slot of the program's count.

	A slot is the shader's, so two lit shaders each have every slot, and another call for a slot fills it again. `UpdateLightValues`
	sends a changed field as for any light.

	@param index  The slot, from 0: below `MAX_LIGHTS` for `LoadLightingShader` and `LoadPbrShader`, below the count given to
	`LoadPbrShaderEx`; past it, a light that is off and sets nothing.
	@param type  `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
	@param position  Where it is.
	@param target  Where it points, for a directional light.
	@param color  Its color.
	@param shader  The lit shader.
	@return  The light. */
static function CreateLightAt(index:Int, type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light
```

**4. A ray test as posed (`extras.Models`).** Beside `GetModelBoundingBoxPosed`, the same idea for the ray.

```haxe
/** Returns where a ray first meets a mesh as its last `UpdateModelAnimation` posed it, moved by a transform: `GetRayCollisionMesh`
	against the vertices where the bones put them, as `GetModelBoundingBoxPosed` bounds them. See `GetRayCollisionMesh` for testing the
	bind pose.

	@param ray  The ray.
	@param mesh  The mesh, with its positions.
	@param transform  The transform.
	@return  The hit. */
static function GetRayCollisionMeshPosed(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision
```

## What this says about the engine

The scene layer should be a thin graph issuing raylib's calls. Everything the two scenes needed in the draw path went through as it is:
`DrawMesh` takes the material and the transform per draw, keeps call order and draws the pose on the mesh, the camera's matrices are
readable inside the mode, and rlgl's pushed matrix carries a 2D hierarchy through one sprite run. The four gaps are beside the draw
path, in loads (a reload refilling a record) and in the lit shader's fixed slots (their count, their owner, a posed ray test), and each
closes with a small raylib-shaped extra. The engine's own code is what three.js's is too: the tree, the world matrices, the planes, the
sort and the light choice, none of which needs a door. What would push toward a draw path of its own is not in these scenes: clipping
under rotation (`BeginScissorMode` is axis-aligned), shadows, and a light's intensity past the color's bytes.
