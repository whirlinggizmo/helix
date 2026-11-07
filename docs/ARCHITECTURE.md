# Architecture

helix is layered libraries (docs/PLAN.md), and inside the bottom one, the platform, code belongs to exactly one of two sides:

| Side | Where | What it is |
| --- | --- | --- |
| Interfaces | `libs/platform/src/helix/platform/I*.hx` and the data types they take | What a platform must provide, stated as capabilities, not as any engine's features. |
| Adapters | `libs/platform/src/helix/platform/adapters/<interface>/<api>/` | One platform API behind one interface: a hardware and OS abstraction layer, nothing more. |

Everything above the platform (services, then the layers the chosen path asks for) is pure Haxe: no platform API, no target
conditional. A program constructs one adapter per interface for its target, then the services it wants from them, and uses the
interfaces alone after that.

**Adapter directories are named for their interface:** `adapters/<interface>/<api>/`, where `<interface>` is the interface's name without
the `I`, lowercase, words run together (`IAudioDecoder` → `audiodecoder/`, `IEvents` → `events/`), and `<api>` is the platform API it
uses (`webgl2/`, `sdl3/`, `dom/`). One library behind several interfaces still gives each its own directory (`window/sdl3/`,
`events/sdl3/`), so a program chooses each interface's adapter on its own; what they share lives in `adapters/shared/<api>/`. The
`<api>` directory names the exact API, not the platform, so it says where an adapter can run (`http/fetchapi` runs wherever the Fetch
API exists: browsers, Node, Bun, Deno). An interface whose adapters differ only by the target they run on names the target instead
(`filesystem/browser`, `filesystem/native`), since that is what a reader picks it by. **The adapter class is `<Api><Interface>Adapter`**,
with words the API's name ends with and the interface's starts with written once: `graphics/webgl2/WebGl2GraphicsAdapter`,
`filesystem/browser/BrowserFileSystemAdapter`, `audio/webaudio/WebAudioAdapter` (not WebAudioAudio), `http/haxehttp/HaxeHttpAdapter`.
Helpers beside it are named `<Api><Thing>` (`DomPage`). Native C, headers and extern bindings go in the adapter's `internal/`; what
several adapters share, in `adapters/shared/`: SDL3's window and its state (`shared/sdl3`, which also implements `surface.h`, the
framebuffer the graphics adapters draw in and present), the page's (`shared/dom`), and the native graphics adapters' `NativeGraphics`
over the C each implements (`graphics.h`), so `SokolGraphicsAdapter` and `Sdl3GpuGraphicsAdapter` hold only their setup and how they
build a program. Each adapter's extern bridge carries the hxcpp build XML for its own C and libraries, so a build compiles and links
only the adapters the program constructs.

## The adapter rule

An adapter holds only what differs because of its platform or API.

- **In an adapter:** calls into the platform API; the API's quirks and limits worked around (GL's bottom-left origin, sokol's one write
  per image a frame, WebGL2's missing base instance), and a workaround that changes what the caller gets is stated in the interface's
  doc, so code above relies on it on every target; resource handles and their bookkeeping; the threads and callbacks the API needs,
  handed back to the main thread; validation that protects the platform (native memory, GL state).
- **Never in an adapter:** anything another adapter of the same interface would have to repeat. Formats a library above reads (glTF,
  .hdr), a library's programs, vertex layouts and pipelines, policies (limits, queues, concurrency caps, caching, retries, lifetimes),
  state machines over the platform's events (edges, gestures, the frame's order), services and their wiring, test tooling.
- **The test:** if a second adapter for the same interface (WebGPU beside WebGL2, SDL3 beside sokol, another OS's file system) would
  have to copy a piece of code, that piece belongs above the platform, and the interface hands the adapter data instead.

### Enforced

`tools/check_adapters.py` runs first in `tools/check_types.py` and `helix.py test`, and fails on:

1. an adapter naming code above the platform;
2. the platform's code outside its adapters using a platform API (`js.html`, `js.Browser`, `js.Syntax`, `js.lib`, `sys.`, `cpp.`) or a
   target conditional (its `macros/` and `tools/` excepted: they run in the compiler, never in a program);
3. an adapter's C including a generated shader header;
4. two adapters of one interface sharing a run of six or more identical lines;
5. an adapter directory not named for an interface one of its adapters implements;
6. an adapter class not named `<Api><Interface>Adapter` as above;
7. a C bridge (`internal/`) or a shared helper (`adapters/shared/`) shown in the reference (no `@:noCompletion`), or an interface, an
   adapter or a type they take hidden from it;
8. an adapter with a public member that is neither its constructor nor its interface's (an override and the C bridges excepted).

What it can't see (the same logic written twice in different words, policy hiding in an interface's doc comment) is review's. The check
has a list for known violations; it is empty, and it only shrinks.

## Interfaces and adapters

The specification is docs/PLATFORM.md; this is the map.

| Interface | Adapters | What it provides |
| --- | --- | --- |
| `IGraphics` | `graphics/webgl2` (browser), `graphics/sokol` + C (native, sokol_gfx on GL 4.1), `graphics/sdl3gpu` + C (native, SDL_GPU on Vulkan, Direct3D 12 or Metal) | Textures (2D, cube, data, render targets of RGBA8 or half floats with or without depth, depth arrays), buffers, programs built from a `ShaderSource`, pipelines made as a `PipelineDesc` says, passes, one draw, reading pixels back, `present`. |
| `IWindow` | `window/dom` (browser), `window/sdl3` + C (native) | The drawing surface (framebuffer size, pixel ratio), focus, title, sizes, position, fullscreen, displays and visibility where the platform has them, and closing. No loop: the program's owner calls each frame. |
| `IEvents` | `events/dom` (browser), `events/sdl3` + `shared/sdl3` C (native) | The window's focus, visibility, size and close events and the first press as records at each `poll`, in one stream the devices add to. Edges, gestures and pad slots are a service's. |
| `IKeyboard` | `keyboard/dom`, `keyboard/sdl3` | Keys (`Key`) and typed text in the events' stream, built over the events adapter. |
| `IMouse` | `mouse/dom`, `mouse/sdl3` | The mouse's buttons (`MouseButton`), moves and wheel in the events' stream. |
| `ITouch` | `touch/dom`, `touch/sdl3` | Fingers in the events' stream. |
| `IGamepads` | `gamepads/dom`, `gamepads/sdl3` | Pads connecting and their buttons in the events' stream, and their state after each poll (`PadButton`, `PadAxis`). |
| `ITilt` | `tilt/dom`, `tilt/sdl3` (unavailable) | The device's orientation in the events' stream, once access is asked for. |
| `ISystem` | `system/dom` (browser), `system/sdl3` (native) | The device, the run options (the URL query in a page, `--name=value` or a `HELIX_*` environment variable natively), a monotonic clock (`getTime`), the directory of the files the program ships with, and where the OS keeps a program's data and cache. |
| `IAudio` | `audio/webaudio` (browser), `audio/sdl3mixer` + C (native, SDL3_mixer) | Output: clips copied from PCM, streams opened from a source, voices with a volume, a pitch and a pan, each change ramped so nothing clicks; whether audio exists and runs now. In a page a voice played before the first gesture waits and starts when audio runs. Natively it decodes its streams itself as they're read, from a file or a download arriving; `playsUrls` says whether it plays a remote URL itself (a browser) or is given the download (natively). Buses, fades and lifetimes are a service's. |
| `IAudioDecoder` | `audiodecoder/webaudio` (browser), `audiodecoder/sdl3mixer` + C (native) | A whole WAV, Ogg Vorbis, MP3 or FLAC file to float PCM in its channels, at its own rate or one asked for. |
| `IImageDecoder` | `imagedecoder/canvas` (browser), `imagedecoder/stb` + C (native, stb_image) | A PNG, JPEG, BMP, TGA or GIF file to RGBA. |
| `IHttp` | `http/fetchapi` (browser), `http/haxehttp` (native) | A GET whose response arrives in parts, and its abort. Limits, timeouts, progress and queuing are a service's. |
| `IFileSystem` | `filesystem/browser` (IndexedDB), `filesystem/native` (a directory) | Files on this machine under a root: read and written whole by path, removed, cleared, located for streaming. Bringing a file in when it's missing or stale is a service's, over `IHttp`. |
| `IExport` | `export/download` (browser), `export/filesystem` (native) | Hands a finished file to the user: a download, or a file in a directory. |

Adapters that implement `IPollable` must be pumped every frame via `poll()`, with results being returned on the main thread during that
poll. Note that native adapters return results from their threads back through `adapters/shared/Mailbox`, drained by `poll()`.
