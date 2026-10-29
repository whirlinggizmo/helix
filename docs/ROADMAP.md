# Roadmap

- **The build trial, rerun.** Fresh agents, given platform, math and log alone, each write a services library and a small game on it.
  Where they agree is the shape; what they invent is what the platform lacks.
- **docs/SERVICES.md,** the services spec, from the trial.
- **services,** built from the spec.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
