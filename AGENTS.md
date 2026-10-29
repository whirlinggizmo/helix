# Agent instructions: helix-2.0

helix-2.0 is a Haxe game framework built as layered libraries: Haxe → JS for the browser, Haxe → hxcpp/C++ natively. Read
[GOALS.md](GOALS.md), then [docs/PLAN.md](docs/PLAN.md) and [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before changing code; what's
next is in [docs/ROADMAP.md](docs/ROADMAP.md).

## Rules

- **A program constructs what it uses.** Nothing in a library installs itself, runs a loop, is reached through a static that builds it,
  or is bundled with everything else. When a design answer starts from "the engine does it this way", ask instead what a program using
  the library directly would construct.
- **HeliX is prior art, not a source.** [HeliX](https://github.com/whirlinggizmo/helix), and the earlier C frameworks (`../wgrender-c`,
  `../libwgf`), are read for how they did a thing and the platform quirks they found. Then write this library's own code. Don't name
  libwgf in code or docs.
- **The spec is the authority.** docs/PLATFORM.md for the platform; each library above gets its own before it's written. A library
  changes when it doesn't do what its spec says, or when the spec changes first.
- **No backward compatibility.** When an API changes, every caller changes in the same commit.
- **Follow docs/CONVENTIONS.md** and docs/ARCHITECTURE.md (the adapter rule). Every public type and member has a doc comment. Run the
  formatter rather than laying code out by hand.

## Working

- **Checks:** `python3 tools/check_types.py --no-output` after an API change; `python3 helix.py test`, `tools/format.py --check` and
  `tools/check_docs.py` before committing; native builds and `tools/platform_checks.py` at the end of a feature.
- **Never open native windows on the user's desktop.** Use `tools/private_display.py`, and `SDL_AUDIO_DRIVER=dummy` so checks make no sound.
- **Report what ran,** on which target. Measure before claiming something is faster or smaller.
- **Ask before pushing,** opening a pull request, creating repositories or publishing packages.
