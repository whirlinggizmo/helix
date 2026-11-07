# helix

Write a game once in Haxe and run it in a browser page or as a native program. The libraries are small and plain: a 2D bunnymark is a 44 KB
gzip download, a whole game about 130 KB. On top of them sits raylib's API, so anyone who knows raylib, or any model trained on it, can
start writing.

> **Work in progress.** No API is stable yet, and any name may change in any commit. There are no releases to pin.

## What's here

| Library | What it is | Needs (haxelib.json) |
|---|---|---|
| [helix-platform](libs/platform/README.md) | The hardware and the OS as contracts (window, events, GPU, audio, decoders, HTTP, files, export, system), one adapter per API: the browser's, SDL3, WebGL2, sokol_gfx, SDL_GPU, SDL3_mixer | helix-math, helix-formats |
| [helix-math](libs/math/README.md) | Points, bounds, matrices, curves, interpolation, deterministic trigonometry and random numbers | nothing |
| [helix-geometry](libs/geometry/README.md) | Cameras, frustums, rays, meshes in the usual shapes, and tests on segments, triangles and polygons | helix-math |
| [helix-formats](libs/formats/README.md) | File formats read into plain data: glTF 2.0 and GLB models, BMFont text fonts, TrueType and OpenType font tables | helix-math |
| [helix-log](libs/log/README.md) | Levels and tags, to the browser's console or the process's output | nothing |
| [helix-services](libs/services/README.md) | Time, input, assets, audio, images, saves and config over the platform | helix-platform, helix-geometry, helix-math, helix-log |
| [helix-render](libs/render/README.md) | Drawing: 2D and 3D batches, draw lists, text, materials, lights, shadows, environment maps and post-processing. Being built in stages | helix-services, helix-platform, helix-formats, helix-geometry, helix-math, helix-log |

The libraries are plain. A program constructs what it uses and nothing runs on its own. An engine on top may run the loop:

| Engine | What it is | Needs (haxelib.json) |
|---|---|---|
| [helix-raylib](engines/raylib/README.md) | raylib 5.5's API over the services and the platform, 2D and 3D, in a page and natively | helix-services, helix-platform, helix-geometry, helix-math |

## Try it

The libraries aren't published yet, so point haxelib at the checkout once:

```console
for lib in platform math geometry formats log services render; do haxelib dev helix-$lib <checkout>/libs/$lib; done
haxelib dev helix-raylib <checkout>/engines/raylib
```

Then build an example both ways:

```console
cd engines/raylib/examples/basic
haxe build-web.hxml      # web/app.js: serve web/ with any static server and open index.html
haxe build-native.hxml   # native/Main, with hxcpp and SDL3 installed (CONTRIBUTING.md has the prerequisites)
```

## Documents

- [GOALS.md](GOALS.md): what the libraries are for.
- [CONTRIBUTING.md](CONTRIBUTING.md): prerequisites, the checks, the tools and how work runs.
- [docs/PLAN.md](docs/PLAN.md): the layers, what makes a library, and how the next one is built.
- [docs/PLATFORM.md](docs/PLATFORM.md): each platform contract, what it means and what each adapter does.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): contracts, adapters and the adapter rule.
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout and doc comments.
- [docs/api/](docs/api/README.md): the API reference, generated from the doc comments.
- [docs/benchmarks.md](docs/benchmarks.md): the measurements. [docs/sizes.md](docs/sizes.md) is each library's web size ladder, and
  [docs/speed.md](docs/speed.md) is speed and size against raylib C, Godot, three.js, Lime and HeliX.
- [docs/ROADMAP.md](docs/ROADMAP.md): what's next. [docs/DECISIONS.md](docs/DECISIONS.md): why things are the way they are.

## License

zlib: [LICENSE](LICENSE), with a copy in each library's directory (haxelib.json says BSD, as haxelib has no zlib). A program built with
the libraries owes no notice. A copy of their source keeps it. What a library includes of others' work, each with its license, is in its
README's Credit section ([helix-platform](libs/platform/README.md#credit), [helix-math](libs/math/README.md#credit),
[helix-geometry](libs/geometry/README.md#credit), [helix-raylib](engines/raylib/README.md#credit)). None of it asks anything of a built
program either.
