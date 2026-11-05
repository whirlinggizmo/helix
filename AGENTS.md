# Agent instructions: helix-2.0

helix-2.0 is a Haxe game framework built as layered libraries: Haxe → JS for the browser, Haxe → hxcpp/C++ natively. Read
[GOALS.md](GOALS.md), then [docs/PLAN.md](docs/PLAN.md) and [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before changing code; what's
next is in [docs/ROADMAP.md](docs/ROADMAP.md).

## Rules

- **Platform and services are constructed.** A program constructs the adapters and services it uses; nothing in them installs itself,
  runs a loop, is reached through a static that builds it, or is bundled with everything else. When a design answer for them starts
  from "the engine does it this way", ask instead what a program using them directly would construct. The layers above (the runner, an
  engine wearing a known API) may own the loop, and build a feature when its API is first touched where the API they match requires it
  (DECISIONS 15).
- **HeliX is prior art.** [HeliX](https://github.com/whirlinggizmo/helix), and the earlier C frameworks (`../wgrender-c`, `../libwgf`),
  are read for how they did a thing and the platform quirks they found. Useful code may be cribbed, refactored to this library's
  conventions and needs, or this library's own written instead; HeliX's design (its runner, statics, profiles) is never a reason for
  this library's shape. Don't name libwgf in code or docs.
- **The spec is the authority.** docs/PLATFORM.md for the platform. A library above starts as its API: its types and members with
  their doc comments and no implementation, agreed with the user and tried by fresh agents before any of it is written; those doc
  comments are its spec. A library changes when it doesn't do what its spec says, or when the spec changes first.
- **No backward compatibility.** When an API changes, every caller changes in the same commit.
- **Follow docs/CONVENTIONS.md** and docs/ARCHITECTURE.md (the adapter rule). Every public type and member has a doc comment. Run the
  formatter rather than laying code out by hand.

## Working

- **Checks:** `python3 tools/check_types.py --no-output` after an API change; `python3 helix.py test`, `tools/format.py --check` and
  `tools/check_docs.py` before committing; native builds, `tools/platform_checks.py` and `tools/services_checks.py` at the end of a feature.
- **Never open native windows on the user's desktop.** Use `tools/private_display.py`, and `SDL_AUDIO_DRIVER=dummy` so checks make no sound.
- **Report what ran,** on which target. Measure before claiming something is faster or smaller.
- **Ask before pushing,** opening a pull request, creating repositories or publishing packages.
- **A change touching helix-raylib's `Runtime`, `Frame` or what the native adapters are built over** gets one native parity suite
  (`python3 tools/raylib_parity.py shapes2d`) before its commit. `helix.py test` and a page run open no native window.

## Unattended work

- **One worktree an agent**, beside the checkout, with `build/haxelib` a real copy (its dev links then point into the worktree). Each
  checkout's builds take its own `build/.lock`; never nest it around a tool that takes it itself (`tools/bunnymark.py`, `tools/compare`).
- **Watch, don't wait.** Nothing gates all work on one background task. Its log is read early, a watcher reports its steps, and the
  person following along gets a status line every ten minutes, each starting with the Eastern time.
- **Check the homework.** An agent's report is a claim: read its diff, run the checks it names, and compare two agents' branches when
  the task was given to both.
