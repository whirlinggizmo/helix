# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Next

- **Milestone 8: SDL3, a second native profile.** `NativeSdl3Profile` beside `NativeSokolGLProfile`, under the same contracts, to be agreed before it's built; SDL's source (window, events, gamepads, audio streams, GPU) and the earlier frameworks' SDL use are read first.
  - **The dependency:** SDL 3.4.18 (3.4 is the stable series), pinned and hash-checked, in the user's cache as `tools/shdc.py` does: on Linux built from its source by a tool (CMake, needed for that one build only; HeliX's own build stays hxcpp alone), on Windows the official `SDL3-devel-3.4.18-VC.zip` (its DLL copied beside the program, as libsndfile's), on macOS the official disk image's framework. The system's SDL isn't used, so every machine and CI build against the same one.
  - **The adapters:** `Sdl3HostAdapter` with its `Sdl3Window` (`host/sdl3/`); `Sdl3InputSourceAdapter`, keys, pointer, touch, text and gamepads through SDL's gamepad API and its controller database (hot-plugging, rumble), replacing evdev and XInput under this profile; `Sdl3AudioAdapter` on an audio stream, with libsndfile decoding as now.
  - **Graphics in two steps:** first the sokol_gfx adapter drawing in SDL's GL 4.1 context, which proves the platform half with graphics known to work; then `Sdl3GpuGraphicsAdapter` on SDL_GPU (Vulkan, Direct3D 12, Metal), its shader route (sokol-shdc's SPIR-V and Metal outputs, or SDL_shadercross) and SDL_GPU's binding rules settled by reading its source first.
  - **Done when:** the services tests and both autopilots pass under both native profiles with the same final games, on Linux (Vulkan through lavapipe on CI) and in a window on Windows; a gamepad works through SDL on Windows; every example builds under the SDL3 profile on all three systems; the two profiles' CPU cost compared in cycles.
- **Milestone 9: native network streaming.** A native audio stream playing a remote file as it downloads, and both targets playing while keeping the copy, shown starting before the download ends on a slowed network.

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
- **macOS and iOS: deferred until a Mac can run them.** CI builds every example on macOS, but no Mac here can open a HeliX window (the one at hand reaches GL 3.3), so nothing beyond the build is claimed; SDL3's Metal path is where a Mac would start. Android hasn't been tried.
- **A WebGPU adapter** would sit beside WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
