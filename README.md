# helix-2.0

A Haxe game framework built as layered libraries: one Haxe program runs in the browser (Haxe → JS) and natively (Haxe → hxcpp/C++).

> **Work in progress.** No API is stable yet, and any name may change in any commit. There are no releases to pin.

| Library | What it is | Depends on |
|---|---|---|
| [helix-platform](platform/README.md) | The hardware and the OS as contracts (window, events, GPU, audio, decoders, HTTP, files, export, system), one adapter per API: the browser's, SDL3, WebGL2, sokol_gfx, SDL_GPU, SDL3_mixer | nothing |
| [helix-math](math/README.md) | Points, bounds, curves, interpolation, deterministic trigonometry and random numbers | nothing |
| [helix-log](log/README.md) | Levels and tags, to the browser's console or the process's output | nothing |
| [helix-services](services/README.md) | Time, input, assets, audio, saves and config over the platform; its API alone so far | helix-platform, helix-math, helix-log |

Until they're published:

```console
haxelib dev helix-platform <checkout>/platform
haxelib dev helix-math <checkout>/math
haxelib dev helix-log <checkout>/log
haxelib dev helix-services <checkout>/services
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

MIT: [LICENSE](LICENSE). Third-party code keeps its own license: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
