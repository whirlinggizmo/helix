# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Now: milestone 4, advanced 3D

Built: shadows, environments, instancing, particles, 3D sprites and text, camera nodes, skinning and animation. Left: its checkpoint (the full checks, every 3D example natively).

## Next

- **Milestone 5: scene and pick.** Picking models and sprites under the pointer; what a scene adds over stages (the earlier frameworks' `scene3d` and `pick` examples).
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
