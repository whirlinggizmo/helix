# Roadmap

- **The services' API:** time, input, assets, audio, saves and config as types and members with doc comments, no implementation,
  agreed with the user, then a trial on its reference.
- **services,** built to it.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
