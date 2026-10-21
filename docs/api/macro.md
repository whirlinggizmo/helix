# helix.macro

[Back to the index](README.md)

## AppBuild

*class* in `src/helix/macro/AppBuild.hx`

The build macro behind helix.App, run on every class extending it (`@:autoBuild`). It writes into the subclass what a native hot reload needs and what the build's backend decides, so a game writes neither: - `@:hot public static var hotApp`, the app object `new` made, and `@:hot static function hotInit()`, `hotFrame(dt)` and `hotCleanup()`, each calling the app in `hotApp`: hotreload-hx's springboards. The Runner, compiled once into the executable, reaches the game only through them (a Springboard of lambdas calling them by name), so a native reload re-points the calls at the new module and migrates `hotApp` with the other `@:hot` statics; in the browser they cost nothing. They're written here, in the game's own class, because a `@:hot` static in the library's App would make the library reloaded code, and because hotreload-hx's global build, which turns `@:hot` into what a reload needs, runs after a parent's `@:autoBuild` and before a class's own `@:build` (checked with Haxe 4.3.7), so fields this macro adds are seen as written. - `hotSpringboard()`, giving App the Springboard over those statics, and `hotStart(identity, springboard)`, running the profile of the backend the build names with `-D helix-backend=` (BACKENDS); a build naming none, or one not in the list, fails here, naming the choices, and an `sdl3-gpu` build without `helix_sdl3_gpu` (the define the programs carry SDL_GPU's dialects under; `-lib helix` defines it from the backend, helix.macro.Haxelib, and the repository's builds pass it) too. A subclass can't declare a field of those names.

```haxe
static final BACKENDS(default, null):Array<String>
static function profileOf(backend:String):Null<String>
static function isBrowser(backend:String):Bool
static final WRITTEN(default, null):Array<String>
```

- `BACKENDS`: The backends a build may name with -D helix-backend=, each the name of a build's backend (docs/CONVENTIONS.md): the browser's webgl2, and natively sokol-gl, sdl3-gl and sdl3-gpu.
- `profileOf`: The profile class (helix.profiles) that runs backend, or null for a name not in BACKENDS.
- `isBrowser`: Whether backend draws in a browser (its profile takes an asset URL and a manifest) rather than natively (an asset directory).
- `WRITTEN`: The fields the macro writes, which a subclass can't declare itself.

## Haxelib

*class* in `src/helix/macro/Haxelib.hx`

What a build on `-lib helix` needs beyond the library's class path, run by the library's extraParams.hxml (`--macro helix.macro.Haxelib.configure()`), so a game's hxml carries nothing of the library's layout: - the generated code's class paths, `generated/shaders` and `generated/fonts` at the library's root (the framework's programs, the packed shader library and the built-in font, committed and shipped: docs/DECISIONS.md 138), and `generated/shaders-sdlgpu` for an SDL_GPU build (SDL_GPU's dialects, which only its builds carry); - `helix_sdl3_gpu`, the define the programs carry SDL_GPU's dialects under, when the build names the `sdl3-gpu` backend (`-D helix-backend=sdl3-gpu`), so a game's hxml writes the backend and nothing else of it; - in the browser, the page beside the `-js` output (`helix.tools.Build.generateWebPage`: `index.html` from the library's template, `favicon.svg`, the game's `config.json`), so the dev loop's server has a page to serve; - natively, hxcpp's architecture define for this machine, `HXCPP_ARM64` on arm64 and `HXCPP_M64` elsewhere, when the build sets none (hxcpp picks 32-bit on Windows from a 64-bit process, which has no `PROCESSOR_ARCHITEW6432`). The repository's own builds list the class paths and the defines themselves (`tools/example.py`), which is also what the dev loop watches.
