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

How work runs (prerequisites, the checks and when each runs, windows and sound, worktrees and unattended work, publishing) is
[CONTRIBUTING.md](CONTRIBUTING.md). The four rules that matter most, kept here too:

- **Never open native windows on the user's desktop.** Use `tools/private_display.py`, and `SDL_AUDIO_DRIVER=dummy` so checks make no sound.
- **Report what ran,** on which target. Measure before claiming something is faster or smaller.
- **Ask before pushing,** opening a pull request, creating repositories or publishing packages.
- **Watch, don't wait:** an agent's or a task's progress is checked as it runs, and its report is a claim to check.
