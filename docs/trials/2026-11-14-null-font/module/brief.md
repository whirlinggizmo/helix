Write the program in `{DIR}/task.md` in Haxe, using **raylib 5.5's API**.

- **How raylib looks here.** This is raylib 5.5 in Haxe. `raylib.h` is the class `helix.raylib.Raylib`, and `import helix.raylib.Raylib.*;` brings its functions, constants and colors in unqualified, as raylib names them. raylib's structs are classes of the same names and fields in `helix.raylib` (`import helix.raylib.*;`). Write it as you would write a raylib program.
- **Docs:** raylib 5.5's own headers are in `{DIR}/docs/include/` and its C examples in `{DIR}/docs/examples/`. helix-raylib's pages for text and textures are in `{DIR}/docs/api/` (`text.md`, `textures.md`). Read them as you need. Read nothing else about the library: no library sources, no other documentation, no web. Where it differs from raylib in C, the compiler tells you.
- **Assets:** the program's files are in `{DIR}/assets/`, named by their paths from this directory, as `"assets/ui/font.ttf"`.
- **Building:** in `{DIR}`, `haxe build.hxml` builds the program natively as `native/Main`. Don't change `build.hxml`. Build as often as you like.
- **Running:** `./native/Main [arguments]` from `{DIR}` runs it, passing it the arguments (as `--frames=120`). It runs on a display of its own, never on the desktop, with no sound. What it logs is printed. Look at `shot.png` to see it.
- **Writing:** write to `{DIR}` only: `Main.hx`, then `NOTES.md` with each compile error you hit, in order, and what you changed for it; each warning the program logged and what you changed for it; each place you were left guessing and what you guessed.
- **Budget:** stop at 30 minutes or when the task is done, whichever comes first, and reply with one line saying which.
