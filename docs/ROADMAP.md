# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Now: milestone 5, scene and pick

What the earlier frameworks' `scene3d` and `pick` examples show, with what they learned (wgrender-c and libwgt had picking; libwgf planned it), within DECISIONS 61: picks are queries the app makes, never callbacks or signals on nodes, and no scene object becomes a game tree. In order, each step leaving both targets working:

0. **Three flags on every node, libwgf's.** `enabled` (off: skipped with everything under it, by drawing, picking and updates, an emitter under it not moved on; the only flag that reaches the children, which keep their own), `visible` (off: its own output isn't drawn, a light doesn't shine or cast; it stays placed, its children as they are) and `pickable` (off: the ray passes its own output; its children can still be hit). Drawing and picking are independent: visible off and pickable on is an invisible hit area. Today's `setVisible` behaves as `enabled`, so its callers move to the flag they mean. On 3D and 2D nodes alike.
1. **The ray.** `Camera3D.getRay(x, y)`: from the near plane through a framebuffer pixel, within the camera's viewport area (the earlier frameworks assumed the whole window), perspective or orthographic from the same matrices the draw uses (wgrender-c's 526ff15: picking built its own perspective, so orthographic cameras missed). Games' own tests (physics, later) use it too.
2. **Picking a Stage3D.** `pick(camera, x, y)` returns the nearest hit: the node, the distance, the point (world and the node's own) and the normal facing the ray. Models by their triangles (Möller–Trumbore against the mesh's own vertices), after each one's world box; a box beyond the nearest hit so far is skipped (libwgt). Skinned models posed on the CPU with the shader's blend, cached until their joints move (wgrender-c's 6e79587: animated models picked in their rest pose left ghost arms). 3D sprites and text by their quads as drawn, and, when a node asks, by its texels' alpha; see-through materials hit only where they're opaque enough (6e79587's see-through blob shadow). Emitters are never picked. A node can be made unpickable (the ray passes; its children can still be hit); flags as step 0 says. Box normals face the ray from either side (wgrender-c's 9949a51).
3. **Picking a Stage2D.** The topmost (last drawn) sprite, text or shape under a point, through its 2D camera's zoom and turn, by its rectangle or its texels' alpha.
4. **The pointer over stages.** A pointer service polled once a frame, after input: the stages given it, in draw order, picked topmost first (a HUD over the world); queries for what's hovered, pressed (kept while dragged off), held, and clicked (released over what it was pressed on), with tick and frame edges as keys have. A press on a 2D node captures the pointer, so the world under a button doesn't see it. Nothing on the nodes themselves.
5. **Lights chosen per model.** Each model lit by the 8 lights whose reach meets its box most, as the earlier frameworks did (today: the first four the walk finds; API_FINDINGS). The stage's lights in one table, each record naming its 8, so models that share a mesh still draw as one.
6. **Measured.** A culling switch on a stage (libwgf's `set_culling`, on by default), so what culling saves can be measured, and a stage benchmark after libwgf's shadowbench: many models looking at and away from them, culled and not, shared meshes and not, many lights, and a pick through a crowd; natively and in V8, in CPU cycles (ratios, as the clamped CPU requires). And libwgf's shadow test: a caster above the view, whose shadow falls into it, kept; one aside, whose shadow can't, dropped (HeliX tests casters against each light's own view, fitted to the camera's slice: checked against libwgf's case, not assumed).
7. **The examples.** `scene3d`: shapes in a ring, clicked to select, hovered, a HUD over them taking the pointer first. `pick`: every kind picked (a cube, a sphere, a sprite by its alpha, text, a car, a walking character), with the hit's point, normal and distance shown.

Decided after measuring, not before: a spatial index (both culling and picking walk every node; neither earlier framework needed one), visibility and pick masks, skipping the posing of characters out of view (libwgt: 400 models looking away 0.94 ms posed lazily, 16.1 posed; and its trap: culling by last frame's posed box never poses a culled model, so it never walks back into view), occlusion culling, per-instance picks.

## Next

- **Milestone 6: UI.** Widgets and layout for games' menus and tools. A Clay-style UI is deferred.
- **Milestone 7: native network streaming.** A native audio stream playing a remote file as it downloads, and both targets playing while keeping the copy, shown starting before the download ends on a slowed network.

## Deferred until a game needs it

- **Animation layers:** an upper body's clip over a lower body's.
- **Skinned surface shaders:** an app's surface shader on a skinned model (it's ignored today).
- **Morph targets**, and more than four joints a vertex.
- **`IWebSocket`:** a contract of its own (open, send, receive, close), with a shared service for reconnecting and queuing.
- **`ecs-scene`:** waits on the game model, which is still open (behaviors and components undecided).

## Open designs

- **Work off the frame**, to be designed with physics: a module of fixed bulk calls (as the physics study's) that can run in place, in a Web Worker or on a thread without its callers changing. The environment bake would be its first one-shot client; today environment loads are tied to a per-frame budget, slow at a low frame rate.
- **One frame budget across the job pools:** each pool still delivers under its own 2 ms.
- **More platforms:** Windows, macOS and mobile haven't run; SDL3 and WebGPU adapters would sit beside sokol and WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
