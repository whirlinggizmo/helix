# helix.macro

[Back to the index](README.md)

## Haxelib

*class* in `src/helix/macro/Haxelib.hx`

What a build on `-lib helix` needs beyond the library's class path, run by the library's extraParams.hxml (`--macro helix.macro.Haxelib.configure()`), so a game's hxml carries nothing of the library's layout: - the generated code's class paths, `generated/shaders` and `generated/fonts` at the library's root (the framework's programs, the packed shader library and the built-in font, committed and shipped: docs/DECISIONS.md 138), and `generated/shaders-sdlgpu` when the build defines `helix_sdl3_gpu` (SDL_GPU's dialects, which only its builds carry); - natively, hxcpp's architecture define for this machine, `HXCPP_ARM64` on arm64 and `HXCPP_M64` elsewhere, when the build sets none (hxcpp picks 32-bit on Windows from a 64-bit process, which has no `PROCESSOR_ARCHITEW6432`). The repository's own builds list the class paths and the define themselves (`tools/example.py`), which is also what the dev loop watches.
