# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Next

- **Milestone 7: Windows, macOS and CI.** HeliX has only run on Linux/X11 and in Chromium. This milestone carries the earlier frameworks' verification over, and fills the native parts that are Linux-only. The plan, to be agreed before it's built:
  1. **Windows over ssh** (`tools/remote_windows.py`, from libwgt's `run_remote_windows.py` as libwgf extended it with `--then`). It packs the working tree (tracked and new, unignored files), copies it to a scratch folder on a Windows machine (sightblinder: Windows 11, Visual Studio 2026, Python 3.12, Haxe 4.3.7, hxcpp 4.3.2) and builds there with hxcpp and MSVC. It then runs the test suite and Trig's bits there, and deletes the folder, also on failure. MSVC is the Windows compiler, as hxcpp chooses it and as wgrender-c's and libwgf's Haxe builds used it; hxcpp 4.3.2 with MinGW (`-D mingw`) doesn't compile under GCC 16 and was never verified by either, so it's left out. An ssh session has no desktop, so the windowed checks (the autopilots, the examples) run in the logged-in desktop session of the Windows machine, or the MSVC build under Wine on the private display here: to be chosen.
  2. **CI on GitHub Actions** (public, so Linux, Windows and macOS runners are free), with wgrender-c's and libwgf's shape:
     - On every push except docs-only ones: the type check, the interpreter's unit tests, formatting and docs, and the tool tests. Also one native hxcpp build of an example, since the type check never compiles the C adapters (wgrender-c's "one example links" lesson).
     - Daily and on demand: the full native suite under Xvfb, the services and both autopilots in Chrome, with screenshots uploaded as artifacts.
     - A Windows job (MSVC) and a macOS arm64 job, headless: the runners have no GPU for GL 4.1 (libwgf's finding). macOS hasn't run for any of the frameworks yet; this is its first.
     - The pins as the earlier CIs set them: Haxe 4.3.7, and hxcpp 4.3.2 cached, a cache miss fetching with retries. A newer push cancels the run in progress.
  3. **The Linux-only native parts:**
     - Gamepads: an XInput adapter on Windows (libwgf's, from wgrender-c, loading the DLL at runtime and reading the Guide button through ordinal 100). On macOS, a no-gamepad adapter, as none of the frameworks had one.
     - Audio decoding: libsndfile's pinned official Windows release and Homebrew's on macOS, as DECISIONS 28 chose a pinned SDK. The earlier frameworks vendored their decoders instead (dr_mp3, libogg, libvorbis); that's the alternative if the binaries prove awkward.
     - The build's system libraries and flags per platform: Windows' and macOS' libraries in place of X11 and ALSA; `-ffp-contract=off`'s equivalents for MSVC and clang, so `Trig` keeps the same bits; hxcpp's 64-bit flag (`HXCPP_M64`, already set).
     - The user's cache folder: `%LOCALAPPDATA%` and `~/Library/Caches`.
     - The native checks that open windows: on Windows and macOS they run headless, the private display staying Linux's.
  4. **Done when:** every example builds on Windows (sightblinder and CI) and macOS (CI), the test suite passes on all three, the Trig hash agrees on all of them, and on Windows the autopilots give the same final game in a window.
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
