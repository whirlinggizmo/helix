# helix-services

What a game program needs over [helix-platform](../platform/README.md) that isn't drawing:

| Package | What |
|---|---|
| `helix.services.time` | `Time`: the game's time, scaled and paused, its timers, real time beside it, frames a second, and a frame rate aimed for |
| `helix.services.input` | `Keyboard` (with typed text and repeats), `Mouse`, `Touch`, `Gamepads` and `Tilt`: each device held or pressed this frame; `Gestures`: taps, holds, drags, swipes and pinches; `Actions`: names bound to several of them |
| `helix.services.assets` | `Assets`: files by path, from a file system or downloaded from an HTTP server and kept |
| `helix.services.audio` | `Audio`: sounds loaded whole, streamed or made from samples, their lengths, queues of samples played as they are added, voices played in groups with fades, their positions moved |
| `helix.services.images` | `Images`: image files by path, or images inside other bytes, decoded into pixels |
| `helix.services.models` | `Models`: glTF, GLB and OBJ models by path, with the files they name (buffers, material libraries) and their images, as meshes and materials |
| `helix.services.fonts` | `Fonts`: TrueType and OpenType fonts rasterized onto an atlas at a size, and BMFont files |
| `helix.services.screen` | `Screen`: a design size fitted to the window (letterboxed, pixel-perfect, stretched or expanded), fullscreen with the windowed size and place to go back to, resizes, and the window kept between runs |
| `helix.services.saves` | `Saves`: small values kept between runs, set before they are read if need be |
| `helix.services.config` | `Config`: the options the program was started with |
| `helix.services.shaders` | `Shader` and `ShaderVariants`: GLSL compiled while the program builds and known by name; `ShaderValues` and its kin: values by handle as `IGraphics.draw` takes them, layered over defaults, shared blocks and scenes; `ShaderPrograms`: programs and pipelines on the GPU; `Shaders`: shaders replaced in place when their files change |

## Using it

```
-lib helix-services
```

Until it is published, link it, and the libraries it's built on (helix-platform, helix-formats, helix-math and helix-log), from a checkout:

```
haxelib dev helix-services <checkout>/services
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
- `patch`: shipped files patched from a server, by its manifests: with nothing kept, with the same manifests, and after the server
  is updated; only what changed is downloaded.
- `quad`: a shader compiled into the program, its values set by handle over defaults, drawn with `IGraphics` directly.
- `reload`: the same shader with its file, replaced in place when the assets hear it changed.

Its tests are in `tests/`.

The API reference is [docs/api/](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/README.md), one page per package.
