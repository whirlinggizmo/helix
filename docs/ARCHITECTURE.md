# Architecture

HeliX is three layers, and code belongs to exactly one of them.

| Layer | Where | What it is |
| --- | --- | --- |
| Engine | `src/helix/` outside `adapters/` and `profiles/` | Everything that is the same on every platform: rendering (`render2d`, `render3d`, the framework's shaders and pipelines), assets, audio resources, input state, particles, math, the runner. Pure Haxe: no platform API, no target conditional. |
| Platform contracts | the interfaces the engine calls (below) | What a platform must provide, stated as capabilities, not as engine features. |
| Adapters | `src/helix/adapters/<contract>/<api>/` | One platform API behind one contract: a hardware and OS abstraction layer, nothing more. |

**Adapter directories are named for their contract:** `adapters/<contract>/<api>/`, where `<contract>` is the interface's name without the `I`, lowercase, words run together (`IAudioDecoder` → `audiodecoder/`, `IInputSource` → `inputsource/`), and `<api>` is the platform API it uses (`webgl2/`, `sokol/`, `dom/`). A contract whose object comes with another adapter's lives in that adapter's directory: `IWindow` in `host/` (the host makes the window; the native hosts share theirs, below), `IPcmFiles` in `audiodecoder/libsndfile/` (the native audio output streams through the codec). The `<api>` directory names the exact API, not the platform, so it says where an adapter can run (`http/fetchapi` runs wherever the Fetch API exists: browsers, Node, Bun, Deno); profiles are named for platforms. **The adapter class is `<Api><Contract>Adapter`**, with words the API's name ends with and the contract's starts with written once: `graphics/webgl2/WebGL2GraphicsAdapter`, `store/indexeddb/IndexedDbStoreAdapter`, `audio/webaudio/WebAudioAdapter` (not WebAudioAudio), `http/haxehttp/HaxeHttpAdapter`. Helpers beside it are named `<Api><Thing>` (`DomWindow`, `LibsndfilePcmFiles`). Native C, headers and extern bindings go in the adapter's `internal/`; what several adapters share, in `adapters/shared/`: the native hosts' `NativeHost` and `NativeWindow` over the C each host implements (`window.h`, and `surface.h`, the framebuffer the GL graphics adapter draws in), so `SokolHostAdapter` and `Sdl3HostAdapter` hold only how each opens its window, runs its loop and quits; and the native graphics adapters' `NativeGraphics` over the C each implements (`graphics.h`), so `SokolGraphicsAdapter` and `Sdl3GpuGraphicsAdapter` hold only their setup and how they build a program. Each adapter's extern bridge carries the hxcpp build XML for its own C and libraries, so a build compiles and links only the adapters its profile uses.

A **profile** (`src/helix/profiles/`) picks one adapter per contract for a target and hands them to the engine.

## The adapter rule

An adapter holds only what differs because of its platform or API.

- **In an adapter:** calls into the platform API; the API's quirks and limits worked around (GL's bottom-left origin, sokol's one write per image a frame, WebGL2's missing base instance); resource handles and their bookkeeping; the threads and callbacks the API needs, handed back to the host thread; validation that protects the platform (native memory, GL state).
- **Never in an adapter:** anything another adapter of the same contract would have to repeat. Formats the engine reads (WAV, glTF, .hdr), the framework's programs, layouts and pipelines, policies (limits, queues, concurrency caps, caching, retries, lifetimes), state machines over the platform's events (edges, gestures, the frame's order), engine services and their wiring, test tooling.
- **The test:** if a second adapter for the same contract (WebGPU beside WebGL2, SDL3 beside sokol, another OS's file system) would have to copy a piece of code, that piece belongs in the engine, and the contract hands the adapter data instead.

### Enforced

`tools/adaptercheck.py` runs first in `tools/typecheck.py` and `helix.py test`, and fails on:

1. an adapter naming engine code (rendering, engine services, generated layouts or framework programs, shared decoders, the runner);
2. engine code using a platform API (`js.html`, `js.Browser`, `js.Syntax`, `js.lib`, `sys.`, `cpp.`) or a target conditional;
3. an adapter's C including a generated shader header;
4. two adapters of one contract sharing a run of six or more identical lines;
5. an adapter directory not named for a contract one of its adapters implements;
6. an adapter class not named `<Api><Contract>Adapter` as above.

What it can't see (the same logic written twice in different words, policy hiding in a contract's doc comment) is review's. The check has a list for known violations, each with the audit step that removes it ([ADAPTER_AUDIT.md](ADAPTER_AUDIT.md)); the audit emptied it, and it only shrinks.

## Contracts and adapters

As built today; what is still to change is under **Target shape** below.

| Contract | Adapters | Platform part (theirs) |
| --- | --- | --- |
| `IGraphics` | `graphics/webgl2` (browser), `graphics/sokol` + C (native, sokol_gfx on GL 4.1), `graphics/sdl3gpu` + C (native, SDL_GPU on Vulkan, Direct3D 12 or Metal) | Textures (2D, cube, data, render targets, depth arrays), buffers, programs built from a `ShaderSource`, pipelines made as a `PipelineDesc` says, passes, one draw, reading pixels back. |
| `IHost` | `host/dom` (browser), `host/sokol` + C (native) | The loop, the clock, the window, quitting, run options. The `Runner` (engine) is what it pumps; the app reads `Services` (engine), filled by the runner. |
| `IWindow` | `host/dom/DomWindow`, `host/sokol/SokolWindow` | The drawing surface (framebuffer size, pixel ratio), focus, title, sizes, position, fullscreen, displays and visibility where the platform has them. |
| `ITestHarness` | `testharness/dom` (browser), `testharness/stdio` (native) | Hands a check the program's result. |
| `IInputSource` | `inputsource/dom` (browser), `inputsource/sokol` + `inputsource/evdev` C (native) | Keyboard, text, mouse, wheel, touch and focus events as they arrive, each connected gamepad's state at poll, and the platform's key codes as a table. The shared `InputRouter` owns edges, the pointer, focus policy and pad slots; the app reads its `InputState` as `IInput`. |
| `IAudio` | `audio/webaudio` (browser), `audio/sokol` + C (native) | Output: clips copied from PCM, streams opened from a source, voices; whether audio exists and runs now. Natively it streams through an `IPcmFiles` (the codec adapter's) and pumps its voices, as a push-based output must. The shared `AudioResources` and `AudioPlayback` own lifetimes, volume checks and waiting for audio to start. |
| `IAudioDecoder` | `audiodecoder/webaudio` (browser), `audiodecoder/libsndfile` + C (native; also `IPcmFiles` for streaming) | A whole Ogg or MP3 file to mono float PCM at 44.1 kHz. The shared `AudioDecoding` owns sniffing, the WAV path, the limits, PCM checks and queuing. |
| `IHttp` | `http/fetchapi` (browser), `http/haxehttp` (native) | A GET whose response arrives in parts, and its abort. The shared `Fetch` owns limits, the timeout, progress and queuing. |
| `IStore` | `store/indexeddb` (browser), `store/filesystem` (native) | Files by key (read, write, remove, clear, lease). The shared `Storage` owns key checks, the size limit, read-only refusal and queuing. |
| `IExport` | `export/download` (browser), `export/filesystem` (native) | Hands a finished file to the user: a download, or a file in the directory the profile chose (`HELIX_EXPORT`, else the user's pictures). The shared `Screenshots` reads the frame, encodes PNG (`Png`) and names the files. |
| `IImageDecoder` | `imagedecoder/canvas` (browser), `imagedecoder/stb` + C (native) | Bytes to RGBA. The shared `ImageDecoding` owns queuing, cancellation and shutdown. |

### Target shape (decided)

- **Host: done** (DECISIONS 81). Backend facts (`Adapters.info`) went with step 4: nothing read them.
- **Screenshots: done** (DECISIONS 86). `IGraphics.readPixels` reads the finished frame or a render target back; `Png` encodes in shared Haxe; `IExport` saves; `Services.screenshots` and the autopilot's `screenshot` command use them, in release builds too.
- **Asynchronous work: done** (DECISIONS 82). `helix.core.Jobs` is the shared pool (a queue, a cap, exactly-once completion on the host thread, cancellation with the platform's abort, shutdown); `Fetch`, `Storage`, `ImageDecoding` and `AudioDecoding` run on it over `IHttp`, `IStore` and `IImageDecoder`; native adapters hand thread results back through `adapters/shared/Mailbox`. Left: one frame budget across the pools (each still delivers under its own 2 ms).
- **WebSockets, later:** a contract of their own (`IWebSocket`: open, send, receive, close), not folded into `IHttp`; a shared service on top for what's policy (reconnecting, queuing messages).
- **Audio: done** (DECISIONS 83).
- **Input: done** (DECISIONS 84).

## Graphics

`IGraphics` knows no program, layout or pipeline of HeliX's own. The engine describes them as data:

- **Programs:** each framework shader in `src/helix/graphics/shaders/` is compiled by sokol-shdc at build time into a generated Haxe class (`Lit3DLayout` and its siblings) holding the program in both dialects with its bindings (`source()`), its vertex buffers' layout (`buffers()`) and the constants the engine packs vertices and records with. An app's `.hxshader` is the same `ShaderSource`. `IGraphics.createShader` builds either.
- **Pipelines:** `PipelineDesc` is a program, its buffers' layout, primitive, indexing, blend, depth test and write, culling and winding, depth-only, and the clip flip (what block 0 holds, so an adapter whose render targets are stored upside down can draw them the right way up). `helix.graphics.Pipelines` describes every framework pipeline, makes each once per GPU and keeps it; drawing code asks it at each draw, so a program built again (a hot reload) gets its pipelines made again behind it.
- **Drawing:** one `draw`: buffers by the pipeline's buffer index, an index buffer for indexed pipelines, a range, instances, textures, samplings and uniform blocks by slot.

Resource kinds are the adapter's concern (a cube, a depth array read through a comparison sampler, a data texture read texel by texel), and so is binding each; which kind a program expects is in its `ShaderSource`.

## What each audience needs

| To... | Needs |
| --- | --- |
| Build and run a game in a browser | Haxe. Node and Terser only to minify a release build. |
| Build and run a game natively (Linux) | Haxe, hxcpp, a C/C++ compiler, and the native adapters' system libraries: X11/Xrandr/Xi/Xcursor and GL (window, graphics), ALSA (audio output), the libsndfile runtime with Vorbis, Opus and mpg123 (compressed audio). |
| Write shaders (an app's `.hxshader`, or the framework's) | sokol-shdc, and Python with PyYAML for the packer and generator. |
| Develop HeliX itself | The above, plus hotreload-hx (the dev loop), Node with Playwright and pngjs (browser checks), FFmpeg (test fixtures, Asteroids' sounds). |

Today a fresh checkout also needs sokol-shdc and Python to build at all, because the framework's generated shader code isn't committed. Since that code is now pure Haxe (sources and layouts as data), committing it, or shipping it in a release, would take both off a game developer's list; shader authors and HeliX's own development keep them. Python is the tools' language (the build and dev driver, the shader packer and generator, the checks); moving them to Haxe's interpreter is possible, the YAML reflection reader being the one piece Haxe lacks. Wasm (physics, later) would be built by maintainers with Emscripten and shipped prebuilt; natively the same C/C++ links through hxcpp.
