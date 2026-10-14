# Roadmap

What comes next, milestone by milestone. What's done, and when: [HISTORY.md](HISTORY.md). Why each piece is the way it is: [DECISIONS.md](DECISIONS.md).

Each milestone reimplements a part of the earlier frameworks (wgrender-c, libwgf, libwgt) feature by feature, as examples that run in the browser and natively. Mid-milestone, work is checked in the browser with hot reload and the interpreter's unit tests; a milestone ends with the full checks on both targets.

## Now: milestone 6, UI

wgrender-c's model in Haxe, with libwgf's focus: widgets are helpers that own Stage2D nodes and are read through `helix.scene.Pointer` and a focus service each frame, never callbacks on nodes (DECISIONS 61); a small layout places them; no Clay (C, and HeliX's engine code is Haxe). libwgt had no UI. In order, each step leaving both targets working:

0. **Clipping** (built). `IGraphics.setScissor` (both GL adapters), a clip stack in Batch2D (each clip within its parent's, wgrender-c's nested stack), a Stage2D node whose children are clipped to its area; a clipped-out node isn't picked (wgrender-c's lesson).
1. **Nine-slice sprites** (built) (a frame's corners kept, its edges and middle stretched) on Node2D and Batch2D, and **text wrapped** to a width (Text2D and text nodes; measured and picked by the wrapped block; a space measures its width, wgrender-c's caa49dd).
2. **Layout** (built). Rows, columns and anchors to a parent's edges, with padding, gaps, alignment and sizes fixed, fitted to content or growing to fill; it writes positions and sizes into nodes once a frame. HUDs anchor instead of guessing positions (libwgf's friction), within a design resolution (Camera2D.fit).
3. **Widgets** (built) (`helix.ui`): label, panel (nine-slice), button, toggle, slider, progress bar, and a scrolling list (clipped, the wheel and a drag); each asked `isClicked`, `getValue` and the like, owning its nodes and drawn by the stage; a theme of colors, font and sizes.
4. **Focus** (built). Keys and a pad's D-pad move focus in the order widgets were given, Enter, Space or the pad's south button activates, Escape or east backs out; focus is drawn only when moved by keys or pad (libwgf's :focus-visible); a default focus when the last input was keys or a pad; a press already held when a screen appears is ignored (libwgf's held fire key); while the UI has focus it reports that it has the keys, so a game doesn't also act on them (libwgf's arrows driving both); the focus published for autopilot checks.
5. **A text field** (built), if typed text through focus proves simple: a caret, typing, Backspace, selection later; no IME yet.
6. **The examples** (built; Asteroids' scripts now click its menu's widgets by name). `ui`: a menu, a settings screen (toggle, slider), a scrolling list, nine-slice panels, all by pointer, keys and pad. Asteroids' title and pause menus moved onto it, its autopilot checking focus.

## Next

- **Milestone 7: native network streaming.** A native audio stream playing a remote file as it downloads, and both targets playing while keeping the copy, shown starting before the download ends on a slowed network.

## Deferred until a game needs it

- **Decided after measuring** (milestone 5 left them for numbers that call for them): a spatial index (both culling and picking walk every node; neither earlier framework needed one), visibility and pick masks, skipping the posing of characters out of view (libwgt: 400 models looking away 0.94 ms posed lazily, 16.1 posed; and its trap: culling by last frame's posed box never poses a culled model, so it never walks back into view), occlusion culling, per-instance picks. Also caching skinned poses for picks, if picking many characters is measured to cost.
- **The autopilot's UI:** probes that report which widgets are showing, and events recorded for scripts to wait on, beside `click`.
- **Animation layers:** an upper body's clip over a lower body's.
- **Skinned surface shaders:** an app's surface shader on a skinned model (it's ignored today).
- **Morph targets**, and more than four joints a vertex.
- **`IWebSocket`:** a contract of its own (open, send, receive, close), with a shared service for reconnecting and queuing.
- **`ecs-scene`:** waits on the game model, which is still open (behaviors and components undecided).

## Open designs

- **Work off the frame**, to be designed with physics: a module of fixed bulk calls (as the physics study's) that can run in place, in a Web Worker or on a thread without its callers changing. The environment bake would be its first one-shot client; today environment loads are tied to a per-frame budget, slow at a low frame rate.
- **One frame budget across the job pools:** each pool still delivers under its own 2 ms.
- **More platforms:** Windows, macOS and mobile haven't run; SDL3 and WebGPU adapters would sit beside sokol and WebGL2 under the same contracts ([ARCHITECTURE.md](ARCHITECTURE.md)).
