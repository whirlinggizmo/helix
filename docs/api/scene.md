# helix.scene

[Back to the index](README.md)

## Fade

*class* in `src/helix/scene/Transition.hx`

A fade to a color and back: covered at the middle, where the scenes swap.

```haxe
function new(?seconds:Float = .5, ?color:Int = 0x000000ff)
function getColor():Int
function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void
```

- `new`: A fade over seconds (half a second unless given) through color (black unless given, 0xRRGGBBAA, its alpha the cover at the middle).
- `getColor`: Its color.

## Loader

*class* in `src/helix/scene/Loader.hx`

A group of loads with one progress: a scene's files gathered so a loading screen shows how far they are (getProgress, from how many have ended) and the scene starts once they're done (isDone), with what failed by name (getFailures). Each load goes through the service it always did, its own callback kept; the loader only counts. wrap counts any other load the game makes. Nothing here cancels: a scene that exits early cancels its own requests.

```haxe
function new()
function getCount():Int
function getDoneCount():Int
function getProgress():Float
function isDone():Bool
function getFailures():Array<String>
function wrap(name:String, complete:wrap.T -> Void, failed:wrap.T -> Null<String>):wrap.T -> Void
function asset(path:String, complete:AssetResult -> Void):IRequest
function texture(path:String, linear:Bool, complete:TextureLoadResult -> Void):IRequest
function clip(path:String, complete:AudioLoadResult<AudioClip> -> Void):IRequest
function stream(path:String, complete:AudioLoadResult<AudioStream> -> Void):IRequest
function environment(path:String, complete:EnvironmentLoadResult -> Void):IRequest
function model(models:Models, path:String, complete:ModelLoadResult -> Void):IRequest
```

- `new`: No loads yet: done, at progress 1.
- `getCount`: How many loads were added.
- `getDoneCount`: How many have ended, failed ones included.
- `getProgress`: How far along, 0 to 1 (1 with nothing to load).
- `isDone`: Whether every load has ended.
- `getFailures`: What failed, each as its name and the reason.
- `wrap`: Counts a load the game makes itself: wrap its completion, naming it; failed gives the reason for a result that failed, or null.
- `asset`: An asset's bytes through Services.assets.
- `texture`: A texture through Services.textures (linear: not sRGB, for data such as normal maps).
- `clip`: A sound clip through Services.audioResources.
- `stream`: A sound stream through Services.audioResources.
- `environment`: An environment through Services.environments (ready once it's prepared).
- `model`: A model file through models (a game's Models over the services).

## Loading

*class* in `src/helix/scene/Loading.hx`

The built-in loading scene: the theme's panel color or a picture (setImage: a level's art, covering the screen or centered), a caption ("Loading the caves", setText; "Loading" unless given) over a bar of the loader's progress and the count, a tip along the bottom (setTip), and what failed in the disabled text color. With setHoldForPress it stays once loaded, saying so, until a press (the "loaded, go" screen of a movie-like opening); else the scene runs as soon as its loads are in. The game drives it: one for the program (Scenes.getLoadingScene) set before each level, or one a level brings (Scene.getLoadingScene). Its theme is its own (setTheme).

```haxe
function new()
function getTheme():Theme
function setTheme(value:Theme):Void
function getImage():Null<Texture2D>
function setImage(value:Null<Texture2D>, ?cover:Bool = true):Void
function getText():String
function setText(value:String):Void
function getTip():String
function setTip(value:String):Void
function isHoldForPress():Bool
function setHoldForPress(value:Bool):Void
function getPrompt():String
function setPrompt(value:String):Void
function enter():Void
function isHolding():Bool
function update(dt:Float):Void
function exit():Void
function draw():Void
```

- `new`: The built-in loading scene with the default theme.
- `getTheme`: Its theme.
- `setTheme`: The theme it draws with.
- `getImage`: Its picture, or null.
- `setImage`: A picture behind the rest: covering the screen (cropped to its shape) when cover, else centered whole; null for the panel color alone.
- `getText`: The caption over the bar.
- `setText`: The caption over the bar: what's loading ("Loading the caves").
- `getTip`: The tip along the bottom, "" for none.
- `setTip`: A line along the bottom (a hint, a credit), wrapped; "" for none.
- `isHoldForPress`: Whether it stays once loaded, until a press.
- `setHoldForPress`: Stays once the loads are done, showing the prompt, until a key, a button or a finger is pressed.
- `getPrompt`: The line shown once loaded, while holding for a press.
- `setPrompt`: Sets the line shown while holding.

## LoadingScene

*class* in `src/helix/scene/LoadingScene.hx`

A scene shown while another's loads are pending (Scenes.setLoadingScene): the stack hands it the loader before it enters, and it draws the loader's progress and failures. Loading is the built-in one; another extends this and draws its own.

```haxe
function new()
function getShownLoader():Null<Loader>
function setLoader(value:Null<Loader>):Void
function isHolding():Bool
```

- `new`: Not showing a loader yet.
- `getShownLoader`: The loader it shows, or null (its own getLoader stays empty: a loading scene loads nothing first).
- `setLoader`: The loader to show: set by the stack as the wait begins.
- `isHolding`: Whether to stay shown once the loads are done (a "loaded, press to go" screen): the stack keeps it until this is false. False unless overridden.

## Pointer

*class* in `src/helix/scene/Pointer.hx`

The pointer over stages: which node it's over, and what it pressed and clicked, asked of it, never told to the nodes (DECISIONS 61). The stages it looks at are added in draw order, each with the camera it's drawn through; update() picks them topmost (last added) first, once a frame after input is polled, so a HUD drawn over the world takes the pointer first. A press on a 2D node captures the pointer: until it's released, the stages under it see nothing (isCaptured, for an app's own use of the pointer too). Edges (isPressed, isClicked) last the frame they happen in. Nodes are compared by identity: a 3D stage's are Nodes, a 2D stage's Node2Ds.

```haxe
function new(input:IInput)
function addStage2D(stage:Stage2D, camera:Camera2D):Void
function addStage3D(stage:Stage3D, camera:Camera3D):Void
function remove(stage:Any):Void
function update():Void
function getHovered():Null<Any>
function isHovered(node:Any):Bool
function isPressed(node:Any):Bool
function isDown(node:Any):Bool
function isClicked(node:Any):Bool
function getHeld():Null<Any>
function isCaptured():Bool
function getHit3D():Null<PickHit>
```

- `new`: The pointer of input.
- `addStage2D`: Looks at stage through camera, above the stages added before it.
- `addStage3D`: Looks at stage through camera, above the stages added before it.
- `remove`: Stops looking at stage (2D or 3D); what it held lets go.
- `update`: Once a frame, after input is polled and before the stages' nodes are read: picks under the pointer, topmost stage first, and works out the frame's press and click.
- `getHovered`: The node under the pointer, topmost stage first, or null.
- `isHovered`: Whether node is under the pointer.
- `isPressed`: Whether the pointer went down on node this frame.
- `isDown`: Whether node is held: the pointer went down on it and hasn't come up, wherever it is now (a drag).
- `isClicked`: Whether node was clicked this frame: the pointer came up over the node it went down on.
- `getHeld`: The node held (isDown), or null.
- `isCaptured`: Whether a press on a 2D stage holds the pointer: the stages under it, and the app's own world controls, should leave it be.
- `getHit3D`: The last hit in a 3D stage (its point, normal, distance), when the hovered node is a 3D stage's; null otherwise.

## Scene

*class* in `src/helix/scene/Scene.hx`

One screen of a game (a splash, a title, a level, a pause menu) on a Scenes stack, which calls it through the object (hooks are overrides, so a hot reload reaches them, DECISIONS 123): enter once it's pushed, update and draw each frame while it's on top, pause when another is pushed over it or the window loses focus, resume when that ends, exit when it's popped or replaced. A scene that loads first returns its Loader (getLoader) from enter on: the stack shows its loading scene until the loader is done, then runs this one. draw begins the frame (Services.graphics.beginFrame) and draws; the stack ends it, after any transition it draws over.

```haxe
function new()
function getName():String
function getScenes():Null<Scenes>
function getLoader():Null<Loader>
function getLoadingScene():Null<LoadingScene>
function enter():Void
function exit():Void
function pause():Void
function resume():Void
function update(dt:Float):Void
function draw():Void
```

- `new`: A scene not on a stack yet.
- `getName`: Its name: the class's, without its package, unless overridden; what an autopilot's probe reports.
- `getScenes`: The stack it's on, or null.
- `getLoader`: The loads it waits for before it runs, or null for none: made in enter.
- `getLoadingScene`: The loading scene shown while its loads are pending, or null for the stack's (Scenes.getLoadingScene): a level with its own picture and caption.
- `enter`: Pushed onto the stack: make what it needs, start its loads.
- `exit`: Popped or replaced: free what it made.
- `pause`: Another scene pushed over it, or the window lost focus (Scenes.setPauseOnBlur).
- `resume`: On top again, or the window focused again.
- `update`: A frame's logic, dt seconds since the last (the game's clock's delta, or an autopilot's tick).
- `draw`: A frame's drawing: begins the frame and draws; the stack ends the frame.

## Scenes

*class* in `src/helix/scene/Scenes.hx`

A game's scenes as a stack: the top one runs; push puts one over it (the one under pauses: a pause menu over play), pop takes it off (the one under resumes), replace swaps the top (a title for a level). A transition handed to any of them draws over the frames while the scenes swap at its middle. A scene with a loader (Scene.getLoader) is shown the loading scene until its loads are done: the built-in Loading unless setLoadingScene gives another, or none. The window losing focus pauses the game's clock and the top scene (setPauseOnBlur, on unless turned off); focus resumes them. Scenes read input through getInput (Services.input, or what an autopilot gives through setInput). frame runs update then draw; an autopilot runs several updates a frame and one draw. Quick (setQuick; on with the run option quick=1, a developer's) skips the built-in screens' waits and every transition: the game jumps in as soon as it's loaded.

```haxe
function new()
function isQuick():Bool
function setQuick(value:Bool):Void
function getTop():Null<Scene>
function getCount():Int
function getAll():Array<Scene>
function getInput():IInput
function setInput(value:IInput):Void
function getLoadingScene():Null<LoadingScene>
function setLoadingScene(value:Null<LoadingScene>):Void
function isPauseOnBlur():Bool
function setPauseOnBlur(value:Bool):Void
function isTransitioning():Bool
function isLoading():Bool
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
- `isQuick`: Whether the built-in screens' waits and the transitions are skipped (the run option quick=1, or setQuick).
- `setQuick`: Skips, or not, the built-in screens' waits and every transition.
- `getTop`: The scene on top, or null.
- `getCount`: How many scenes are stacked.
- `getAll`: The scenes, bottom first.
- `getInput`: The input scenes read: Services.input, or what setInput gave.
- `setInput`: What scenes read instead of Services.input: an autopilot's.
- `getLoadingScene`: The scene shown while the top one's loads are pending, or null for none (the scene shows itself loading).
- `setLoadingScene`: Sets the loading scene: the built-in Loading to start, any LoadingScene, or null to show none.
- `isPauseOnBlur`: Whether the window losing focus pauses the game's clock and the top scene.
- `setPauseOnBlur`: Turns pausing on focus loss on or off.
- `isTransitioning`: Whether a transition is under way (input is still the scenes').
- `isLoading`: Whether the loading scene is showing: the top scene's loads are pending, or the loading scene holds after them (LoadingScene.isHolding).
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

The built-in splash: a logo (or none) centered on the theme's panel color for at least its seconds, then the next scene, once the user has pressed a key, a button or a finger (IInput.isActivated: a browser lets audio start and fullscreen be asked for only after that; the same rule everywhere), or after setMaxWait's seconds without one: "press any key" shows until then, or, where a press came already, nothing. A pad's press doesn't count (a browser can't unlock with one), so the line stays for a tap. Pushed with a Fade, it fades in from the color. Extend it for another look; setTheme for its colors and font, setPrompt for the line.

```haxe
function new(logo:Null<Texture2D>, seconds:Float, next:Scene, ?transition:Transition)
function getTheme():Theme
function setTheme(value:Theme):Void
function getPrompt():String
function setPrompt(value:String):Void
function getShown():Float
function getMaxWait():Float
function setMaxWait(seconds:Float):Bool
function exit():Void
function update(dt:Float):Void
function draw():Void
```

- `new`: A splash of logo (null: the theme's colors alone), shown at least seconds, then next, by transition (a half-second fade unless given).
- `getTheme`: Its theme.
- `setTheme`: The theme it draws with.
- `getPrompt`: What it asks for the press with.
- `setPrompt`: The line shown until a press comes ("press any key" to start).
- `getShown`: Seconds shown so far.
- `getMaxWait`: The most seconds it waits for a press before going on without one; 0 for as long as it takes.
- `setMaxWait`: Goes on after seconds even without a press (a game that needs no audio unlock, or one that unlocks later), 0 to wait for one. False, changing nothing, for under 0.

## Transition

*class* in `src/helix/scene/Transition.hx`

How one scene gives way to the next on a Scenes stack: drawn over the frames for its seconds, the old scene under its first half and the new under its second (the swap is at the middle). A transition runs on the frames' time, not the game's clock, so a paused game still transitions to its menu. Fade is the one made; another draws anything over the frame by progress.

```haxe
function new(seconds:Float)
function getSeconds():Float
function draw(batch:Batch2D, width:Float, height:Float, progress:Float):Void
```

- `new`: A transition taking seconds. Throws for 0 or less.
- `getSeconds`: How long it takes.
- `draw`: Draws it over the frame, width by height framebuffer pixels, at progress 0 to 1 (the swap at .5), into batch, begun on a camera of framebuffer pixels. Nothing by default.
