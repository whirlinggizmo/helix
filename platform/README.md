# helix-platform

The hardware and the OS as plain Haxe calls, in the browser and natively. Each device is a contract, an interface in
`helix.platform`, and each API behind it is an adapter in `helix.platform.adapters.<contract>.<api>`, as the table names them. It has no policy of its own.

| Contract | What | Browser | Native |
|---|---|---|---|
| `IGraphics` | The GPU | `graphics.webgl2.WebGl2GraphicsAdapter` | `graphics.sokol.SokolGraphicsAdapter` (GL 4.1), `graphics.sdl3gpu.Sdl3GpuGraphicsAdapter` (Vulkan, Direct3D 12, Metal) |
| `IWindow` | The window | `window.dom.DomWindowAdapter` | `window.sdl3.Sdl3WindowAdapter` |
| `IEvents` | The window's events, and the stream the devices add to | `events.dom.DomEventsAdapter` | `events.sdl3.Sdl3EventsAdapter` |
| `IKeyboard` | Keys and typed text | `keyboard.dom.DomKeyboardAdapter` | `keyboard.sdl3.Sdl3KeyboardAdapter` |
| `IMouse` | The mouse | `mouse.dom.DomMouseAdapter` | `mouse.sdl3.Sdl3MouseAdapter` |
| `ITouch` | Fingers | `touch.dom.DomTouchAdapter` | `touch.sdl3.Sdl3TouchAdapter` |
| `IGamepads` | Gamepads | `gamepads.dom.DomGamepadsAdapter` | `gamepads.sdl3.Sdl3GamepadsAdapter` |
| `ITilt` | The device's tilt | `tilt.dom.DomTiltAdapter` | `tilt.sdl3.Sdl3TiltAdapter` (unavailable) |
| `ISystem` | The device, the clock and the program's directories | `system.dom.DomSystemAdapter` | `system.sdl3.Sdl3SystemAdapter` |
| `IAudio` | Sound | `audio.webaudio.WebAudioAdapter` | `audio.sdl3mixer.Sdl3MixerAudioAdapter` |
| `IAudioDecoder` | Audio files to samples | `audiodecoder.webaudio.WebAudioDecoderAdapter` | `audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter` |
| `IImageDecoder` | Image files to pixels | `imagedecoder.canvas.CanvasImageDecoderAdapter` | `imagedecoder.stb.StbImageDecoderAdapter` |
| `IHttp` | HTTP GET | `http.fetchapi.FetchApiHttpAdapter` | `http.haxehttp.HaxeHttpAdapter` |
| `IFileSystem` | Files on this machine | `filesystem.browser.BrowserFileSystemAdapter` | `filesystem.native.NativeFileSystemAdapter` |
| `IExport` | A file handed to the user | `export.download.DownloadExportAdapter` | `export.filesystem.FileSystemExportAdapter` |

## Using it

```
-lib helix-platform
```

Until it is published, link it from a checkout:

```
haxelib dev helix-platform <checkout>/platform
```

A program constructs one adapter for each contract it uses, for its target, and after that uses the contract alone. Native builds link
SDL3: `HELIX_SDL3_LIBRARY` names the library.

## Shaders

A shader is standard GLSL 450, a `.vert` and a `.frag` file. `ShaderCompiler.compile("x.vert", "x.frag")`, in `helix.platform.tools`,
compiles it while the program builds, into the `ShaderSource` that `IGraphics.createShader` takes on every adapter. What a shader may
declare is in [docs/PLATFORM.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/PLATFORM.md).

## Examples

Each example in `examples/` shows one thing, and builds from the hxml files beside it:

```
cd examples/triangle
haxe build-web.hxml                                  # web/app.js beside web/index.html: serve web/ and open it
HELIX_SDL3_LIBRARY=/path/to/libSDL3.a haxe build-native.hxml   # native/Main
HELIX_SDL3_LIBRARY=/path/to/libSDL3.a haxe build-native-gpu.hxml   # native-gpu/Main, drawing with SDL_GPU
```

- `triangle`: a window, its events and one triangle, the loop on both targets.
- `shader`: a compiled shader's texture and uniforms.

Its tests are in `tests/`.

## Documents

- [docs/api/platform.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/platform.md) and
  [docs/api/platform-adapters.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/platform-adapters.md): the API
  reference, the contracts and the adapters.
- [docs/PLATFORM.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/PLATFORM.md): each contract, what it means and what each adapter does.
- [docs/ARCHITECTURE.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/ARCHITECTURE.md): contracts, adapters and what belongs in each.
- [docs/CONVENTIONS.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/CONVENTIONS.md): names, units, layout and doc comments.
- [GOALS.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/GOALS.md): what the libraries are for.
