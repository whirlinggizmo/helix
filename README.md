# helix

Helix is a suite of libraries and engines for Haxe game development.  It provides useful core libraries, platform abstractions, higher level services, and a game engine that mirrors [Raylib](https://github.com/raysan5/raylib)'s 5.5 API (with some [extras](https://whirlinggizmo.github.io/helix/api/helix/raylib/extras/index.html)). 

> **Work in progress.** No API is stable yet, and any name may change in any commit. Caveat Emptor.

## Components

### Libraries

| Library | Description | API | Dependencies |
|---|---|---|---|
| [helix-platform](libs/platform/README.md) | Provides access to hardware and OS functions via adapters and interfaces | [API](https://whirlinggizmo.github.io/helix/api/helix/platform/index.html) | helix-math, helix-formats |
| [helix-math](libs/math/README.md) | Points, bounds, matrices, curves, interpolation, deterministic trigonometry and random numbers | [API](https://whirlinggizmo.github.io/helix/api/helix/math/index.html) |  |
| [helix-geometry](libs/geometry/README.md) | Cameras, frustums, rays, meshes in the usual shapes, and tests on segments, triangles and polygons | [API](https://whirlinggizmo.github.io/helix/api/helix/geometry/index.html) | helix-math |
| [helix-formats](libs/formats/README.md) | File formats read into plain data: glTF 2.0 and GLB models, BMFont text fonts, TrueType and OpenType font tables | [API](https://whirlinggizmo.github.io/helix/api/helix/formats/index.html) | helix-math |
| [helix-log](libs/log/README.md) | Levels and tags, to the browser's console or the process's output | [API](https://whirlinggizmo.github.io/helix/api/helix/log/index.html) |  |
| [helix-services](libs/services/README.md) | Time, input, assets, audio, images, saves and config over the platform | [API](https://whirlinggizmo.github.io/helix/api/helix/services/index.html) | helix-platform, helix-geometry, helix-math, helix-log |
| [helix-render](libs/render/README.md) | Drawing: 2D and 3D batches, draw lists, text, materials, lights, shadows, environment maps and post-processing. Being built in stages | [API](https://whirlinggizmo.github.io/helix/api/helix/render/index.html) | helix-services, helix-platform, helix-formats, helix-geometry, helix-math, helix-log |

### Engines

| Engine | Description | API | Dependencies |
|---|---|---|---|
| [helix-raylib](engines/raylib/README.md) | raylib 5.5's API over the services and the platform | [API](https://whirlinggizmo.github.io/helix/api/helix/raylib/index.html) | helix-services, helix-platform, helix-geometry, helix-math |

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
- [docs/PLATFORM.md](docs/PLATFORM.md): each platform interface, what it means and what each adapter does.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): interfaces, adapters and the adapter rule.
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout and doc comments.
- [The API reference](https://whirlinggizmo.github.io/helix/api/index.html), generated from the doc comments. Each library's `api/`
  directory holds the same as Markdown.
- [docs/benchmarks.md](docs/benchmarks.md): the measurements. [docs/sizes.md](docs/sizes.md) is each library's web size ladder, and
  [docs/speed.md](docs/speed.md) is speed and size against raylib C, Godot, three.js, Lime and HeliX.
- [docs/ROADMAP.md](docs/ROADMAP.md): what's next. [docs/DECISIONS.md](docs/DECISIONS.md): why things are the way they are.

## License

zlib. See [LICENSE](LICENSE).
