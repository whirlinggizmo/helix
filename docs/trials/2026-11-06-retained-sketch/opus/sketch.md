## What raylib's API carries as it is

Both files type-check, on a target. The brief's command, with no target, fails for each in Haxe's `sys/thread/Deque.hx`, and so does a
one-line `InitWindow` program. Adding `--js build/sketch.js` or `--cpp build/sketch-cpp` passes both, and a planted error in a copy
fails, so the bodies are typed. Nothing was run, so speed is unmeasured. `build/haxelib` came from `tools/pins.py`'s `use_haxelib`.

3D:

- Transforms: `MatrixMultiply`, `MatrixScale`, `QuaternionToMatrix`, `MatrixTranslate`, world matrices the engine's own.
- Camera: `Camera3D` built from the node's world matrix, then `BeginMode3D`.
- Geometry shared under different materials: `DrawMesh(mesh, material, transform)`.
- Skinning under per-mesh materials: `UpdateModelAnimation` on the model, then `DrawMesh` on each mesh, which keeps the pose.
- Lit drawing: `LoadPbrShader`, `CreateLight`, `UpdateLightValues`.
- Sort state: `rlDisableDepthMask`, `BeginBlendMode`, `rlDisableBackfaceCulling`.
- Bounds: `GetMeshBoundingBox` kept per geometry, `GetModelBoundingBoxPosed` once a frame per model (a CPU skin, a cost, not a gap).
- Picking: `GetScreenToWorldRay`, `GetRayCollisionBox`, `GetRayCollisionMesh`.

Culling is arithmetic over the view-projection (Scene3D.hx:493). raylib has no frustum, and helix-geometry's `Frustum3D` is below.

2D:

- Sprites with pivots and shear: `DrawTextureInstanced` with one matrix (Layer2D.hx:167).
- Text and shapes in a node's space: `rlPushMatrix`, `rlMultMatrixf`, `DrawTextEx`, `DrawRectangleRec`, `DrawCircleV`, `rlPopMatrix`.
  Glyphs stay sprite records under the pushed matrix (`Frame.vertex`).
- One run: `SetShapesTexture` on the sheet's white texel keeps rectangles with sprites. Order is the batch's.

## What has no door

1. **Stable handles across a reload.** Confirmed (Scene3D.hx:360). A load of a file while a load of it lives answers with the kept one,
   and textures are shared by path. No call reads the file anew. `Texture2D.id` is already a table key (`Textures.handle`), but
   nothing public swaps what it points at.
2. **More than four lights on one mesh.** Half refuted. Six in a scene work, because each draw captures the shader's values, so
   four slots are refilled per draw (Scene3D.hx:532). A mesh in reach of all six still loses two. `MAX_LIGHTS` is fixed at build,
   and `CreateLight` counts across the program, so a second lit shader gets lights that are off (Scene3D.hx:474).
3. **Light kinds.** New (Scene3D.hx:543). rlights' light is a color and a direction. A point light's distance, any falloff, a spot
   light and an intensity past the color's 255 have no uniform.
4. **A material's alpha mode and sides.** New (Scene3D.hx:335). A glTF's `alphaMode`, `alphaCutoff` and `doubleSided` never reach
   `Material` (helix-formats' `GltfMaterial` doesn't read them), so the sort can't tell a blended mesh from an opaque one.
5. **A glTF's node tree.** New (Scene3D.hx:330). Node transforms are baked into vertices and `Mesh` has no name, so three.js's
   `getObjectByName` and a rigid part's own node have nothing to hold.
6. **Picking a posed mesh.** New (Scene3D.hx:655). `GetRayCollisionMesh` reads `vertices`, the bind pose. A throwaway `Mesh` around
   `animVertices` works, by hand.
7. **A file's reader through a wrapper.** New (Scene3D.hx:351). `LoadModelAsync` chooses its reader from a constant name, so an
   engine's `load(fileName)` links the OBJ reader in every glTF program, unless the engine's own load is a macro too.
8. **Several textures in a run.** Partly confirmed (Layer2D.hx:57). A run is one texture, so text ends the sheet's run. Merging the font's
   image into the sheet fixes that through public fields. Two sheets interleaved cost a draw per change, where Pixi binds several.

Refuted:

- **Draw order.** A mesh draws ahead of the batch's waiting vertices, so a billboard sorted among meshes would land late, but
  `rlDrawRenderBatchActive` after it holds the order (Scene3D.hx:513).
- **A material or shader per draw without a `Model` copy.** `DrawMesh` takes both.
- **Reading the camera's matrices.** `rlGetMatrixModelview` and `rlGetMatrixProjection` inside `BeginMode3D` (Scene3D.hx:493).
- **Picking without a ray test per mesh.** A box gates the triangles. A faster index is the engine's.

## The extras that would open the doors

```haxe
// extras.Textures, close to UpdateTexture: new pixels behind the same id.
/** Asynchronously reads a texture's file anew and replaces its pixels, keeping its id. See `LoadTextureAsync` for a first load.

	Every holder of the id, each `MaterialMap` too, draws the new pixels from the next frame. A failure leaves the old ones.

	@param texture  The texture, its `width` and `height` updated.
	@param fileName  The file, as the program names it.
	@param done  Optional. Called once it is replaced.
	@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
static function ReloadTextureAsync(texture:Texture2D, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void

// extras.Models, close to UpdateMeshBuffer: new data in the same records.
/** Asynchronously reads a model's file anew and replaces what every load of it draws, keeping its `Mesh` and `Material` records.

	A file with other mesh or material counts fails and leaves the model.

	@param model  The model.
	@param fileName  The file, as the program names it.
	@param done  Optional. Called once it is replaced.
	@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
static function ReloadModelAsync(model:Model, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void

// extras.Lights. rlights' answer to more lights is editing `#define MAX_LIGHTS`, so this is a build define: -D helix-raylib-max-lights=8.
/** Makes a light in one of a lit shader's slots, as `CreateLight` does, without its program-wide count.

	@param index  The slot, from 0 to `MAX_LIGHTS` - 1.
	@param type  `LIGHT_DIRECTIONAL`, `LIGHT_POINT` or `LIGHT_SPOT`.
	@param position  Where it is.
	@param target  Where it points.
	@param color  Its color.
	@param shader  The lit shader.
	@return  The light. */
static function CreateLightAt(index:Int, type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light

// Light, beside rlights' fields, read by `LoadPbrShader` alone. `LoadLightingShader` stays rlights'.
/** A light shining a cone from its position toward its target. */
static inline var LIGHT_SPOT:Int
/** Gets or sets the distance past which nothing is lit, in world units; 0, the default, for no falloff, as rlights' lights. */
public var range:Float
/** Gets or sets what the color is multiplied by, 1 by default. */
public var intensity:Float
/** Gets or sets a spot light's half angle at full strength, in degrees. */
public var innerAngle:Float
/** Gets or sets a spot light's half angle where it reaches nothing, in degrees. */
public var outerAngle:Float

// Material, beside `unlit`, its precedent. Needs helix-formats' GltfMaterial to read them first.
/** Gets or sets how alpha is taken: `ALPHA_OPAQUE`, `ALPHA_MASK` or `ALPHA_BLEND`.

	`LoadModel` sets it from the file. A draw blends as raylib's does, whatever this says. `LoadPbrShader` discards under `ALPHA_MASK`. */
public var alphaMode:Int
/** Gets or sets the alpha under which `ALPHA_MASK` discards, 0.5 by default. */
public var alphaCutoff:Float
/** Gets or sets a value indicating whether the file draws both sides. A draw culls by rlgl's state, whatever this says. */
public var doubleSided:Bool

// Model, close to `bones`, `bindPose` and `meshMaterial`.
/** Gets the number of nodes in the file, 0 for a model of a mesh. */
public var nodeCount:Int
/** Gets the file's nodes, each parent an index here, -1 at the top. */
public var nodes:Null<Array<BoneInfo>>
/** Gets each node's transform in the model as loaded, already in its meshes' vertices. */
public var nodePose:Null<Array<Transform>>
/** Gets the node of each mesh, by its index in `nodes`. */
public var meshNode:Null<Array<Int>>

// extras.Models, beside GetModelBoundingBoxPosed.
/** Returns where a ray first meets a mesh as last posed, at the nearest of its triangles. See `GetRayCollisionMesh` for testing the bind pose.

	Reads `animVertices`, so the first call after a pose moves the vertices on the CPU.

	@param ray  The ray.
	@param mesh  The mesh.
	@param transform  The transform.
	@return  The hit. */
static function GetRayCollisionMeshPosed(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision

// extras.Models, as Conventions' "functions it calls by name". LoadModelObjAsync is its twin.
/** Asynchronously loads a model from a glTF or GLB file through the glTF reader alone, whatever the name. See `LoadModelAsync` for choosing by the name.

	@param fileName  The file, as the program names it.
	@param loaded  Receives the model.
	@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
static function LoadModelGltfAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
```

Gap 8 takes no extra. Several textures to a run would be `Frame`'s, under the same calls, and is worth measuring first.

## What this says about the engine

The scene layer should be a thin graph issuing raylib's calls. Every draw went through `DrawMesh`, `DrawBillboard`,
`DrawTextureInstanced` or text and shape calls under a pushed matrix, and raylib's state calls held the sort. Per-draw capture of
shader values even carried six lights through four slots. No gap asks for a second draw path: gaps 1, 4, 5 and 7 are data the loads
hold back, gaps 2 and 3 are the lit shader's limits, and gap 6 is one test on the wrong vertices. What the sketch can't say is whether that
path stays fast. It allocates a raylib `Matrix` per multiply and makes 20 `SetShaderValue` calls per lit draw, and none of it was timed. The first
measurement decides whether the graph keeps its matrices in helix-math's types, which changes its arithmetic and not its draw path.
