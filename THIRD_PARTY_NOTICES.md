# Third-party notices

What HeliX builds include or link that it didn't write, with each one's license. The license texts are beside the files in `vendor/`, and builds that include a part ship its notice with them (see "In builds" below). Versions and SHA256 pins are in `dependencies.json`.

| Part | Where | Used for | License | Text |
| --- | --- | --- | --- | --- |
| [Sokol](https://github.com/floooh/sokol), through the Whirling Gizmo fork [whirlinggizmo/sokol](https://github.com/whirlinggizmo/sokol) | `vendor/sokol_*.h` | native window, graphics and audio | zlib; the fork's altered headers say so at their tops | `vendor/LICENSE` |
| [sokol_utils](https://github.com/squk/sokol_utils), through the Whirling Gizmo fork [whirlinggizmo/sokol_utils](https://github.com/whirlinggizmo/sokol_utils) | `vendor/sokol_utils/sokol_app_utils.h` | native window size, position, displays, style, visibility | zlib; altered, as its top says | `vendor/sokol_utils/LICENSE` |
| [stb_image](https://github.com/nothings/stb) v2.30 | `vendor/stb/stb_image.h` | native image decoding (PNG, JPEG, BMP, TGA, GIF) | public domain, or MIT | at the end of the header |
| [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) Regular, Copyright 2020 The JetBrains Mono Project Authors | `vendor/fonts/JetBrainsMono/` | the built-in font: its printable ASCII, baked into a distance-field atlas compiled into the program | SIL Open Font License 1.1 | `vendor/fonts/JetBrainsMono/OFL.txt` |
| [SDL](https://github.com/libsdl-org/SDL) 3.4.18 | `vendor/sdl3/SDL3/` (its headers); the library is built or fetched into `build/deps` by `tools/sdl3.py`, or the system's (3.4.18 or newer) | the SDL3 profiles' window, input, gamepads, audio and (SDL_GPU) graphics | zlib | `vendor/sdl3/LICENSE.txt` |
| [libsndfile](https://github.com/libsndfile/libsndfile) 1.2.2 | `vendor/sndfile/sndfile.h`; the library is the system's | native audio decoding (Ogg Vorbis, Opus, MP3), dynamically linked | LGPL 2.1 | `vendor/sndfile/COPYING` |

Tools that run while building, and whose code isn't in builds: sokol-shdc (sokol-tools-bin, MIT), glslang (BSD-3-Clause and others, its `LICENSE.txt`) and SPIRV-Cross (Apache-2.0). Their output, the shaders, is HeliX's.

Examples' assets (images, sounds, fonts) are credited in `examples/assets/CREDITS.md`.

## In builds

The OFL asks that the font's copyright notice and license go with it wherever it is distributed, and the zlib and LGPL licenses ask for their notices too. A build that includes the built-in font or the native adapters copies this file and the license texts it names into its output, under `licenses/`, with HeliX's own MIT license (`HeliX-MIT.txt`), since every build contains HeliX's code.
