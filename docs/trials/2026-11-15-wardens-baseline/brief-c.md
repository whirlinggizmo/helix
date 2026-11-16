Build the game in `{DIR}/spec.md` in C with **raylib 5.5** (`#include "raylib.h"`, with `raymath.h`, `rlgl.h`, `raygui.h` and the examples' `rlights.h`).

- **Docs:** raylib 5.5's headers are in `{DIR}/include/` and its C examples, with their shaders, in `{DIR}/docs/examples/`. Read them as you need. Read nothing else: no web.
- **Assets:** the game's files are in `{DIR}/assets/`. The program names them by their paths from this directory, as `"assets/characters/Adventurer_Body.glb"`.
- **Building:** in `{DIR}`, `cmake -B build && cmake --build build` builds the program natively as `native/wardens`: every `.c` here, against raylib 5.5's library (`lib/libraylib.a`). You may change `CMakeLists.txt`. Build as often as you like.
- **Running:** `./native/wardens [arguments]` from `{DIR}` runs it, passing it the arguments (as `--enemies=50 --seed=1`). It runs on a display of its own, never on the desktop, with no sound. The program must exit on its own, as your shell waits for it, so give it a way to stop (an argument naming the frames to run, say). To see the game, save screenshots with raylib's call for it and look at them.
- **Touch:** the display here has no touch screen, so the touch controls can't be tried. Write them as the spec says.
- **Writing:** write to `{DIR}` only: the game's `.c` and `.h` files, its shaders, and `CMakeLists.txt`, then `NOTES.md` with each build error you hit, in order, and what you changed for it; each place raylib's API had no call for what the spec asks and what you did instead; each place you were left guessing and what you guessed; and anything you expect not to work.
- **Budget:** stop at 3 hours or when the spec is met, whichever comes first, and reply with one line saying which.
