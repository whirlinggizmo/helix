# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Next

- **Milestone 8, what's left** (the rest is in [HISTORY.md](HISTORY.md)): the checkpoint: the typecheck, every example natively, both autopilots under both profiles on the three systems, and this entry closed.
- **Milestone 11: the scene file.** A `.scene` of HeliX's own (JSON: a tree of groups, models from files by path, lights, cameras, nested scenes as prefabs, overrides on a file's nodes by path, `props` per node), load and save round-tripping; behaviors as classes (`Behavior`: `start`, `update(dt)`, `stop`, `done`) run by a `Behaviors` pass the scene owns beside its timers and tweens, never held on a node, each holding the node it drives and its props, found by name for the file through a build macro over `@:behavior`, which settles the game model (decisions 61 and 130); property schemas for an inspector; `tools/gltf2scene.py` from a Blender export. libwgf's scene blocks are the lessons (the racer's FRICTION part 4) and Vignette Studio the prior art for the editor, which comes after as a separate web package over the JS build, not in the framework. **Done when:** load, save, load gives the same bytes under test, a `scene` example loads a level with behaviors, and a Blender-exported level converts and loads.
- **Milestone 12: input actions and audio control.** An action map ("jump" is Space, a pad's South, a touch button), queried as keys are, rebound at run time and saved; audio buses (master, music, effects) with volumes, fades, pitch and pan; native network streaming (a native stream playing a remote file as it downloads, both targets keeping the copy, shown starting before the download ends on a slowed network). **Done when:** the `ui` example's settings screen rebinds a key and sets the buses, and the stream starts before its download ends.
- **Milestone 13: the shader library.** `helix.shaders`: surface shaders (outline, silhouette, rim, hit flash, toon, dissolve, water) and screen effects (bloom over half-size intermediates in `PostProcess`, FXAA, blur, vignette, a color LUT, CRT, chromatic aberration, pixelate), and 2D sprite shaders (outline, flash, dissolve, palette swap), each attached in one line with parameters by name. **Done when:** a gallery example shows each on both targets and the autopilot checks each one's pixels.
- **Milestone 14: physics.** 2D arcade physics first (bodies, gravity, move-and-slide against tiles and slopes, deterministic), then Box2D and Jolt through the work-off-the-frame module (below), with the racer's lessons (its FRICTION part 2) and a body's drawn transform for the camera. **Done when:** a platformer slice and a physics slice replay alike on both targets.
- **Milestone 15: pathfinding.** Grid A* with flow fields; a navmesh (Recast and Detour, or hxDaedalus, benchmarked first) with steering. **Done when:** agents cross a level in an example on both targets, the same paths.
- **Milestone 16: saves.** A store of the game's own apart from the asset cache: keys to bytes or JSON, slots, a version for migration; IndexedDB in a browser, the user's data directory natively. **Done when:** the dressing room saves a look and the services tests cover it on both targets.
- **Milestone 17: sockets and netcode.** `ISocket` (open, send, receive, close) with a browser adapter and a native one with TLS, a shared service reconnecting and queuing; then netcode as a separate package, lockstep over the deterministic pieces, shaped by the final example. **Done when:** two browsers and a native build play the final example together.

## Deferred until a game needs it

- **Decided after measuring** (milestone 5 left them for numbers that call for them): a spatial index (both culling and picking walk every node; neither earlier framework needed one), visibility and pick masks, skipping the posing of characters out of view (libwgt: 400 models looking away 0.94 ms posed lazily, 16.1 posed; and its trap: culling by last frame's posed box never poses a culled model, so it never walks back into view), occlusion culling, per-instance picks. Also caching skinned poses for picks, if picking many characters is measured to cost.
- **The autopilot's UI:** probes that report which widgets are showing, and events recorded for scripts to wait on, beside `click`.
- **Animation layers:** an upper body's clip over a lower body's.
- **Skinned surface shaders:** an app's surface shader on a skinned model (it's ignored today).
- **Morph targets**, and more than four joints a vertex.
- **`ISocket`:** milestone 17.
- **`ecs-scene`:** milestone 11 settles the game model with behaviors; whether an ECS follows is decided after it.

## Open designs

- **Work off the frame**, to be designed with physics: a module of fixed bulk calls (as the physics study's) that can run in place, in a Web Worker or on a thread without its callers changing. The environment bake would be its first one-shot client; today environment loads are tied to a per-frame budget, slow at a low frame rate.
- **One frame budget across the job pools:** each pool still delivers under its own 2 ms.
- **macOS: built for in full, verified only as far as a Mac can run it.** macOS is a target like the others: each milestone builds for it, Metal and SDL_GPU included, and CI builds every example there. What waits is verification beyond building: no Mac here can open a HeliX window (the one at hand reaches GL 3.3), so what's claimed is the build, the unit tests, and SDL_GPU on Metal in CI's virtual machine (milestone 8). A real display, gamepads, sound and Retina scaling still need a Mac in hand. iOS waits for a Mac that can run it; Android hasn't been tried.
- **A WebGPU adapter** would sit beside WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
