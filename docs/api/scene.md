# helix.scene

[Back to the index](README.md)

## Fade

*class* in `src/helix/scene/Transition.hx`

A fade to a color and back: covered at the middle, where the scenes swap.

```haxe
function new(?seconds:Float = .5, ?color:Int = 0x000000ff)
var color(default, null):Int
function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void
```

- `new`: A fade over seconds (half a second unless given) through color (black unless given, 0xRRGGBBAA, its alpha the cover at the middle).
- `color`: Its color.

## Loader

*class* in `src/helix/scene/Loader.hx`

A group of loads with one progress: a scene's files gathered so a loading screen shows how far they are (progress, from how many have ended) and the scene starts once they're done (done), with what failed by name (failures). Each load goes through the service it always did, its own lambdas kept (a failure with no failed lambda logged with its path, as the service would); the loader only counts. wrap counts any other load the game makes. Nothing here cancels: a scene that exits early cancels its own requests, and a cancelled load is never counted as ended.

```haxe
function new()
var count(get, never):Int
var doneCount(get, never):Int
var progress(get, never):Float
var done(get, never):Bool
var failures(get, never):Array<String>
function wrap(name:String, complete:wrap.T -> Void, failed:wrap.T -> Null<String>):wrap.T -> Void
function asset(path:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):IRequest
function texture(path:String, linear:Bool, loaded:Texture2D -> Void, ?failed:String -> Void):IRequest
function clip(path:String, loaded:AudioClip -> Void, ?failed:String -> Void):IRequest
function stream(path:String, loaded:AudioStream -> Void, ?failed:String -> Void):IRequest
function environment(path:String, loaded:Environment -> Void, ?failed:String -> Void):IRequest
function model(models:ModelCache, path:String, loaded:ModelFile -> Void, ?failed:String -> Void):IRequest
```

- `new`: No loads yet: done, at progress 1.
- `count`: How many loads were added.
- `doneCount`: How many have ended, failed ones included.
- `progress`: How far along, 0 to 1 (1 with nothing to load).
- `done`: Whether every load has ended.
- `failures`: What failed, each as its name and the reason.
- `wrap`: Counts a load the game makes itself: wrap its completion, naming it; failed gives the reason for a result that failed, or null.
- `asset`: An asset's bytes through Assets.
- `texture`: A texture through Textures (linear: not sRGB, for data such as normal maps).
- `clip`: A sound clip through Audio.
- `stream`: A sound stream through Audio.
- `environment`: An environment through Environments (loaded once it's prepared).
- `model`: A model file through models (Models.instance, or a ModelCache of the test's).

## Loading

*class* in `src/helix/scene/Loading.hx`

The built-in loading scene: the theme's panel color or a picture (setImage: a level's art, covering the screen or centered), a caption ("Loading the caves", text; "Loading" unless given) over a bar of the loader's progress and the count, a tip along the bottom (tip), and what failed in the disabled text color. With holdForPress it stays once loaded, saying so, until a press (the "loaded, go" screen of a movie-like opening); else the scene runs as soon as its loads are in. The game drives it: one for the program (Scenes.loadingScene) set before each level, or one a level brings (Scene.loadingScene). Its theme is its own (theme).

```haxe
function new()
var theme:Theme
var image(default, null):Null<Texture2D>
function setImage(value:Null<Texture2D>, ?cover:Bool = true):Void
var text:String
var tip:String
var holdForPress(get, set):Bool
var prompt:String
function enter():Void
function update(dt:Float):Void
function exit():Void
function draw():Void
```

- `new`: The built-in loading scene with the default theme.
- `theme`: The theme it draws with.
- `image`: Its picture, or null.
- `setImage`: A picture behind the rest: covering the screen (cropped to its shape) when cover, else centered whole; null for the panel color alone.
- `text`: The caption over the bar: what's loading ("Loading the caves").
- `tip`: A line along the bottom (a hint, a credit), wrapped; "" for none.
- `holdForPress`: Whether it stays once the loads are done, showing the prompt, until a key, a button or a finger is pressed.
- `prompt`: The line shown once loaded, while holding for a press.

## LoadingScene

*class* in `src/helix/scene/LoadingScene.hx`

A scene shown while another's loads are pending (Scenes.loadingScene): the stack hands it the loader before it enters, and it draws the loader's progress and failures. Loading is the built-in one; another extends this and draws its own.

```haxe
function new()
var shownLoader:Null<Loader>
var holding(get, never):Bool
```

- `new`: Not showing a loader yet.
- `shownLoader`: The loader it shows, or null (its own loader stays empty: a loading scene loads nothing first): set by the stack as the wait begins.
- `holding`: Whether to stay shown once the loads are done (a "loaded, press to go" screen): the stack keeps it until this is false. False unless overridden.

## Node

*class* in `src/helix/scene/Node.hx`

What every node shares, in a 3D tree (Node3D) or a 2D one: a name, the flags (enabled, visible, pickable), a parent and children, and find. It has no transform: Node3D and Node2D add their own, each taking children of its own kind only (its addChild and removeChild). Never made bare and never subclassed by a game: the framework's kinds are its classes, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61 and 130).

```haxe
var name:String
function find(name:String):Null<Node>
var enabled(get, set):Bool
var visible:Bool
var pickable:Bool
var childCount(get, never):Int
function getChild(index:Int):Null<Node>
```

- `name`: Its name: a model file's node name, or what the game gave it; "" for none.
- `find`: The first node named name below it (depth first, in drawing order), or null: for picking out a part of a loaded model (its wheels, a lamp), once, and keeping the node. Never a path.
- `enabled`: Whether it takes part at all: off, it and everything under it are skipped by drawing, picking and updates (an emitter under it isn't moved on), as if it weren't in the tree. The only flag that reaches its children; theirs are kept, so enabling it brings each back as set. On to start.
- `visible`: Whether its own output is drawn: off, a model, sprite, shape, text or emitter isn't drawn (an emitter still moves on) and a light doesn't shine or cast; it stays placed, and its children are as they are. On to start.
- `pickable`: Whether a pick can hit its own output: off, the ray passes through it, though its children can still be hit. Drawing doesn't matter to it: hidden and pickable is a hit area. On to start, but for text.
- `childCount`: How many children it has.
- `getChild`: Its child at index, in drawing order; null past the end.

## Pointer

*class* in `src/helix/scene/Pointer.hx`

The pointer over stages: which node it's over, and what it pressed and clicked, asked of it, never told to the nodes (DECISIONS 61). The stages it looks at are added in draw order, each with the camera it's drawn through; update() picks them topmost (last added) first, once a frame after input is polled, so a HUD drawn over the world takes the pointer first. A press on a 2D node captures the pointer: until it's released, the stages under it see nothing (captured, for an app's own use of the pointer too). Edges (isPressed, isClicked) last the frame they happen in. Nodes are compared by identity: a 3D stage's are Node3Ds, a 2D stage's Node2Ds.

```haxe
function new(input:IInput)
function addStage2D(stage:Stage2D, camera:Camera2D):Void
function addStage3D(stage:Stage3D, camera:Camera3D):Void
function remove(stage:Any):Void
function update():Void
var hovered(default, null):Null<Any>
function isHovered(node:Any):Bool
function isPressed(node:Any):Bool
function isDown(node:Any):Bool
function isClicked(node:Any):Bool
var held(default, null):Null<Any>
var captured(default, null):Bool
var hit3D(get, never):Null<PickHit>
```

- `new`: The pointer of input.
- `addStage2D`: Looks at stage through camera, above the stages added before it.
- `addStage3D`: Looks at stage through camera, above the stages added before it.
- `remove`: Stops looking at stage (2D or 3D); what it held lets go.
- `update`: Once a frame, after input is polled and before the stages' nodes are read: picks under the pointer, topmost stage first, and works out the frame's press and click.
- `hovered`: The node under the pointer, topmost stage first, or null.
- `isHovered`: Whether node is under the pointer.
- `isPressed`: Whether the pointer went down on node this frame.
- `isDown`: Whether node is held: the pointer went down on it and hasn't come up, wherever it is now (a drag).
- `isClicked`: Whether node was clicked this frame: the pointer came up over the node it went down on.
- `held`: The node held (isDown), or null.
- `captured`: Whether a press on a 2D stage holds the pointer: the stages under it, and the app's own world controls, should leave it be.
- `hit3D`: The last hit in a 3D stage (its point, normal, distance), when the hovered node is a 3D stage's; null otherwise.

## Scene

*class* in `src/helix/scene/Scene.hx`

One screen of a game (a splash, a title, a level, a pause menu) on a Scenes stack, which calls it through the object (hooks are overrides, so a hot reload reaches them, DECISIONS 123): enter once it's pushed, update and draw each frame while it's on top, pause when another is pushed over it or the window loses focus, resume when that ends, exit when it's popped or replaced. A scene that loads first returns its Loader (loader) from enter on: the stack shows its loading scene until the loader is done, then runs this one. draw begins the frame (Graphics.beginFrame) and draws; the stack ends it, after any transition it draws over.

```haxe
function new()
var name(get, never):String
var scenes(default, null):Null<Scenes>
var loader(get, never):Null<Loader>
var loadingScene(get, never):Null<LoadingScene>
function enter():Void
function exit():Void
function pause():Void
function resume():Void
function update(dt:Float):Void
function draw():Void
```

- `new`: A scene not on a stack yet.
- `name`: Its name: the class's, without its package, unless overridden; what an autopilot's probe reports.
- `scenes`: The stack it's on, or null.
- `loader`: The loads it waits for before it runs, or null for none: made in enter.
- `loadingScene`: The loading scene shown while its loads are pending, or null for the stack's (Scenes.loadingScene): a level with its own picture and caption.
- `enter`: Pushed onto the stack: make what it needs, start its loads.
- `exit`: Popped or replaced: free what it made.
- `pause`: Another scene pushed over it, or the window lost focus (Scenes.pauseOnBlur).
- `resume`: On top again, or the window focused again.
- `update`: A frame's logic, dt seconds since the last (the game's clock's delta, or an autopilot's tick).
- `draw`: A frame's drawing: begins the frame and draws; the stack ends the frame.

## Scenes

*class* in `src/helix/scene/Scenes.hx`

A game's scenes as a stack: the top one runs; push puts one over it (the one under pauses: a pause menu over play), pop takes it off (the one under resumes), replace swaps the top (a title for a level). A transition handed to any of them draws over the frames while the scenes swap at its middle. A scene with a loader (Scene.loader) is shown the loading scene until its loads are done: the built-in Loading unless loadingScene gives another, or none. The window losing focus pauses the game's clock and the top scene (pauseOnBlur, on unless turned off); focus resumes them. Scenes read input through input (Input.instance, or what an autopilot gives through input). frame runs update then draw; an autopilot runs several updates a frame and one draw. Quick (quick; on with the run option quick=1, a developer's) skips the built-in screens' waits and every transition: the game jumps in as soon as it's loaded.

```haxe
function new()
var quick:Bool
var top(get, never):Null<Scene>
var count(get, never):Int
var all(get, never):Array<Scene>
var input:IInput
var loadingScene(get, set):Null<LoadingScene>
var pauseOnBlur:Bool
var transitioning(get, never):Bool
var loading(get, never):Bool
function push(scene:Scene, ?transition:Transition):Void
function pop(?transition:Transition):Void
function replace(scene:Scene, ?transition:Transition):Void
function clear():Void
function frame(dt:Float):Void
function update(dt:Float):Void
function draw():Void
function destroy():Void
```

- `new`: An empty stack with the built-in loading scene and the program's input.
- `quick`: Whether the built-in screens' waits and every transition are skipped (the run option quick=1 sets it).
- `top`: The scene on top, or null.
- `count`: How many scenes are stacked.
- `all`: The scenes, bottom first.
- `input`: What scenes read: Input.instance, or what was assigned instead (an autopilot's).
- `loadingScene`: The scene shown while the top one's loads are pending, or null for none (the scene shows itself loading).
- `pauseOnBlur`: Whether the window losing focus pauses the game's clock and the top scene.
- `transitioning`: Whether a transition is under way (input is still the scenes').
- `loading`: Whether the loading scene is showing: the top scene's loads are pending, or the loading scene holds after them (LoadingScene.holding).
- `push`: Puts scene on top: the one under pauses, scene enters. With transition, the swap comes at its middle.
- `pop`: Takes the top scene off: it exits, the one under resumes. Nothing with an empty stack.
- `replace`: Swaps the top scene for scene: the top exits, scene enters; the one under stays paused.
- `clear`: Takes every scene off, top first, each exiting.
- `frame`: A frame: update then draw.
- `update`: The frame's logic: the transition's time (the frames'), focus, then the top scene's update, or its loading scene's while it loads.
- `draw`: The frame's drawing: the top scene's (or its loading scene's), the transition over it, then the frame's end.
- `destroy`: Frees what it made (the transition batch); the scenes are cleared first.

## Splash

*class* in `src/helix/scene/Splash.hx`

The built-in splash: a logo (or none) centered on the theme's panel color for at least its seconds, then the next scene, once the user has pressed a key, a button or a finger (IInput.activated: a browser lets audio start and fullscreen be asked for only after that; the same rule everywhere), or after maxWait's seconds without one: "press any key" shows until then, or, where a press came already, nothing. A pad's press doesn't count (a browser can't unlock with one), so the line stays for a tap. Pushed with a Fade, it fades in from the color. Extend it for another look; theme for its colors and font, prompt for the line.

```haxe
function new(logo:Null<Texture2D>, seconds:Float, next:Scene, ?transition:Transition)
var theme:Theme
var prompt:String
var shown(default, null):Float
var maxWait(default, set):Float
function exit():Void
function update(dt:Float):Void
function draw():Void
```

- `new`: A splash of logo (null: the theme's colors alone), shown at least seconds, then next, by transition (a half-second fade unless given).
- `theme`: The theme it draws with.
- `prompt`: The line that asks for the press, shown until one comes ("press any key" to start).
- `shown`: Seconds shown so far.
- `maxWait`: The most seconds it waits for a press before going on without one (a game that needs no audio unlock, or one that unlocks later); 0, the default, waits for one as long as it takes. 0 or more (under 0, or NaN, is 0).

## Transition

*class* in `src/helix/scene/Transition.hx`

How one scene gives way to the next on a Scenes stack: drawn over the frames for its seconds, the old scene under its first half and the new under its second (the swap is at the middle). A transition runs on the frames' time, not the game's clock, so a paused game still transitions to its menu. Fade is the one made; another draws anything over the frame by progress.

```haxe
function new(seconds:Float)
var seconds(default, null):Float
function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void
```

- `new`: A transition taking seconds. Throws for 0 or less.
- `seconds`: How long it takes.
- `draw`: Draws it over the frame, width by height framebuffer pixels, at progress 0 to 1 (the swap at .5), into batch, begun on a camera of framebuffer pixels. Nothing by default.
