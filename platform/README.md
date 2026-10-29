# helix-platform

The hardware and the OS as plain Haxe calls, in the browser and natively. Each device is a contract, an interface in
`helix.platform`, and each API behind it is an adapter in `helix.platform.adapters.<contract>.<api>`. It has no policy of its own: no
queues, caches, frame order or asset model.

| Contract | Adapters |
|---|---|
| `IGraphics`: textures, buffers, programs, pipelines, passes and one draw; `present` | WebGL2 (the browser), sokol_gfx on GL 4.1 (native), SDL_GPU on Vulkan, Direct3D 12 or Metal (native) |
| `IWindow`: the drawing surface, title, size, position, fullscreen, monitors, visibility and closing | the page (DOM), SDL3 |
| `IEvents`: input and the window's events as records at each poll (keys as `Key`, mouse buttons as `MouseButton`), the gamepads' state (`PadButton`, `PadAxis`) | the page (DOM), SDL3 |
| `ISystem`: the device, the run options, a monotonic clock, the directory of the files the program ships with, and where the OS keeps a program's files | the page (DOM), SDL3 |
| `IAudio`: clips, streams (from a file, a URL or a download arriving) and voices with a volume, pitch and pan | Web Audio, SDL3_mixer |
| `IAudioDecoder`: a whole WAV, Ogg Vorbis, MP3 or FLAC file to mono PCM | Web Audio, SDL3_mixer |
| `IImageDecoder`: a PNG, JPEG, BMP, TGA or GIF file to RGBA | the page's decoder (a canvas), stb_image |
| `IHttp`: a GET whose body arrives in parts, and its abort | `fetch`, `sys.Http` |
| `IFileSystem`: files on this machine under a root, read and written whole by path, and located for streaming | IndexedDB (`BrowserFileSystemAdapter`), a directory (`NativeFileSystemAdapter`) |
| `IExport`: a finished file handed to the user | a download, a file in a directory |

Nothing here runs a loop: the program pumps each contract from its own loop ("Each frame", below).

## Using it

```
-lib helix-platform
```

Until it is published, link it from a checkout:

```
haxelib dev helix-platform <checkout>/platform
```

It depends on nothing. An application picks one adapter per contract for its target and constructs it, passing what that platform needs
as one object of named values (`new DomWindowAdapter({canvas: canvas})`, `new Sdl3WindowAdapter({graphics: Gl})`); after that it uses
the contract alone. Native builds compile the adapters' C with the program through hxcpp, against what is in `vendor/` (sokol_gfx, sokol_log, stb_image, SDL3's headers, and SDL3_mixer's sources, compiled with the program), found through
`HELIX_PLATFORM` (this directory, from `-lib helix-platform`). The SDL3 adapters link the SDL3 library that `HELIX_SDL3_LIBRARY` names.

Its tests, in `tests/`, build with `-lib helix-platform` alone; `tests/native/` holds the C tests of the native adapters, and
`tests/graphics/` draws on the GPU and checks the pixels it reads back, built from the hxml files beside it for a page, GL or SDL_GPU.

## Each frame

A contract that answers later delivers its answers in its `poll`, on the main thread, and never calls the program at any other time. So
each frame the program calls `poll` on each of these it made, in any order; one it forgets never answers:

| Contract | What its `poll` does |
|---|---|
| `IEvents` | Fills `events` with what happened since the last poll; read them after it |
| `IHttp` | Delivers each download's head, its body's parts, and its end |
| `IFileSystem` | Delivers reads, writes and the rest |
| `IAudio` | Delivers opened streams and keeps the voices fed |
| `IAudioDecoder`, `IImageDecoder` | Delivers finished decodes |

Then it draws with `IGraphics` (`beginFrame`, the draws, `endFrame`) and shows the frame with `present`. `IWindow`, `ISystem` and
`IExport` have nothing to poll. At the end, `dispose` on each, the window last (`IWindow.close`, where `canClose`).

```haxe
events.poll();
http.poll();
files.poll();
audio.poll();
for (event in events.events)
	switch event {
		case CloseRequested: running = false;
		case _:
	}
graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff000000);
graphics.endFrame();
graphics.present();
```

## Shaders

A program's shader is standard Vulkan-style GLSL 450, a `.vert` and a `.frag` file, and `ShaderCompiler.compile("x.vert", "x.frag")`
compiles it while the program builds into the `ShaderSource` `IGraphics.createShader` takes, for every adapter. It runs glslang and
SPIRV-Cross, fetched into the user's cache the first time (SPIRV-Cross from github.com/whirlinggizmo/helix-tools, which builds it, as
it publishes source only; built from source by hxcpp on a system it doesn't cover); what a source may declare, and what's
refused, is in its doc comment and docs/PLATFORM.md.

## Examples

Each example in `examples/` shows one thing with this library alone, and builds from the hxml files beside it:

```
cd examples/triangle
haxe build-web.hxml                                  # web/app.js beside web/index.html: serve web/ and open it
HELIX_SDL3_LIBRARY=/path/to/libSDL3.a haxe build-native.hxml   # native/Main
HELIX_SDL3_LIBRARY=/path/to/libSDL3.a haxe build-native-gpu.hxml   # native-gpu/Main, drawing with SDL_GPU
```

- `triangle`: a window, its events, one triangle through `IGraphics` and `present`, the loop on both targets. Its shader is
  `triangle.vert` and `triangle.frag`, standard GLSL compiled while it builds (`helix.platform.tools.ShaderCompiler`), so it runs on
  WebGL2, GL and SDL_GPU (`build-native-gpu.hxml`).
- `shader`: a compiled shader's texture and uniforms: a 2 x 2 texture made in code, repeated across a square by `shader.frag`, and a
  uniform block in each stage set every frame, one moving the square, the other shading it.

## Documents

The rules and the design live once, in the repository:

- [docs/PLATFORM.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/PLATFORM.md): each contract, what it means and what each adapter does.
- [docs/ARCHITECTURE.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/ARCHITECTURE.md): contracts, adapters and what belongs in each.
- [docs/CONVENTIONS.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/CONVENTIONS.md): names, units, layout and doc comments.
- [GOALS.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/GOALS.md): what the libraries are for.
