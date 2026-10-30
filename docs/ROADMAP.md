# Roadmap

- **The services' API:** time, input, assets, audio, saves and config as types and members with doc comments, no implementation,
  agreed with the user, then a trial on its reference.
- **services,** built to it.
- **The layer above the services:** constructs the platform and the services for a target, runs the frame in order and ends with the
  saves written, so a program knows none of that; its spec is the `Main.hx` the services trial's three agents each wrote the same way.
  Whether it wears a known API or an engine's is GOALS' open path.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
- **Gestures:** taps, double taps, drags and flicks (the mouse and fingers alike), and two fingers' pan, pinch and twist, over `Touch`
  and `Mouse`, as HeliX's `PointerGestures` and touch gesture had them.
- **On-screen controls, with the UI layer:** touch regions and floating touch sticks (one, two halves, regions; dead zone, takeover,
  blocked by buttons) read by `Actions` through `IActionDevice`, placed in the game's units and drawn (DECISIONS 13).
