# HeliX

HeliX is a Haxe game framework. One Haxe program runs in the browser (Haxe → JS, WebGL2, Web Audio, Fetch, IndexedDB) and on the desktop (Haxe → hxcpp/C++, Sokol, libsndfile, evdev). Games use the same Haxe interfaces on both. Thin adapters supply each platform's services underneath them; a named profile picks the adapters for a build. Framework and game code have no target conditionals.

> **Work in progress: caveat emptor.** HeliX is not yet stable, and backward compatibility is not a consideration. Any API, name or file layout may change in any commit, with every caller in this repository changed alongside and no deprecation period. There are no releases or versions to pin yet. If you build on it, pin a commit and expect to update your code when you move.

**Status:** milestones 1–6 are done (the platform, 2D and services; 3D basics; 2D stages and the rest of 2D; advanced 3D, through skinning and animation; scene and pick; UI). Milestone 7 (native network streaming) is next. Every example runs in the browser and natively on Linux/X11; Windows, macOS and mobile have not run.

## Try it

With Haxe 4.3.7, Python 3 and `sokol-shdc` (the rest, and the native toolchain: [BUILDING.md](BUILDING.md)):

```console
python3 tools/example.py animation dev --shdc /path/to/sokol-shdc   # http://localhost:8060/, hot reload as you edit
python3 tools/example.py animation build native                   # build/native/animation/Main
```

## Documents

- [BUILDING.md](BUILDING.md): prerequisites and pins, building, the dev loop, the checks, the repository's layout.
- [docs/EXAMPLES.md](docs/EXAMPLES.md): every example, and the larger games (Asteroids, Blocks).
- [docs/ROADMAP.md](docs/ROADMAP.md): what comes next.
- [docs/HISTORY.md](docs/HISTORY.md): what was built, milestone by milestone.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the engine, the platform contracts and their adapters, and the rule for what an adapter may hold.
- [docs/INTERFACE.md](docs/INTERFACE.md): the contracts and their limits.
- [docs/CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout, and how examples are developed.
- [docs/DECISIONS.md](docs/DECISIONS.md): why things are the way they are, numbered, in order.
- [docs/API_FINDINGS.md](docs/API_FINDINGS.md): known API problems, fixed and open.
- [docs/PACKAGING.md](docs/PACKAGING.md): tooling, autopilot and the road to a haxelib.
- [docs/ADAPTER_AUDIT.md](docs/ADAPTER_AUDIT.md): the adapter audit of 2026-10-14, what it found and how each step landed.

## License

MIT: [LICENSE](LICENSE). Third-party code, fonts and assets keep their own licenses: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md); the examples' assets: [examples/assets/CREDITS.md](examples/assets/CREDITS.md).

HeliX began as experiment 05 of whirlinggizmo's framework architecture study. That study keeps its comparison and measurements; this repository carries HeliX's history from it ([docs/HISTORY.md](docs/HISTORY.md)).
