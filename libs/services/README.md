# helix-services

What a game program needs over [helix-platform](../platform/README.md) that isn't drawing:

| Package | What |
|---|---|
| `helix.services.time` | `Time`: the game's time, scaled and paused, its timers, real time beside it, frames a second, and a frame rate aimed for |
| `helix.services.input` | `Keyboard` (with typed text and repeats), `Mouse`, `Touch`, `Gamepads` and `Tilt`: each device held or pressed this frame; `Gestures`: taps, holds, drags, swipes and pinches; `Actions`: names bound to several of them |
| `helix.services.assets` | `Assets`: files by path, from a file system (`FileSystemSource`) or downloaded from an HTTP server (`ServerSource`) and kept as its cache decides: revalidated by the server's ETag and Last-Modified (`RevalidateCache`), trusted (`TrustCache`), held for the run (`MemoryCache`), or known by the server's manifests, shipped files read in place (`ManifestCache`); a program links only the sources and caches it constructs |
| `helix.services.audio` | `Audio`: sounds loaded whole, streamed or made from samples, their lengths, queues of samples played as they are added, voices played in groups with fades, their positions moved |
| `helix.services.images` | `Images`: image files by path, or images inside other bytes, decoded into pixels, or decoded for the GPU so a page never holds their pixels |
| `helix.services.models` | `Models`: glTF, GLB and OBJ models by path, with the files they name (buffers, material libraries) and their images decoded for the GPU, as meshes and materials |
| `helix.services.fonts` | `Fonts`: TrueType and OpenType fonts rasterized onto an atlas at a size, and BMFont files |
| `helix.services.screen` | `Screen`: a design size fitted to the window (letterboxed, pixel-perfect, stretched or expanded), fullscreen with the windowed size and place to go back to, resizes, and the window kept between runs |
| `helix.services.saves` | `Saves`: small values kept between runs, set before they are read if need be |
| `helix.services.config` | `Config`: the options the program was started with |
| `helix.services.shaders` | `Shader` and `ShaderVariants`: GLSL compiled while the program builds and known by name; `ShaderValues` and its kin: values by handle as `IGraphics.draw` takes them, layered over defaults, shared blocks and scenes; `ShaderPrograms`: programs and pipelines on the GPU; `Shaders`: shaders replaced in place when their files change |

## Using it

```
-lib helix-services
-D helix-company=<company>
-D helix-product=<product>
```

The two names are required. They say where the program's saves and cache are kept, so two programs keep apart, and natively
they name the program to the system. Each is one directory's name. A build without them fails, saying so.

Until it is on haxelib, install it and the libraries it depends on from GitHub:

```
haxelib git helix-math https://github.com/whirlinggizmo/helix main libs/math
haxelib git helix-formats https://github.com/whirlinggizmo/helix main libs/formats
haxelib git helix-platform https://github.com/whirlinggizmo/helix main libs/platform
haxelib git helix-geometry https://github.com/whirlinggizmo/helix main libs/geometry
haxelib git helix-log https://github.com/whirlinggizmo/helix main libs/log
haxelib git helix-services https://github.com/whirlinggizmo/helix main libs/services
```

A program polls each service that answers later once a frame, with the platform's adapters it was given: `Assets`, `Audio`, `Images`,
`Saves`, `Time` and the input devices are `IPollable`. One never polled never answers.

```haxe
var assets = new Assets([new ServerSource("", httpClient, new RevalidateCache(downloads))]);
// each frame:
httpClient.poll();
downloads.poll();
assets.poll();
```

## Examples

Each example in `examples/` shows one thing, and builds from the hxml files beside it, as the platform's do:

- `time`: one timer.
- `input`: one action, bound to a key and a gamepad button, over the keyboard and the gamepads.
- `touch`: every finger, by its id, as it lands and lifts.
- `config`: one option read.
- `saves`: one value loaded, set and written.
- `assets`: one file loaded.
- `audio`: one sound loaded and played.
- `fades`: a group fading its voices in, then `master` fading everything out.
- `stream`: one long sound played as it's read, as music is.
- `patch`: shipped files patched from a server, by its manifests (`ManifestCache`): with nothing kept, with the same manifests, after
  the server is updated, with the connection lost, and after a manifest drops a file, whose copy goes; only what changed is downloaded.
- `quad`: a shader compiled into the program, its values set by handle over defaults, drawn with `IGraphics` directly.
- `reload`: the same shader with its file, replaced in place when the assets hear it changed.

Its tests are in `tests/`.

The API reference is [api/](api/README.md), one page per package.
