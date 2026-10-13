# Agent instructions: HeliX

HeliX is a Haxe game framework: Haxe → JS for the browser, Haxe → hxcpp/C++ for native (not HashLink). You are developing it, not prototyping. Read [README.md](README.md) and [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before changing code.

## Rules

- **Follow docs/CONVENTIONS.md.** It covers names (get/set/is/has/can/request methods, not Haxe properties), units (radians, seconds, 0xRRGGBBAA, named spaces), capitals and layout. Every public type and member gets a doc comment. Run the formatter rather than laying code out by hand.
- **No backward compatibility.** When an API changes, change every caller in the same commit. No aliases, shims or deprecated wrappers.
- **Check prior work first.** Before writing a feature, read how the earlier Whirling Gizmo C frameworks did it (`../wgrender-c`, `../libwgf`). Their platform quirks were hard-won, for example gamepad mapping by driver, touch gestures, mipmaps, and cache locations. Write HeliX's own code; don't copy large chunks.
- **Don't name libwgf in HeliX.** Code, examples, conventions and API docs don't refer to it. It is going away. Only historical entries in docs/DECISIONS.md name it.
- **Keep platform APIs where they are enough.** In the browser, audio, storage and fetch use the browser's APIs, not Wasm. Native services can differ beneath the same Haxe interfaces. Keep the graphics contract thin: add what an example needs, not a general GPU abstraction.
- **Read the current source of a dependency** (Sokol, sokol_utils, hxcpp, hotreload-hx) before writing bindings against it. Pins and hashes live in `dependencies.json`; vendored copies in `vendor/`.

## Working

- **Develop in the browser hot-reload loop** (`python3 tools/example.py <name> dev`). Judge changes in the running page. Native builds, unit tests and cross-target checks run at checkpoints (the end of a feature or milestone), not after every change.
- **Examples are probes, not products.** An example proves a framework feature on both targets. No deployment, hosting or polish beyond what the feature needs. Asteroids and Blocks are larger examples, not separate products.
- **Never open native windows on the user's desktop.** Run native window checks on a private display (`tools/private_display.py`): a new window takes the keyboard focus, and the user's typing lands in it. Set `HELIX_AUDIO=0` so checks make no sound.
- **Type-check after an API change:** `python3 tools/typecheck.py --no-output`. Before committing, run `tools/format.py --check` and `tools/doccheck.py`.
- **Report what ran.** Say what was executed and on which target; never invent results or claim untested platforms. Measure before claiming something is faster.

## Outward-facing actions

- **Ask the user before opening any pull request,** here or upstream. Upstream maintainers needn't be asked first. A PR says it was prepared with an AI coding agent, and claims only what was checked.
- **Ask before pushing** to a remote, creating repositories or publishing packages.
