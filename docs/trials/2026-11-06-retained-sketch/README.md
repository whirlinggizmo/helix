# A retained-mode engine on helix-raylib: the sketch

What a retained-mode engine wearing three.js's shape (3D) and a display list's (2D, Pixi's) needs that raylib's API has no door for
(DECISIONS 53). The same brief went to Opus and Fable, blind, in worktrees of their own. Their work is in [opus/](opus) and
[fable/](fable) as delivered. This page is the best of the two, read against the code, and the one to work from.

Both sketches type-check on JS and C++. Neither was run. A small program of the graph was, below. Every extra is an API proposal, unbuilt.

## The answer

The scene layer is a thin graph issuing raylib's calls, with no draw path of its own. `DrawMesh` takes a material and a transform per
draw, keeps call order and draws the pose on the mesh. rlgl's matrix stack carries a 2D hierarchy through one sprite run. What is the
engine's own is what three.js's is too: the tree, the world matrices, the frustum planes, the sort and the choice of lights.

The cost is measured, and holds if the graph keeps its matrices in helix-math's types.

The program ([timing/Main.hx](timing/Main.hx), raw lines in [timing/runs.jsonl](timing/runs.jsonl)) draws the robots contender's scene six
ways: `direct` as the contender; `graph`, a tree of root, groups of 10, robots and 19 mesh nodes a robot, world matrices by raymath each
frame, six-plane culling, a depth sort and `DrawMesh`; `graph-math` the same through helix-math's `Matrix3D`, written in place; and each
under `LoadPbrShader`, the graph's with six scene lights and the nearest four refilled per robot. Mean ms a frame, median of three runs of
600 frames, 2026-11-07 on coinspinner, Performance profile, every robot in view:

| Mode | Page 50 | Page 200 | Page 400 | SDL_GPU 50 | SDL_GPU 200 | SDL_GPU 400 |
|---|---|---|---|---|---|---|
| `direct` | 1.98 | 7.90 | 15.04 | 1.60 | 6.35 | 13.75 |
| `graph` | 2.37 | 9.69 | 19.55 | 2.49 | 9.95 | 19.66 |
| `graph-math` | 2.07 | 7.97 | 16.00 | 1.74 | 7.10 | 14.90 |
| `direct-pbr` | 2.64 | 10.22 | 21.07 | 2.32 | 9.88 | 22.58 |
| `graph-pbr` | 3.38 | 12.97 | 26.40 | 3.84 | 16.04 | 32.67 |
| `graph-math-pbr` | 2.93 | 11.74 | 23.80 | 2.97 | 12.57 | 28.50 |

raylib C held steady through it (GPU skinning, page 400: 16.73 before, 15.79 after), and `direct` matched helix-raylib's own contender.
At 400 robots, raymath's allocating matrices cost 30% on the page and 43% natively. helix-math's cost 6% and 8%, tree, cull and sort
included. Under the PBR shader the graph adds 13% on the page and 26% natively over `direct-pbr`, mostly the 20 `SetShaderValue` calls a
robot. `LoadPbrShader` itself adds 40% on the page over `direct`, and the robots fill little of the screen. Every robot passes the cull
here, so culling costs and saves nothing. The lights were near-white with no falloff, so those frames are over-lit, which doesn't change
the shader's work. Not timed: GL natively, a page on a phone, and a scene the cull thins.

## Carried by raylib's API as it is

- **Transforms:** `MatrixMultiply`, `MatrixScale`, `QuaternionToMatrix`, `MatrixTranslate`.
- **Camera:** `Camera3D` from the node's world matrix, `rlSetClipPlanes`, and `rlGetMatrixModelview` and `rlGetMatrixProjection` inside
  `BeginMode3D`.
- **A material per draw:** `DrawMesh(mesh, material, transform)`, for shared geometry and for a skinned mesh, whose pose rides on the
  `Mesh`.
- **Sort state:** `rlDisableDepthMask`, `BeginBlendMode`, `rlDisableBackfaceCulling`.
- **Draw order:** meshes draw in call order. `rlDrawRenderBatchActive` places immediate shapes among them.
- **Lights past four in a scene:** each draw captures the shader's values, so the slots are refilled per mesh (see gap 2).
- **Picking:** `GetScreenToWorldRay`, `GetRayCollisionBox` as a gate, `GetRayCollisionMesh`. Ids drawn into a `RenderTexture` and read by
  `LoadImageFromTextureAsync` give a GPU pick, a frame late.
- **2D:** each node between `rlPushMatrix`, `rlMultMatrixf` and `rlPopMatrix`, drawing with `DrawTexturePro` or `DrawTextureInstanced`,
  `DrawTextEx` and the shapes. Quads stay sprite records under a pushed matrix. `SetShapesTexture` on the sheet's white texel keeps
  shapes in the sheet's run.

## What has no door

1. **Stable handles across a reload.** A model load answers with a new `Model` of new `Mesh` records, so every holder is found and
   swapped. Textures are shared by path, and no call reads a file anew.
2. **More lights on one mesh than a draw has slots.** The count is fixed at build. `CreateLight` also counts across the program, so a
   second lit shader gets lights that are off, and a removed light's slot is never free again.
3. **Light kinds.** rlights' light is a color and a direction: no range, falloff, spot or intensity past the color's bytes.
4. **Instancing under `LoadPbrShader`.** `DrawMeshInstanced` draws nothing without a `mat4` attribute, and `pbr_vertex.glsl` has none.
   Found by Opus and left out of its write-up, then checked in the code. three.js's `InstancedMesh` needs it.
5. **A material's alpha mode and sides.** A glTF's `alphaMode`, `alphaCutoff` and `doubleSided` never reach `Material`, and `GltfMaterial`
   doesn't read them, so the sort can't tell a blended mesh from an opaque one.
6. **A glTF's node tree.** Node transforms are baked into vertices and `Mesh` has no name, so `getObjectByName` and a rigid part's own
   node have nothing to hold.
7. **Picking a posed mesh.** `GetRayCollisionMesh` reads the bind pose. A scratch `Mesh` around `animVertices` works, as a CPU skin.
8. **A file's reader through a wrapper.** `LoadModelAsync` chooses its reader from a constant name, so an engine's `load(fileName)` links
   the OBJ reader in every glTF program unless that load is a macro too.
9. **Several textures in a run.** A run is one texture, so interleaved sheets cost a draw per change, where Pixi binds several. No extra:
   this would be `Frame`'s own work under the same calls, and is measured first.

## The extras that would open them

Each stays close to one of raylib's own ideas.

| Gap | Extra | Close to |
|---|---|---|
| 1 | `ReloadModelAsync(model, fileName, ?done, ?failed)`, `ReloadTextureAsync(texture, fileName, ?done, ?failed)` | `UpdateTexture`, `UpdateMeshBuffer` |
| 2 | `-D helix-raylib-max-lights-per-draw=8`, and `CreateLightAt(index, type, position, target, color, shader)` | editing `MAX_LIGHTS` in rlights.h |
| 3 | `LIGHT_SPOT` and `Light.range`, `intensity`, `innerAngle`, `outerAngle`, read by `LoadPbrShader` alone | rlights' `Light` |
| 4 | An instanced twin of the PBR shader | raylib's instancing example |
| 5 | `Material.alphaMode`, `alphaCutoff`, `doubleSided`, after helix-formats reads them | `Material.unlit` |
| 6 | `Model.nodes`, `nodePose`, `meshNode` | `bones`, `bindPose`, `meshMaterial` |
| 7 | `GetRayCollisionMeshPosed(ray, mesh, transform)` | `GetModelBoundingBoxPosed` |
| 8 | `LoadModelGltfAsync`, `LoadModelObjAsync` | the name calling its reader alone |

Full doc comments are in [opus/sketch.md](opus/sketch.md) and [fable/sketch.md](fable/sketch.md). Fable's for `ReloadModelAsync` and
`CreateLightAt` are the closer to CONVENTIONS' rule.

The define sets how many lights one draw can use, not how many a scene can hold. The engine chooses which fill the slots for each mesh.
It keeps `MAX_LIGHTS` underneath. It is build-wide, for every lit shader in the program, and the fragment stage loops over every slot, so
raising it costs each pixel. Shaders are compiled as the program builds, so a count can't be a run-time argument: Fable's
`LoadPbrShaderEx(lightCount)` can't work as written.

## What would push toward a draw path of its own

None of it is in these two scenes (Fable's list): clipping under rotation, as `BeginScissorMode` is axis-aligned, and shadows. A light's
intensity past the color's bytes is the third, closed by gap 3's extra.

## The two sketches

| | Opus | Fable |
|---|---|---|
| Wall clock | 13 min | 18 min |
| Tokens | 226k | 232k |
| Gaps | 8 | 4 |
| More than four lights | half refuted, four slots refilled per draw (right: `Frame` takes a snapshot per draw) | confirmed |
| A model reload | says a held file answers with the kept one (true of textures alone) | a new `Model` of new records (right) |
| Extras | 11, and the build define | 6, one of which can't work as written |

They agree on the conclusion, on what raylib carries, and on the four candidates they refuted. Opus's breadth found the gaps a
three.js-shaped engine meets first. Fable's write-up is the tidier and names the limits. Each corrected the other once.
