You are writing a program in Haxe with helix-raylib, raylib 5.5's API in Haxe: raylib's functions, types and constants by the same
names (`import helix.raylib.Raylib.*;` for the functions and constants, `import helix.raylib.*;` for the types, `import helix.raylib.Raygui.*;`
for raygui's). raylib 5.5's C headers are in docs/include for what each call does.

The task is in task.md. It uses one of helix-raylib's extras, whose doc comments are in api/: `helix.raylib.extras.GuiSkins`
(api/helix/raylib/extras/GuiSkins.hx, raygui's controls drawn from textures, with its type in GuiSkin.hx). It's imported apart
(`import helix.raylib.extras.GuiSkins.*;`). Learn it from its doc
comments. Some of its calls aren't built yet, so the program is compiled, not run.

- Work in {DIR}, and write only there. Read nothing outside it.
- The program is native. `haxe build.hxml` checks it, compiling it for C++ without building the binary. Don't change build.hxml.
- When it compiles, write NOTES.md: each compile error you hit and what you changed, each place you guessed or weren't sure what a
  call or value of that extra does (which call fits, what a value means, where a thing is drawn), and anything you'd change in
  its API.
