# Agent instructions: helix

helix is a Haxe game framework built as layered libraries: Haxe → JS for the browser, Haxe → hxcpp/C++ natively. Read
[GOALS.md](GOALS.md), then [docs/PLAN.md](docs/PLAN.md) and [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before changing code; what's
next is in [docs/ROADMAP.md](docs/ROADMAP.md).

## Rules

- **Platform and services are constructed.** A program constructs the adapters and services it uses; nothing in them installs itself,
  runs a loop, is reached through a static that builds it, or is bundled with everything else. When a design answer for them starts
  from "the engine does it this way", ask instead what a program using them directly would construct. The layers above (the runner, an
  engine wearing a known API) may own the loop, and build a feature when its API is first touched where the API they match requires it
  (DECISIONS 15).
- **helix-legacy is prior art.** Everything here is helix: the repository, its packages and its libraries (`helix-raylib`). HeliX,
  capital H and X (for Haxe), is the brand, in prose. [helix-legacy](https://github.com/whirlinggizmo/helix-legacy) (`../helix-legacy`),
  the framework that held the name before, and the earlier C frameworks (`../wgrender-c`, `../libwgf`), are read for how they did a
  thing and the platform quirks they found. Useful code may be cribbed, refactored to this library's conventions and needs, or this
  library's own written instead. helix-legacy's design (its runner, statics, profiles) is never a reason for this library's shape.
  DECISIONS and docs/trials keep the names they were written with, where "HeliX" means helix-legacy. Don't name libwgf in code or docs.
- **The spec is the authority.** docs/PLATFORM.md for the platform. A library above starts as its API: its types and members with
  their doc comments and no implementation, agreed with the user and tried by fresh agents before any of it is written; those doc
  comments are its spec. A library changes when it doesn't do what its spec says, or when the spec changes first.
- **No backward compatibility.** When an API changes, every caller changes in the same commit.
- **Follow docs/CONVENTIONS.md** and docs/ARCHITECTURE.md (the adapter rule). Every public type and member has a doc comment. Run the
  formatter rather than laying code out by hand.

## Working

The prerequisites, the checks and when each runs, windows and sound, and the tools are in [CONTRIBUTING.md](CONTRIBUTING.md). Two of
its rules matter most, kept here too:

- **Never open windows on the user's desktop unasked.** The tools run headless by default (a private display, headless Chromium), and
  `SDL_AUDIO_DRIVER=dummy` keeps checks silent. A check that needs the real display (`--headed`: timing, watching) runs once the user
  approves it. Ask for it rather than skip it.
- **Report what ran,** on which target. Measure before claiming something is faster or smaller.

How an agent works here:

- **Ask before pushing,** opening a pull request, creating repositories or publishing packages. Commits carry no attribution lines.
- **One worktree an agent,** beside the checkout, with its own copy of `build/haxelib`. Main's index is then nobody else's. In a shared
  checkout, a commit names its paths (`git commit -- <paths>`), since a plain commit takes whatever another has staged.
- **Watch, don't wait.** Nothing gates all work on one background task. Its log is read early, a watcher reports its steps, and the
  person following along gets a status line every ten minutes, each starting with the Eastern time.
- **Check the homework.** An agent's report is a claim: read its diff, run the checks it names, and when a task went to two agents,
  compare their branches.
- **A departure from raylib gets a trial before it's pushed:** a change adding or moving a refusal, an extra or a build step in
  helix-raylib. How a trial runs is [docs/trials/README.md](docs/trials/README.md).
