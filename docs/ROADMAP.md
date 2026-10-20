# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Next

- **Milestone 14: HeliX as a haxelib.** A game of its own, anywhere on disk, takes the framework with `-lib helix`, as it would Heaps or OpenFL: a `haxelib.json` (the class path `src/`, an `extraParams.hxml` for what HeliX needs); the generated code committed and kept current by CI (the framework's program classes, the library's packed shaders with SDL_GPU's dialects, the built-in font), so a build needs only Haxe and hxcpp, not Python or sokol-shdc; the native C (adapters, sokol, SDL3, the libsndfile bridge) found through the lib's own path, not the checkout's. Hot reload stays the game's choice: `-lib hotreload-hx` and its dev server bring code, textures, sounds and fonts back as they change, as now; a game's own `.glsl` needs packing on save (a small `haxelib run helix shader`, with a watch). The examples build the same way. **Done when:** a game in a folder outside the repository, installed with `haxelib git`/`haxelib dev`, builds for the web and natively and hot reloads in the browser, in CI too.
- **Milestone 15: physics.** 2D arcade physics first (bodies, gravity, move-and-slide against tiles and slopes, deterministic), then Box2D and Jolt through the work-off-the-frame module (below), with the racer's lessons (its FRICTION part 2) and a body's drawn transform for the camera. **Done when:** a platformer slice replays alike on both targets, and a racer slice after libwgf's (`../libwgf-racer`): a vehicle on Jolt in a worker or a thread, its poses crossing by the study's bulk transfer (32-byte poses into a caller-owned typed array; natively straight into Haxe `Bytes`), a chase camera on the body's drawn transform, the same lap replayed on both targets.
- **Milestone 16: pathfinding.** Grid A* with flow fields; a navmesh (Recast and Detour, or hxDaedalus, benchmarked first) with steering. **Done when:** agents cross a level in an example on both targets, the same paths.
- **Milestone 17: saves.** A store of the game's own apart from the asset cache: keys to bytes or JSON, slots, a version for migration; IndexedDB in a browser, the user's data directory natively. **Done when:** the dressing room saves a look and the services tests cover it on both targets.
- **Milestone 18: sockets and netcode.** `ISocket` (open, send, receive, close) with a browser adapter and a native one with TLS, a shared service reconnecting and queuing; then netcode as a separate package, lockstep over the deterministic pieces, shaped by the final example. **Done when:** two browsers and a native build play the final example together.

## Deferred until a game needs it

- **Decided after measuring** (milestone 5 left them for numbers that call for them): a spatial index (both culling and picking walk every node; neither earlier framework needed one), visibility and pick masks, skipping the posing of characters out of view (libwgt: 400 models looking away 0.94 ms posed lazily, 16.1 posed; and its trap: culling by last frame's posed box never poses a culled model, so it never walks back into view), occlusion culling, per-instance picks. Also caching skinned poses for picks, if picking many characters is measured to cost.
- **The autopilot's UI:** probes that report which widgets are showing, and events recorded for scripts to wait on, beside `click`.
- **An action bound to a UI widget:** the drawn touch button and the region it presses as one binding, when the UI asks for it.
- **Animation layers:** an upper body's clip over a lower body's.
- **The shader library's next pieces:** an outline of a model's silhouette only, by stencil (the model marks its pixels as it draws, its outline drawn where none is marked: no more draws than today, the stencil beside the depth; stencil state in the pipeline description and every adapter, depth-stencil targets), so a character's eyes, brows and hair don't outline themselves across its face as an inverted hull's parts do, a line inside the silhouette then needing an edge pass on the screen; an outline's width in pixels, held by the distance (world units only today); values of a sprite's own in its vertices, so sprites with one effect but their own flash or palette row share a draw; sprite effects on a stage's text.
- **Morph targets**, and more than four joints a vertex.
- **`ISocket`:** milestone 18.
- **The scene file's next kinds:** a prefab's reference to a node outside itself (an instantiating entry passing a reference down, so a car prefab's behavior could name the race), and the 2D kinds under a `Node2D` root.
- **An ECS:** not planned. Milestone 11 settled the game model with behaviors run by a pass (decision 132); an ECS would come only for a game that measures the need.

## Open designs

- **Work off the frame**, to be designed with physics: a module of fixed bulk calls (as the physics study's) that can run in place, in a Web Worker or on a thread without its callers changing. The environment bake would be its first one-shot client; today environment loads are tied to a per-frame budget, slow at a low frame rate.
- **One frame budget across the job pools:** each pool still delivers under its own 2 ms.
- **macOS: built for in full, verified only as far as a Mac can run it.** macOS is a target like the others: each milestone builds for it, Metal and SDL_GPU included, and CI builds every example there. What waits is verification beyond building: no Mac here can open a HeliX window (the one at hand reaches GL 3.3), so what's claimed is the build, the unit tests, and SDL_GPU on Metal in CI's virtual machine (milestone 8). A real display, gamepads, sound and Retina scaling still need a Mac in hand. iOS waits for a Mac that can run it; Android hasn't been tried.
- **A WebGPU adapter** would sit beside WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
