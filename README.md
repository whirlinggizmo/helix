# helix-2.0

A Haxe game framework built as layered libraries: one Haxe program runs in the browser (Haxe → JS) and natively (Haxe → hxcpp/C++).

> **Work in progress.** No API is stable yet, and any name may change in any commit. There are no releases to pin.

| Library | What it is | Depends on |
|---|---|---|
| [helix-platform](platform/README.md) | The hardware and the OS as contracts (window, events, GPU, audio, decoders, HTTP, files, export, system), one adapter per API: the browser's, SDL3, WebGL2, sokol_gfx, SDL_GPU, SDL3_mixer | nothing |
| [helix-math](math/README.md) | Points, bounds, matrices, curves, interpolation, deterministic trigonometry and random numbers | nothing |
| [helix-log](log/README.md) | Levels and tags, to the browser's console or the process's output | nothing |
| [helix-services](services/README.md) | Time, input, assets, audio, images, saves and config over the platform | helix-platform, helix-math, helix-log |
| [helix-ray](ray/README.md) | raylib 5.5's API over the services and the platform, 2D and 3D, in a page and natively (on trial, branch `raylib-slice`) | helix-services, helix-platform, helix-math |

Until they're published:

```console
haxelib dev helix-platform <checkout>/platform
haxelib dev helix-math <checkout>/math
haxelib dev helix-log <checkout>/log
haxelib dev helix-services <checkout>/services
haxelib dev helix-ray <checkout>/ray
```

## Documents

- [GOALS.md](GOALS.md): what the libraries are for.
- [BUILDING.md](BUILDING.md): prerequisites, the checks and the tools.
- [docs/PLAN.md](docs/PLAN.md): the layers, what makes a library, and how the next one is built.
- [docs/PLATFORM.md](docs/PLATFORM.md): each platform contract, what it means and what each adapter does.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): contracts, adapters and the adapter rule.
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout and doc comments.
- [docs/api/](docs/api/README.md): the API reference, generated from the doc comments.
- [docs/benchmarks.md](docs/benchmarks.md): web sizes, each library's ladder.
- [docs/ROADMAP.md](docs/ROADMAP.md): what's next. [docs/DECISIONS.md](docs/DECISIONS.md): why things are the way they are.

## License

zlib: [LICENSE](LICENSE), a copy in each library's directory (haxelib.json says BSD, as haxelib has no zlib). A program built with the
libraries owes no notice; a copy of their source keeps it. What a library includes of others' work, each with its license, is in its
README's Credit section ([helix-platform](platform/README.md#credit), [helix-math](math/README.md#credit),
[helix-ray](ray/README.md#credit)); none of it asks anything of a built program either.
