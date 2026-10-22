# The display model

**Status:** designed with the user on 2026-10-22, the day before the ATL Gamedevs Jam, and built on the branch `display-model` (steps 1 to
8 below, each committed with its checks), merged into `main` once the native autopilots and the Windows build pass. Decision 145 records
it; this document is the design, and the place to pick the work up from. Where the build departed from the first plan it says so below.

## Why

Using HeliX for the jam, the user expected a stage that draws itself, as Flash's does (and Pixi's, and Heaps' `s2d`), and found a game
had to open the frame, begin a batch, draw each stage through a camera, end the batch and close the frame, every frame. Looking closer,
the names misled as much as the plumbing: HeliX's `Stage2D`/`Stage3D` were what Babylon and Away3D call scenes (there can be several),
while its `Scene` was a screen with a lifecycle on a stack, and a `.scene` file a third thing again. GOALS.md asks for a clear, consistent
API that people and agents guess right; a dev or an agent who knows Flash should guess HeliX's display model.

## The idea in one line

**Very much like Flash, with these differences:** Flash's stage and display list, Away3D's views, Löve's update loop, and no logic on
what's drawn.

## The pieces

### `App`: the program (Flash's movie)

- `init()`, `update(dt)`, `cleanup()`. `update` is today's `frame` without the drawing.
- No drawing hook and no frame plumbing: after `update` the runner draws the stage.

### `Stage`: the one thing drawn

- A static service: the root `Node2D`, shown on the window in pixels, drawn by the runner every frame. Flash code reads the same:
  `Stage.addChild(ball)`.
- Its children draw in order, later over earlier. A HUD is nodes added after the views.
- `Stage.color`: the clear color, as Flash's `stage.color`.
- A post-processing chain on the stage applies to everything.

### Nodes: display objects

- `Node2D`: a container. `addChild`, `removeChild`, `x`, `y`, `rotation` (radians), `scaleX`, `scaleY`, `visible`, `name`, and new:
  `alpha`, fading the node and everything under it, as Flash's did.
- `Sprite2D`: an image (Flash's `Bitmap`). Flash's `Sprite`, a container you could draw on, is `Node2D`, with a `Drawing2D` in it.
- `Shape2D`, `Text2D` (Flash's `TextField`), `Particles2D` as today.
- `Drawing2D` (new): Flash's `graphics`, a node holding drawing calls, stateless: `fillRect(x, y, w, h, color)`, `fillCircle`, `line`,
  `text`, `clear()`. Calling `clear()` and drawing again in `update` is immediate drawing, as Flash games did it, so no draw hook is
  needed anywhere; `Batch2D` becomes the engine's, not the game's.
- 3D nodes as today: `Node3D`, `Model`, lights, `Sprite3D`, `Text3D`, particles.

### `View2D` / `View3D`: content shown through a camera

- A view is a 2D display object showing a node tree through a camera: `new View2D(worldRoot, camera)`, `new View3D(levelRoot, camera)`.
  Add it to the stage, or to any 2D tree.
- One tree can be shown by several views (split screen, a minimap).
- Views nest (a minimap in a HUD panel, a picture in picture), each clipped to its rectangle. **Cycles are refused**: a view never draws
  a tree it is itself being drawn inside; it is skipped and logged once.
- **3D draws under 2D**, as Flash's Stage3D content drew under its display list: the 2D batch sends its draws once, at the frame's end. A
  nested `View3D` shows right only where no 2D lies under it, until views can draw into a texture (below).
- A `View3D` holds the photography: its camera, `exposure`, `tonemap`, `hdr`, its post-processing chain, and optionally an `environment`
  overriding the content's (a minimap's flat light, an editor's preview). A `View2D` has its camera and a post-processing chain.
- A view with post-processing draws its tree into a texture, runs the chain, and draws the texture where the view is. That same path, a
  view drawn into a texture, is what later puts 3D between 2D.

### Scenes: trees of nodes, saved or live

- A scene is a tree of nodes. Saved, it is a `.scene` file; live, it is the nodes loaded from one, under the node they were put in.
- A level and a prefab are the same thing used two ways: a scene file loaded as the root of what a view shows, or put inside another
  tree, as often as wanted. Neither word is a class. (Godot's meaning of "scene"; Flash's MovieClip symbol in the library.)
- No `Scene2D`/`Scene3D` classes and no `Stage2D`/`Stage3D`: a view shows a node. What those classes held per tree (the clock, picking's
  tables, the draw counts) moves to the view drawing it or to the subtree it describes.
- `SceneFile` (a scene as read) and `SceneInstance` (a scene put into a tree) keep their names. Scene files are 3D now; 2D ones are
  roadmap.

### `Environment3D`: the place's light, on a node

- Plain data, not a node: the environment map that lights and reflects, the ambient light, the background sky, fog when it comes.
- Set as a property of a 3D node, `level.environment = ...`, and saved with that node in its scene file. It applies to the node's
  subtree: a model is lit by the nearest ancestor's environment. A level's sits on its root; a prefab's applies only inside it (no "first
  one wins" rule); regional light (a cave) follows.
- A `View3D`'s `environment`, when set, overrides. The background drawn behind is the view's override, else the environment of the node
  the view shows.
- In the branch: one environment per view (its override, else the first in its tree, the root's first, depth first, so a scene
  file's group under the root lights it); others in the tree logged once. The nearest-ancestor meaning
  stays the definition, so regional light comes later without changing the API.
- The scene file's `stage` section goes: environment, ambient light and background move onto the root node's entry as its environment;
  exposure and tone mapping, the camera's, go to the view.

### Logic: never on nodes

- No `ENTER_FRAME`, no frame scripts, no listeners (decision 61; decision 123: a listener made before a hot reload keeps the old code).
- Logic lives in `App.update`, or in behaviors, which scene files and code attach. A screen's logic is a behavior on its root (the
  `scene-file` example's race director already is one).
- Behaviors run from one pass over what's on the stage, before drawing. `paused = true` on a node stops its subtree: its behaviors, its
  particles' clock and its picking, while it stays drawn. That is pausing a level under a menu.

### Screens and flow: what is on the stage

- No `Scene` class with a lifecycle and no `Scenes` stack. A screen is what's on the stage: swap screens by removing one and adding
  another; pause by pausing the level and adding a menu over it.
- Transitions (a fade) and the loading screen become small helpers working on the stage.

### Input: asked, never delivered

- `Input.isPressed(key)` and the like, polled where logic runs.
- The pointer picks through views, topmost first, and a press captures it until release, so a HUD button takes a click before the world
  under it, and a dragged slider doesn't aim the gun. The pointer reads the stage's order; no separate list of stages.
- **Claiming:** `Input.claim(key)` takes a key for the frame; `isPressed` and `isDown` say false for a claimed key after that, `isClaimed`
  says it was. The UI, reading first, claims what it uses, so typing a space in a text field doesn't make the player jump. Bubbling's use
  (the topmost gets it first) without a tree of handlers.

### Units

Radians, seconds, colors `0xAARRGGBB` (decision 144), world units through a view's camera, pixels on the stage.

## A frame, done by the runner

1. `App.update(dt)`; then the behaviors pass over the stage's trees (skipping paused subtrees).
2. For each `View3D` that will draw: its shadow maps; for each view with post-processing (or, later, drawn into a texture): its texture.
3. The frame opens, cleared to `Stage.color`.
4. The stage draws: every `View3D` first, then all 2D in display order (nested views in place).
5. The stage's post-processing, if any; the frame closes.

## Very much like Flash, but

| Flash | HeliX | Why |
|---|---|---|
| Scrolling by moving a container | `View2D` with a camera | Cameras (zoom about a point, viewport, pixel snapping, culling, follow, shake, the pointer in world units) are what every Flash game hand-rolled. |
| Stage3D, a low-level API | `View3D` showing a 3D tree | Away3D's model, built in. |
| `ENTER_FRAME`, frame scripts | `App.update`, behaviors | Game state apart from what's drawn: saves, replays, determinism (decision 61). |
| `addEventListener`, bubbling | Polling, the pointer's picks, claiming | Hot reload keeps no stale handler (decision 123); the frame's order is plain. |
| `graphics.beginFill`, `drawRect`, `endFill` | `Drawing2D.fillRect(..., color)` | Stateless: no forgotten `endFill`, and the same vocabulary as the batch. |
| `rotation` in degrees | radians | One unit per kind (CONVENTIONS). |
| `0xRRGGBB` plus `alpha` | `0xAARRGGBB` | The order Haxe's libraries and the editor's color picker use. |
| `Sprite`: a container to draw on | `Node2D` (+ `Drawing2D`); `Sprite2D` is an image | A sprite is an image everywhere else in games. |
| `MovieClip` timelines | `SpriteAnimator`, tweens; timelines later as data | Frame scripts are where Flash got tangled; see below. |
| Scenes: sections of the timeline | Scene files: trees, levels and prefabs alike | Godot's and Unity's meaning, the one game developers hold now. |

## Examples

The smallest game:

```haxe
class Game extends helix.App {
	var ball = Shape2D.circle(20, 0xff66bfff);

	override function init() {
		Stage.addChild(ball);
	}

	override function update(dt:Float) {
		ball.x += 100 * dt;
	}
}
```

A 3D level with a HUD and a pause menu:

```haxe
class Game extends helix.App {
	var level:Node3D;
	var view:View3D;
	var score = new Text2D("0", 24, 0xffffffff);
	var menu:Null<Node2D>;

	override function init() {
		Stage.color = 0xff14161c;
		level = SceneFiles.load("levels/track.scene");    // its root carries its environment; its behaviors run the race
		view = new View3D(level, new Camera3D());
		Stage.addChild(view);
		Stage.addChild(score);                            // over the 3D, in pixels
	}

	override function update(dt:Float) {
		if (Input.isPressed(Key.Escape)) {
			level.paused = menu == null;                  // behaviors, particles and picking stop; still drawn
			if (menu == null)
				Stage.addChild(menu = makeMenu());
			else {
				Stage.removeChild(menu);
				menu = null;
			}
		}
	}
}
```

(The calls are the design's, sketched: exact signatures, a scene's loading being asynchronous, are settled as it's built.)

## What changes from today

- **Renamed or reshaped:** `App.frame` → `App.update`; `Stage2D`/`Stage3D` go, their per-tree state to views and subtrees; `Stage3D`'s
  settings split, the place's into `Environment3D` on a node, the photography's onto `View3D`.
- **Gone:** `Scene`, `Scenes` (the stack) and their lifecycle; `Graphics.beginFrame`, `batch.begin`, `batch.end` and `stage.draw` in game
  code; `Pointer`'s list of stages; the scene file's `stage` section.
- **New:** `Stage`, `View2D`, `View3D`, `Environment3D`, `Drawing2D`, `Node2D.alpha`, `paused` on nodes, `Input.claim`, post-processing on
  the stage and on views.
- **Reworked onto the stage:** `Splash`, `Loading`, `Transition`, the `Ui` (over a node on the stage rather than a `Stage2D` and its
  camera), the starter template, every example, the tests, CONVENTIONS, INTERFACE, SCENE_FILE and the API docs.

## The order of work on the branch

1. The runner owns the frame: `App.update`, `Stage` drawn after it, `Stage.color`; the batch the engine's.
2. `View2D` and `View3D` on a shared `View` (a `Node2D`, so a view is a display object; the 2D walk knows only `View`, so a 2D
   program links no 3D); nesting and the cycle check. Built over `Stage2D`/`Stage3D` as renderers, so every example runs throughout the
   branch; those classes go in step 8, with the examples.
3. `Environment3D` on nodes, the view's photography and override; the scene file's root environment, its `stage` section gone.
4. Behaviors as the program's pass (`Behaviors`, over `BehaviorPass`), run by the runner after `update`; `paused` on nodes (behaviors
   wait, emitters hold still, still drawn). `Scenes`/`Scene` go, and transitions and loading become helpers on the stage, in step 8 with
   the two examples that use the stack (`scenes`, `scene-file`).
5. The pointer through views; `Input.claim`, the UI claiming.
6. `Drawing2D`, `Node2D.alpha`.
7. Post-processing on the stage and on views (views drawn into textures).
8. Every example, the starter, the tests and the docs moved over; `Stage2D`/`Stage3D` as public classes gone (their drawing kept as
   the views' renderers), and the runner's allowance for an app drawing its own frame removed (`Graphics.beginFrame` and `endFrame` the
   runner's alone); a decision entry recording what was built and checked.

9. Scene files named by kind, as the convention names 2D and 3D apart: `.scene` becomes `.scene3d` (and `SceneFile`, `SceneInstance`,
   `SceneFiles` their 3D names), so 2D scene files arrive as `.scene2d` without renaming again. A 2D scene shows a 3D one through a
   `View3D` referring to a `.scene3d` file, never by mixing kinds in one tree.

## Later (ROADMAP)

- **Timelines:** what Flash's artists understood best, kept as data so rule 61 holds: keyframed tracks per child node (`x`, `y`,
  `rotation`, `alpha`, `visible`, the sheet frame; each child's track a Flash layer), labels naming spans, markers the game asks about
  (`clip.entered("hit")`) in place of frame scripts, played by a player as `SpriteAnimator` and the 3D `Animator` are (glTF's clips are
  the same shape), saved in the scene file with the nodes they move. Authoring wants the scene editor.
- **2D under 3D:** views drawn into textures in display order (the same path as post-processing on views).
- **Fonts:** the built-in one only where text is drawn; glyphs from the browser's rasterizer.
- **2D scene files (`.scene2d`), and screens as scene files.** With behaviors attachable to any node (not only `Node3D`) and a helper
  that loads a scene file and swaps it onto the stage through a transition, a splash or a loading screen is a `.scene2d` (a panel, a logo,
  a prompt) with a behavior (wait, then go to the scene its `next` prop names): `Splash` and `Loading` shrink to default files and their
  behaviors, restyled in a file or an editor rather than subclassed.
- **Regional environments:** the nearest ancestor's, several per view.
- **Optional parts of the 3D renderer:** its sprites, text and particles (`Sprites3D`, `Emitter`) and its skinning (the skinned program, the
  joint palette, the skinned shadow and pick paths) linked only into programs that use them, as views, drawings and emitters already are in
  2D (`Node2D.drawOwn`): the lit-3D rung of the size ladder links them all today (134 KB gzipped).
- **Sprite effects on text and drawings:** `Batch2D.effect` is set to none for a `Text2D` and a `Drawing2D`, so a flash or an outline can't
  cover them (the sprite2d example's title no longer flashes).
- **Presses for frame-driven screens:** in a fast autopilot (several ticks a frame) each tick ends its presses, so a screen that runs once a
  frame (`Splash`, `Loading`, a `Transition`) misses one made in an earlier tick; the scenes example holds the press itself.
- **A test harness publishing after the frame is drawn,** so a snapshot's draw counts are the frame's own, not the one before.
- **Fixed steps built in:** an app option for the tick rate, a `tick()` override called at it, and the fraction between ticks readable in
  `update`, so no game makes a `Ticker` (Flash's `frameRate`); today a game advances a `Ticker` in `update` and places its nodes at the
  drawn position (`Body2D.getDrawnX(fraction)`).
