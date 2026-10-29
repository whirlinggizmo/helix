# Third-party notices

What the libraries include or link that they didn't write, with each one's license. The license texts are beside the files in `platform/vendor/`. Versions and SHA256 pins are in `dependencies.json`.

| Part | Where | Used for | License | Text |
| --- | --- | --- | --- | --- |
| [Sokol](https://github.com/floooh/sokol), through the Whirling Gizmo fork [whirlinggizmo/sokol](https://github.com/whirlinggizmo/sokol) | `platform/vendor/sokol_gfx.h`, `platform/vendor/sokol_log.h` | native graphics on GL | zlib; the fork's altered headers say so at their tops | `platform/vendor/LICENSE` |
| [stb_image](https://github.com/nothings/stb) v2.30 | `platform/vendor/stb/stb_image.h` | native image decoding (PNG, JPEG, BMP, TGA, GIF) | public domain, or MIT | at the end of the header |
| [SDL](https://github.com/libsdl-org/SDL) 3.4.18 | `platform/vendor/sdl3/SDL3/` (its headers); the library is built or fetched into `build/deps` by `tools/sdl3.py`, or the system's (3.4.18 or newer) | the SDL3 adapters' window, input, gamepads, audio and (SDL_GPU) graphics | zlib | `platform/vendor/sdl3/LICENSE.txt` |
| [SDL3_mixer](https://github.com/libsdl-org/SDL_mixer) 3.2.4 | `platform/vendor/sdl3_mixer/` (its sources), compiled with the program | native audio output, mixing and decoding (WAV, Ogg Vorbis, MP3, FLAC) | zlib | `platform/vendor/sdl3_mixer/LICENSE.txt` |
| [stb_vorbis](https://github.com/nothings/stb), in SDL3_mixer | `platform/vendor/sdl3_mixer/src/stb_vorbis/` | native Ogg Vorbis decoding | public domain, or MIT | at the end of the header |
| [dr_mp3 and dr_flac](https://github.com/mackron/dr_libs), in SDL3_mixer | `platform/vendor/sdl3_mixer/src/dr_libs/` | native MP3 and FLAC decoding | public domain, or MIT No Attribution | `platform/vendor/sdl3_mixer/src/dr_libs/LICENSE` |

Tools that run while building, and whose code isn't in builds: glslang (BSD-3-Clause and others, its `LICENSE.txt`) and SPIRV-Cross (Apache-2.0). Their output, the shaders, is the program's.

The zlib licenses ask for their notices to go with what includes them: a program built with the native adapters ships this file and the license texts it names.
