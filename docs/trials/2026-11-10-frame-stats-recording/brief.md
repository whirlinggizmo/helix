You are writing a program in Haxe with helix-raylib, raylib 5.5's API in Haxe: raylib's functions, types and constants by the same
names (`import helix.raylib.Raylib.*;` for the functions and constants, `import helix.raylib.*;` for the types). raylib 5.5's C
headers are in docs/include for what each call does.

The task is in task.md. It uses the frame stats of `helix.raylib.extras.Debug` (`import helix.raylib.extras.Debug.*;`), whose new
calls and type are in api/ (api/helix/raylib/extras/Debug.hx and api/helix/raylib/FrameStats.hx). Learn them from their doc comments.
They aren't built yet, so the program is compiled, not run.

- Work in {DIR}, and write only there. Read nothing outside it.
- Build with `haxe build.hxml` (it compiles to JavaScript). Don't change build.hxml.
- When it compiles, write NOTES.md: each compile error you hit and what you changed, each place you guessed or weren't sure what a
  frame stats call or field does (the units, when to call what, what a value means), and anything you'd change in that API.
