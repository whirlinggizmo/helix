# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Next

- **Milestone 8: native network streaming.** A native audio stream playing a remote file as it downloads, and both targets playing while keeping the copy, shown starting before the download ends on a slowed network.

## Deferred until a game needs it

- **Decided after measuring** (milestone 5 left them for numbers that call for them): a spatial index (both culling and picking walk every node; neither earlier framework needed one), visibility and pick masks, skipping the posing of characters out of view (libwgt: 400 models looking away 0.94 ms posed lazily, 16.1 posed; and its trap: culling by last frame's posed box never poses a culled model, so it never walks back into view), occlusion culling, per-instance picks. Also caching skinned poses for picks, if picking many characters is measured to cost.
- **The autopilot's UI:** probes that report which widgets are showing, and events recorded for scripts to wait on, beside `click`.
- **Animation layers:** an upper body's clip over a lower body's.
- **Skinned surface shaders:** an app's surface shader on a skinned model (it's ignored today).
- **Morph targets**, and more than four joints a vertex.
- **`IWebSocket`:** a contract of its own (open, send, receive, close), with a shared service for reconnecting and queuing.
- **`ecs-scene`:** waits on the game model, which is still open (behaviors and components undecided).

## Open designs

- **Work off the frame**, to be designed with physics: a module of fixed bulk calls (as the physics study's) that can run in place, in a Web Worker or on a thread without its callers changing. The environment bake would be its first one-shot client; today environment loads are tied to a per-frame budget, slow at a low frame rate.
- **One frame budget across the job pools:** each pool still delivers under its own 2 ms.
- **More platforms:** Windows, macOS and mobile haven't run; SDL3 and WebGPU adapters would sit beside sokol and WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
