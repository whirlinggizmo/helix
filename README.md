# HeliX

HeliX is a Haxe game framework. One Haxe program runs in the browser (Haxe → JS, WebGL2, Web Audio, Fetch, IndexedDB) and on the desktop (Haxe → hxcpp/C++, Sokol, libsndfile, evdev or XInput gamepads). Games use the same Haxe interfaces on both. Thin adapters supply each platform's services underneath them; a named profile picks the adapters for a build. Framework and game code have no target conditionals.

> **Work in progress: caveat emptor.** HeliX is not yet stable, and backward compatibility is not a consideration. Any API, name or file layout may change in any commit, with every caller in this repository changed alongside and no deprecation period. There are no releases or versions to pin yet. If you build on it, pin a commit and expect to update your code when you move.

**Status:** milestones 1–7, 9 and 10 are done (the platform, 2D and services; 3D basics; 2D stages and the rest of 2D; advanced 3D, through skinning and animation; scene and pick; UI; Windows, macOS and CI; the small utilities; scenes and flow), and the API reworked in Haxe's own terms (properties, kinds as classes, services as static classes). SDL3 as a second native profile is under way (its window, input, audio, and graphics on GL or SDL_GPU: Vulkan, Direct3D 12, Metal), then native network streaming. Every example runs in the browser and natively on Linux/X11, and builds natively on Windows and macOS; on Windows both games have run in a window. macOS is built for in full; beyond CI's builds and unit tests, only CI's virtual Mac has run it (both games under SDL_GPU on Metal), not a real one; iOS waits for a Mac that can run it. CI checks all three. Mobile has not run.

## Try it

In the browser: **[the examples](https://whirlinggizmo.github.io/helix/)**, each running on WebGL2, and **[the API reference](https://whirlinggizmo.github.io/helix/api/)**.

Locally, with Haxe 4.3.7, Python 3 and `sokol-shdc` (the rest, and the native toolchain: [BUILDING.md](BUILDING.md)):

```console
python3 tools/example.py animation dev   # http://localhost:8060/, hot reload as you edit
python3 tools/example.py animation build release-sokol-gl         # out/linux-x64/release-sokol-gl/bin/animation/animation
```

## Documents

- [BUILDING.md](BUILDING.md): prerequisites and pins, building, the dev loop, the checks, the repository's layout.
- [docs/EXAMPLES.md](docs/EXAMPLES.md): every example, and the larger games (Asteroids, Blocks).
- [docs/ROADMAP.md](docs/ROADMAP.md): what comes next.
- [docs/HISTORY.md](docs/HISTORY.md): what was built, milestone by milestone.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the engine, the platform contracts and their adapters, and the rule for what an adapter may hold.
- [docs/INTERFACE.md](docs/INTERFACE.md): the contracts and their limits.
- [docs/SCENE_FILE.md](docs/SCENE_FILE.md): the `.scene` file's format, its loading and capture, and a behavior's shape.
- [docs/api/](docs/api/README.md): the API reference, a file a package, generated from the doc comments (the site's HTML is the same).
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout, and how examples are developed.
- [docs/DECISIONS.md](docs/DECISIONS.md): why things are the way they are, numbered, in order.
- [docs/API_FINDINGS.md](docs/API_FINDINGS.md): known API problems, fixed and open.
- [docs/PACKAGING.md](docs/PACKAGING.md): tooling, autopilot and the road to a haxelib.
- [docs/ADAPTER_AUDIT.md](docs/ADAPTER_AUDIT.md): the adapter audit of 2026-10-14, what it found and how each step landed.

## License

MIT: [LICENSE](LICENSE). Third-party code, fonts and assets keep their own licenses: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md); the examples' assets: [examples/assets/CREDITS.md](examples/assets/CREDITS.md).

HeliX began as experiment 05 of whirlinggizmo's framework architecture study. That study keeps its comparison and measurements; this repository carries HeliX's history from it ([docs/HISTORY.md](docs/HISTORY.md)).
