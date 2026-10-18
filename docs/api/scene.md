# helix.scene

[Back to the index](README.md)

## ArgumentSchema

*class* in `src/helix/scene/SceneSchema.hx`

One argument of a mesh generator (Mesh.plane's width, Mesh.sphere's rings): its name as the generator's parameter is named, and the generator's default, null for one it requires. A count (rings, segments, subdivisions) is a whole number; a file's number is rounded toward zero for it.

```haxe
function new(name:String, ?defaultValue:Float)
final name:String
final defaultValue:Null<Float>
var required(get, never):Bool
```

- `new`: An argument name, with the generator's default or none.
- `name`: Its name, as the generator names the parameter (width, radius, segments).
- `defaultValue`: The generator's default, which the writer leaves out of the file; null for an argument the generator requires.
- `required`: Whether the generator requires it: a file leaving it out is refused.

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

## KindSchema

*class* in `src/helix/scene/SceneSchema.hx`

One kind's table: its name, as the file's "kind" names the class, its properties in the order the writer writes them, and what the class starts its flags at (an unsaid flag in a file means the kind's own default, and a flag at it isn't written).

```haxe
function new(name:String, properties:Array<PropertySchema>, ?enabled:Bool = true, ?visible:Bool = true, ?pickable:Bool = true)
final name:String
final properties:Array<PropertySchema>
final enabled:Bool
final visible:Bool
final pickable:Bool
function property(name:String):Null<PropertySchema>
```

- `new`: A kind name with properties, its flags starting at enabled, visible and pickable (each true unless said).
- `name`: The class's name: Model, DirectionalLight, Camera3D.
- `properties`: Its properties, in writing order: a parent class's first (a light's before a spot's range and cones).
- `enabled`: What the class starts Node.enabled at: true for every kind.
- `visible`: What the class starts Node.visible at: true for every kind.
- `pickable`: What the class starts Node.pickable at: false for a Text3D (a label lets a pick through to what it names), true elsewhere.
- `property`: Its property named name, or null for one it hasn't.

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

## NodeOrigin

*enum* in `src/helix/scene/SceneInstance.hx`

Where a node of an instance came from.

- `Entry(entry:SceneNode)`: The file's own entry: made from it, or added under a file's or a prefab's node by an override's children.
- `FileNode(file:String, innerPath:String)`: A model file (a Model entry's "file") made it: the file's path and the node's path inside it, from the entry's node.
- `Prefab(scene:String, innerPath:String)`: A prefab (a "scene" entry) made it: the prefab's path and the node's path inside it, from the entry's node.

## NodeRecord

*class* in `src/helix/scene/SceneInstance.hx`

What an instance keeps of a node: its origin, the values the origin gave it (its snapshot, taken before any override), the game's props, and for an entry with a file or a prefab, whether its overrides have been applied (false while the file loads, or for one that failed: its overrides are then kept as written).

```haxe
function new(node:Node3D, kind:Null<String>, origin:NodeOrigin, snapshot:NodeSnapshot)
final node:Node3D
final kind:Null<String>
var origin:NodeOrigin
var owner:Null<Node3D>
var entry:Null<SceneNode>
var snapshot:NodeSnapshot
var props:Null<Map<String, SceneValue>>
var overridesApplied:Bool
```

- `new`: A record of node from origin with snapshot.
- `node`: The node.
- `kind`: Its kind, as SceneSchema's tables name it; null for a class no table has.
- `origin`: Where it came from.
- `owner`: The entry's node whose file or prefab made it; null for an entry's own node.
- `entry`: The entry it was made from, when one was (a prefab's node keeps its prefab's entry); null for a model file's node.
- `snapshot`: Its values as its origin gave them, before overrides.
- `props`: The game's own values the file gave it; null for a node a file or a prefab made.
- `overridesApplied`: For an entry with a file or a prefab: whether its overrides were applied.

## NodeSnapshot

*class* in `src/helix/scene/SceneInstance.hx`

A node's values as a file sees them: its transform, flags, its kind's properties and, for a Model, its material and its generated mesh.

```haxe
function new(node:Node3D, ?entry:SceneNode)
var position:Array<Float>
var rotation:Array<Float>
var scale:Array<Float>
var enabled:Bool
var visible:Bool
var pickable:Bool
var properties:Map<String, SceneValue>
var material:Null<SceneMaterial>
var mesh:Null<SceneMesh>
```

- `new`: Node's values now: its transform and flags, every property of its kind that reads, and its material. Where read gives nothing yet (a texture still loading), entry's value for the property stands in, when given.
- `position`: Its position, x, y, z.
- `rotation`: Its rotation, Euler x, y, z in radians as Node3D reads them back.
- `scale`: Its scale, x, y, z.
- `enabled`: Node.enabled.
- `visible`: Node.visible.
- `pickable`: Node.pickable.
- `properties`: Its kind's properties by name, those readable.
- `material`: A Model's material as read; null for another kind or a model of no parts.
- `mesh`: A Model's generated mesh as read from its record (Mesh.shape), else the entry's mesh when given; null for another kind or a mesh of no record.

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

## PropertySchema

*class* in `src/helix/scene/SceneSchema.hx`

One property of a kind: its name as the class names it, its type, and the class's default, which the writer leaves out of the file.

```haxe
function new(name:String, type:PropertyType, defaultValue:SceneValue)
final name:String
final type:PropertyType
final defaultValue:SceneValue
```

- `new`: A property name of type type, whose class starts it at defaultValue.
- `name`: Its name, as the class names the property (intensity, fovY, shadowCasting).
- `type`: The shape of its value.
- `defaultValue`: What the class starts with: a value equal to it is not written, and an absent key means it.

## PropertyType

*enum* in `src/helix/scene/SceneSchema.hx`

What a kind's property holds in a .scene file: the shape the parser checks a value against, the writer writes, and an inspector makes a control for.

- `Number(?min:Float, ?max:Float)`: A number, held from min to max where given (null for no bound), as the class clamps it.
- `Text`: Text: a path to an asset, or a named choice in lower case (a sprite's facing: "camera", "upright", "ground", "free").
- `Flag`: A bool.
- `Numbers(count:Int)`: A list of count numbers.
- `Color`: A color, "#RRGGBB" or "#RRGGBBAA" in the file, 0xRRGGBBAA in memory.
- `Reference`: A reference to a node of the file, "@name" or "@path/from/root" in the file.

## Scene

*class* in `src/helix/scene/Scene.hx`

One screen of a game (a splash, a title, a level, a pause menu) on a Scenes stack, which calls it through the object (hooks are overrides, so a hot reload reaches them, DECISIONS 123): enter once it's pushed, update and draw each frame while it's on top, pause when another is pushed over it or the window loses focus, resume when that ends, exit when it's popped or replaced. A scene that loads first returns its Loader (loader) from enter on: the stack shows its loading scene until the loader is done, then runs this one. draw begins the frame (Graphics.beginFrame) and draws; the stack ends it, after any transition it draws over. Its behaviors (behaviors) are a pass of its own, which the stack updates just before update each frame this scene runs, and clears, stopping each, just before exit.

```haxe
function new()
var behaviors(default, null):Behaviors
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

- `new`: A scene not on a stack yet, its behaviors pass empty.
- `behaviors`: Its behaviors: the pass the stack updates before its update each frame it runs (not while it's under another scene, loading or the window is unfocused) and clears before its exit. What a scene file instantiated onto this scene attaches its behaviors to.
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

## SceneBehavior

*class* in `src/helix/scene/SceneBehavior.hx`

A behavior as a .scene file attaches it to a node: the behavior class's name and its props by name, as data. The file says which behaviors a node gets; at run time they live in the behaviors pass, never on the node.

```haxe
function new(kind:String)
var kind:String
var props:Map<String, SceneValue>
```

- `new`: A behavior of class kind with no props set.
- `kind`: The behavior class's name, as the registry knows it.
- `props`: Its props by name: numbers, text, flags, lists, colors and references to nodes of the file.

## SceneFile

*class* in `src/helix/scene/SceneFile.hx`

A .scene file as parsed: HeliX's own JSON, one tree. Its version ("helix-scene"), its stage section and its nodes, each a SceneNode with its kind's properties as SceneSchema's tables say. Parsed from bytes, every problem logged through Failure and the whole refused, so a file either loads as written or says why; written back canonically (write), so load, write, load gives the same bytes and a hand edit stays where it was made; instantiated onto a stage (instantiate) and captured back from a live instance (capture).

```haxe
function new()
static var VERSION(inline, null):Int
static function parse(bytes:haxe.io.Bytes, ?path:String):Null<SceneFile>
static function capture(instance:SceneInstance):SceneFile
var version:Int
var stage:Null<SceneStage>
var nodes:Array<SceneNode>
function instantiate(stage:Stage3D, behaviors:Behaviors, ?ready:() -> Void):SceneInstance
var path(default, null):Null<String>
function write():haxe.io.Bytes
```

- `new`: An empty file of the current version: no stage section, no nodes.
- `VERSION`: The format version read and written: the file's "helix-scene" value.
- `parse`: The file in bytes (JSON), parsed; path names it in the log. Null, with every problem logged through Failure naming the node's path or the key, for a file that isn't a JSON object, a missing or other "helix-scene" version, an unknown key at the root, in the stage section or in a material, a node without a name, two siblings with one name, a node with both "kind" and "scene" or neither, a kind no table has, a key no table has on a node or an override, a value of the wrong shape, a file, a mesh or a material on a kind that isn't a Model, a Model with both a file and a mesh, a mesh without a shape or of a shape no generator makes, with a key its shape hasn't, a required argument missing or one that isn't a number, overrides on a node with no file and no scene, an override with a name, a kind, a mesh or an empty path, or a behavior without a kind.
- `capture`: The file that would instantiate to what instance is now: the stage section from its stage (what isn't the stage's default), each of the instance's own nodes from the live node (its kind, name, transform, flags, properties, material where the file gave one, the behaviors the instance attached with their props away from their defaults, its props), a node from a model file or a prefab as the reference plus an override for every node under it whose values differ from what the file gave (what differs only, with the children and behaviors attached there; a file that hasn't landed keeps its overrides as written), and a node a game added at run time as its class with its properties (a Model whose mesh came from one of Mesh's generators as its mesh entry; one whose mesh has no record of what made it, from arrays or a file, has no file and loads back as an empty Model: logged once). A reference is written as the node's name when one node of the instance has it, else its path. The defaults rule: a capture says only what differs from the defaults, so the stage section holds what isn't the stage's default, a behavior's prop at its schema default is left out, a kind's property at its class's default is left out, and a flag at its kind's own default is left out; a default a hand wrote into the file vanishes on capture. Capturing an untouched instance gives the file it was made from, written canonically.
- `version`: The file's "helix-scene" version: VERSION, the only one read.
- `stage`: Its stage section, or null when the file has none.
- `nodes`: Its nodes at the root, in drawing order.
- `instantiate`: Makes the file's tree on stage, its behaviors on behaviors: the stage section applied (ambient, tonemap and exposure at once, the environment and background once their files land through Environments), then every node at once under a new group named after the file (its path without directory and extension) added to the stage's root, a Model's file and a prefab landing later through Models and SceneFiles (their nodes moved under the entry's node, which is then the file's root, the entry's overrides applied by path), each node's behaviors made from BehaviorRegistry and attached once everything has landed. ready, when given, is called at the pass's next update after that, once the behaviors have started: never inside this call. A missing model, prefab or environment, a prefab naming itself (directly or through another), an unknown behavior, a refused prop or property, and an override naming no node are each logged through Failure with this file's path and the node's, the rest made, and ready still comes. The instance remembers where each node came from, for capture.
- `path`: The path it was parsed under, as parse was given it; "scene" for none. What instantiate names the instance by.
- `write`: The file as canonical JSON: keys in a fixed order, two-space indentation, one key per line, number lists on one line, a trailing newline, numbers with at most six decimals and no trailing zeros, written alike on every target. Absent keys mean defaults: a transform at identity, a node's flag at its kind's own default (an override's is written whenever said), a property at its class's default, a mesh's argument at its generator's default, an unsaid stage or material value, and a property no table has, are not written.

## SceneFileCache

*class* in `src/helix/scene/SceneFileCache.hx`

Scene files (.scene) loaded through the assets into SceneFiles, parsed once and shared by path, as ModelCache is for models: a path asked for again is the file already parsed (or its refusal, remembered), and asking while it loads joins the load. A file's models, prefabs, textures and environments are loaded through their own caches as the file is instantiated, so a level's models aren't fetched twice. The runner's is what the SceneFiles static forwards to.

```haxe
function new(assets:IAssets)
function load(path:String, loaded:SceneFile -> Void, ?failed:String -> Void):IRequest
function find(path:String):Null<SceneFile>
function isLoaded(path:String):Bool
function isLoading(path:String):Bool
var loadingCount(get, never):Int
function put(path:String, file:SceneFile):Void
function forget(path:String):Void
function shutdown():Void
```

- `new`: Loads through assets.
- `load`: Loads path (a .scene) into a SceneFile, parsed with SceneFile.parse under its path. One of loaded or failed runs once: during this call when the file is loaded already (or failed before; forget clears a failure), else on the host thread when its load ends; failed (else the log, with the path) for a load failure or a file the parser refuses, with its reason (each problem the parser found is logged as well). Neither runs once the request is cancelled (the shared load goes on for the others) or the cache shuts down.
- `find`: The file at path if it's loaded, else null.
- `isLoaded`: Whether path is loaded.
- `isLoading`: Whether path is loading.
- `loadingCount`: How many files are loading.
- `put`: Adds a file parsed some other way under path, as if loaded from there (a test's, a generated one).
- `forget`: Forgets path: its file (the instances made from it stay) or its failure, so it's loaded again when next asked for.
- `shutdown`: Cancels every load (telling none of its callers) and forgets every file.

## SceneFiles

*class* in `src/helix/scene/SceneFiles.hx`

Scene files (.scene), parsed once and shared by path (SceneFileCache). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from SceneFileCache's public members with their doc comments.

```haxe
static var instance(default, null):SceneFileCache
static function load(path:String, loaded:SceneFile -> Void, ?failed:String -> Void):IRequest
static function find(path:String):Null<SceneFile>
static function isLoaded(path:String):Bool
static function isLoading(path:String):Bool
static var loadingCount(get, never):Int
static function put(path:String, file:SceneFile):Void
static function forget(path:String):Void
```

- `instance`: The scene files forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `load`: Loads path (a .scene) into a SceneFile, parsed with SceneFile.parse under its path. One of loaded or failed runs once: during this call when the file is loaded already (or failed before; forget clears a failure), else on the host thread when its load ends; failed (else the log, with the path) for a load failure or a file the parser refuses, with its reason (each problem the parser found is logged as well). Neither runs once the request is cancelled (the shared load goes on for the others) or the cache shuts down.
- `find`: The file at path if it's loaded, else null.
- `isLoaded`: Whether path is loaded.
- `isLoading`: Whether path is loading.
- `loadingCount`: How many files are loading.
- `put`: Adds a file parsed some other way under path, as if loaded from there (a test's, a generated one).
- `forget`: Forgets path: its file (the instances made from it stay) or its failure, so it's loaded again when next asked for.

## SceneInstance

*class* in `src/helix/scene/SceneInstance.hx`

What instantiating a .scene file gives (SceneFile.instantiate): its root, a group named after the file under the stage's root holding every node the file made, the nodes by path, the behaviors it attached, the game's props by node, and whether every load has landed (ready). It remembers where each node came from (the file's own entry, a model file by path, a prefab by path) and the values the origin gave it, so SceneFile.capture writes back a file that instantiates to what the tree is now, a node from a file or a prefab as the reference plus what differs. destroy takes it all out again.

```haxe
static function baseName(path:String):String
var path(default, null):String
var root(default, null):Node3D
var stage(default, null):Stage3D
var behaviors(default, null):Array<Behavior>
var ready(default, null):Bool
function node(path:String):Null<Node3D>
function pathOf(node:Node3D):Null<String>
function props(node:Node3D):Null<Map<String, SceneValue>>
function destroy():Void
```

- `baseName`: The file's name without directory and extension: "levels/track.scene" gives "track".
- `path`: The file's path, as it was loaded.
- `root`: The node holding everything the file made: a group named after the file (its path without directory and extension), under the stage's root.
- `stage`: The stage the file was instantiated onto, whose settings the file's stage section set.
- `behaviors`: The behaviors it attached, in the order the file gave them, prefabs' included.
- `ready`: Whether every model, prefab, texture, font and environment the file names has landed or failed, and the behaviors are attached to the pass: false until then. The ready lambda given to instantiate follows at the pass's next update, once they have started.
- `node`: The node at path, slash-separated names from the root (never the root's own name), through nodes a file or a prefab made; null for none. The first of two siblings named alike.
- `pathOf`: Node's path from the root, as node takes it; null for the root itself or a node not under it.
- `props`: The game's own values the file gave node ("props"), kept here, never on the node; null for a node the file didn't make.
- `destroy`: Takes it out: its behaviors from the pass (stopping the started ones), its root from the stage, and the textures, fonts and environments it loaded released to their caches (the last release frees each). Its model and scene files stay in their caches, which keep files until told to forget them. A load still under way is cancelled.

## SceneKinds

*class* in `src/helix/scene/SceneKinds.hx`

The live side of SceneSchema's tables, in one module so the two can't drift: a node of a kind made from its name, a kind's property applied to a live node from a file's value and read back from it, a Model's inline material applied and read, and its generated mesh made by Mesh's generators and read back from the mesh's record. What the tables name as text here becomes the classes' values: an enum's case from its lower-case name (a sprite's facing, its alpha mode, a camera's projection, the stage's tonemap), a texture or a font from its path through Textures and Fonts, a color as 0xRRGGBBAA.

```haxe
static function make(kind:String):Null<Node3D>
static function kindOf(node:Node3D):Null<String>
static function apply(node:Node3D, name:String, value:SceneValue, ?instance:SceneInstance):Bool
static function read(node:Node3D, name:String):Null<SceneValue>
static function makeMesh(mesh:SceneMesh):Null<Mesh>
static function readMesh(mesh:Mesh):Null<SceneMesh>
static function applyMaterial(model:Model, material:SceneMaterial, ?instance:SceneInstance):Void
static function readMaterial(model:Model):Null<SceneMaterial>
static function tonemapOf(name:String):Null<Tonemap>
static function tonemapName(tonemap:Tonemap):String
static function projectionOf(name:String):Null<Projection>
static function projectionName(projection:Projection):String
static function facingOf(name:String):Null<SpriteFacing>
static function facingName(facing:SpriteFacing):String
static function alphaOf(name:String):Null<SpriteAlpha>
static function alphaName(alpha:SpriteAlpha):String
```

- `make`: A new node of kind, as SceneSchema's tables name the classes: a bare Node3D for "Node3D", a Model of no parts, a light, a camera, a sprite of no texture, a text of no text, a Particles3D with an emitter of no texture holding 1024 particles. Null for a name no table has.
- `kindOf`: The kind node is, as the tables name it: its class's name (a Node3D of no other class is "Node3D"). Null for a class no table has.
- `apply`: Sets node's property name to value, as its own kind's table has it: a light's intensity, a camera's fovY, a spot's cones (each through setCone, the other widened or narrowed to keep the pair in order) and a camera's near and far (the other moved just past it to keep the pair in order, so a file giving both lands on both whichever comes first), a sprite's region and size, a text's size. A texture's or a font's path loads through Textures or Fonts and lands when it does ("" for none); instance, when given, keeps what it loads to release at its destroy. False, changing nothing, for a property node's kind hasn't, a value of the wrong shape, a named choice no enum has, or a value the class refuses.
- `read`: Node's property name as it is now, as its own kind's table has it; a texture or a font as the path it was loaded from. Null for a property node's kind hasn't, or one that can't be read now: a sprite with no texture or a text with no font (none, or one not yet landed), or one that didn't come through the caches.
- `makeMesh`: The mesh a file's mesh entry names, made by Mesh's generator of its shape with its arguments, an unsaid one the generator's default (SceneSchema.shapes), a count rounded toward zero. Null for a shape no generator makes or a required argument missing.
- `readMesh`: Mesh as a file's mesh entry, from its record of what made it (Mesh.shape), every argument said (the writer leaves out those at the generator's default). Null for a mesh with no record (from arrays or a file) or a shape the tables don't have.
- `applyMaterial`: Gives model a new material carrying material's values, the rest Material's defaults, as its first part's (made when it has none): an inline material replaces the mesh's or the file's. Its textures load through Textures by path and land when they do; instance, when given, keeps them to release at its destroy.
- `readMaterial`: Model's first part's material as a file writes it, every value said; a texture as the path it was loaded from, or unsaid (null) for none or one that didn't come through Textures. Null for a model of no parts.
- `tonemapOf`: The tone mapping named name, "none", "neutral" or "aces" (SceneSchema.tonemaps); null for another name.
- `tonemapName`: Tonemap's name as the file writes it (SceneSchema.tonemaps).
- `projectionOf`: The projection named name, "perspective" or "orthographic" (SceneSchema.projections); null for another name.
- `projectionName`: A projection's name as the file writes it (SceneSchema.projections).
- `facingOf`: The facing named name, "camera", "upright", "ground" or "free"; null for another name.
- `facingName`: A facing's name as the file writes it.
- `alphaOf`: The alpha mode named name, "opaque", "mask", "blend" or "add"; null for another name.
- `alphaName`: An alpha mode's name as the file writes it.

## SceneMaterial

*class* in `src/helix/scene/SceneMaterial.hx`

A material as a .scene file writes it inline on a Model: Material's values, each null when the file doesn't say it, so an override changes one value and leaves the rest.

```haxe
function new()
var baseColor:Null<Int>
var metallic:Null<Float>
var roughness:Null<Float>
var texture:Null<String>
var normalTexture:Null<String>
var normalScale:Null<Float>
var emissive:Null<Int>
var emissiveStrength:Null<Float>
var doubleSided:Null<Bool>
```

- `new`: A material saying nothing.
- `baseColor`: The base color, 0xRRGGBBAA; null for unsaid.
- `metallic`: How metallic, 0..1; null for unsaid.
- `roughness`: How rough, 0..1; null for unsaid.
- `texture`: The base color texture's path; null for unsaid.
- `normalTexture`: The normal map's path; null for unsaid.
- `normalScale`: How strongly the normal map bends the surface, 0 or more; null for unsaid.
- `emissive`: The light it gives off, 0xRRGGBBAA; null for unsaid.
- `emissiveStrength`: How bright its emissive light is, 0 or more; null for unsaid.
- `doubleSided`: Whether both sides of its triangles draw; null for unsaid.

## SceneMesh

*class* in `src/helix/scene/SceneMesh.hx`

A generated mesh as a .scene file writes it on a Model ("mesh", in place of a file): the shape's name (plane, cube, sphere, cylinder, cone, capsule or torus: SceneSchema.shapes) and its numbers by the generator's own argument names (a plane's width, length and subdivisions; a sphere's radius, rings and segments), an optional one absent when the generator's default.

```haxe
function new(shape:String)
var shape:String
var arguments:Map<String, Float>
```

- `new`: A mesh of shape with no argument said yet.
- `shape`: The shape's name, one of SceneSchema.shapes.
- `arguments`: Its arguments by name, those said; one absent is the generator's default.

## SceneNode

*class* in `src/helix/scene/SceneNode.hx`

A node as a .scene file has it, not a live one: its kind (or the prefab it instantiates), name, a Model's glTF or generated mesh, its transform and flags (each null when unsaid), its kind's properties by name, an inline material, overrides by path for the nodes its file or prefab makes, its children, the behaviors to attach and the game's own props. Each absent part means the default: a null transform is identity, a null flag true, a property its class's. An override is a SceneNode too, with no name, kind or scene: only what it changes, plus children and behaviors to add. Phase 3 of the file's plan makes live nodes from these and captures them back.

```haxe
function new(?kind:String, ?name:String)
var name:Null<String>
var kind:Null<String>
var scene:Null<String>
var file:Null<String>
var mesh:Null<SceneMesh>
var position:Null<Array<Float>>
var rotation:Null<Array<Float>>
var scale:Null<Array<Float>>
var enabled:Null<Bool>
var visible:Null<Bool>
var pickable:Null<Bool>
var properties:Map<String, SceneValue>
var material:Null<SceneMaterial>
var overrides:Map<String, SceneNode>
var children:Array<SceneNode>
var behaviors:Array<SceneBehavior>
var props:Map<String, SceneValue>
var isOverride(get, never):Bool
```

- `new`: A node of kind (null for a prefab node or an override), named name (null for an override), everything else at its default.
- `name`: Its name, unique among its siblings (paths depend on it); null for an override.
- `kind`: The class it is (Node3D for a group, else a kind's name from SceneSchema); null for a prefab node or an override.
- `scene`: The .scene file instantiated here as a prefab; null for a node of a kind or an override.
- `file`: A Model's glTF, instantiated under it; null for none. A Model has a file or a mesh, never both.
- `mesh`: A Model's generated mesh, made by one of Mesh's generators as its first part; null for none.
- `position`: Its position, x, y, z in its parent's units; null for the origin.
- `rotation`: Its rotation, Euler x, y, z in radians as Node3D.setRotation takes them; null for none.
- `scale`: Its scale, x, y, z; null for 1, 1, 1.
- `enabled`: Whether it takes part at all (Node.enabled), as the file says it; null for unsaid: a node's default, true, when instantiated, and unchanged for an override, which may say true to bring a prefab's disabled node back.
- `visible`: Whether its own output is drawn (Node.visible), as the file says it; null for unsaid: true for a node, unchanged for an override.
- `pickable`: Whether a pick can hit it (Node.pickable), as the file says it; null for unsaid: true for a node, unchanged for an override.
- `properties`: Its kind's properties by name (intensity, fovY, tint), from its kind's table in SceneSchema; one absent is the class's default. An override's name any kind's property.
- `material`: A Model's inline material, replacing the mesh's or the file's root material; null for none.
- `overrides`: By path from this node ("road/line"), what changes on the nodes its file or prefab makes: each an override node.
- `children`: The nodes under it, in drawing order; under an override, the nodes added.
- `behaviors`: The behaviors attached to it when the scene is instantiated.
- `props`: The game's own values by name, kept by the instance for this node, never on the live node.
- `isOverride`: Whether it is an override: no name, no kind and no prefab, only what changes on a node another file made.

## SceneSchema

*class* in `src/helix/scene/SceneSchema.hx`

The kinds a .scene file's nodes can be and what each writes flat beside its name and transform: one table per kind, the one place that says it, so the parser checks keys and shapes against it, the writer writes in its order leaving defaults out, and an inspector reads its controls from it; nothing can be written that can't be read. The names are the classes' own (helix.render3d), the defaults what each class starts with. A kind without properties (Node3D, a group; Particles3D, whose emitter is set in code) is still a kind. Beside the kinds, the shapes a Model's "mesh" can name (shapes): Mesh's generators with their arguments and defaults.

```haxe
static var kinds(default, null):Array<KindSchema>
static var shapes(default, null):Array<ShapeSchema>
static final tonemaps(default, null):Array<String>
static final projections(default, null):Array<String>
static function kind(name:String):Null<KindSchema>
static function shape(name:String):Null<ShapeSchema>
static function property(name:String):Null<PropertySchema>
```

- `kinds`: Every kind's table, in the order the writer takes an override's properties (a node's own kind orders its own).
- `shapes`: The shapes a Model's "mesh" can name, one table per generator of Mesh with its arguments in the generator's order and the generator's defaults: the parser checks a mesh's keys against it, the writer writes them in its order leaving defaults out, and SceneKinds calls the generator from it.
- `tonemaps`: What the stage's "tonemap" may say: Tonemap's cases in lower case, in its order, so the index of a name is the case's value.
- `projections`: What a camera's "projection" may say: Projection's cases in lower case, in its order, so the index of a name is the case's value.
- `kind`: The table of the kind named name (as the file's "kind" has it), or null for a kind the file can't hold.
- `shape`: The table of the shape named name (as a mesh's "shape" has it), or null for a shape no generator makes.
- `property`: The property named name on whichever kind has it first, or null for a name no kind has: for an override, whose node's kind is the model's or the prefab's to know, not the file's. A name means one type wherever it is (color is a color on a light and on text).

## SceneStage

*class* in `src/helix/scene/SceneStage.hx`

A .scene file's stage section: what a Stage3D keeps apart from its tree (its ambient light, environment, background, tone mapping and exposure). Each null means the stage's default and is not written. Only a file instantiated onto a stage applies it; a prefab's is logged and ignored.

```haxe
function new()
var ambientColor:Null<Int>
var ambientIntensity:Null<Float>
var environmentFile:Null<String>
var environmentIntensity:Null<Float>
var environmentRotation:Null<Float>
var backgroundFile:Null<String>
var backgroundBlur:Null<Float>
var tonemap:Null<String>
var exposure:Null<Float>
```

- `new`: A stage section saying nothing: every setting the stage's own.
- `ambientColor`: The ambient light's color, 0xRRGGBBAA; null for the stage's.
- `ambientIntensity`: The ambient light's intensity, 0 or more; null for the stage's.
- `environmentFile`: The environment's file (an HDR, loaded through Environments); null for none.
- `environmentIntensity`: How strongly the environment lights, 1 as its file has it; null for the stage's.
- `environmentRotation`: How far the environment and the background turn about +y, in radians; null for the stage's.
- `backgroundFile`: The background's file (an HDR, loaded through Environments); null for none.
- `backgroundBlur`: How blurred the background is, 0 sharp to 1; null for the stage's.
- `tonemap`: The tone mapping, "none", "neutral" or "aces" (Tonemap's cases in lower case); null for the stage's.
- `exposure`: The exposure in stops; null for the stage's.

## SceneValue

*enum* in `src/helix/scene/SceneValue.hx`

A value as a .scene file holds it: a kind's property, a behavior's prop, or one of a node's own props. JSON's own shapes (a number, text, a bool, a list of numbers), and two shapes of string the file gives a meaning: a color, "#RRGGBB" or "#RRGGBBAA", and a reference to a node of the file, "@name" or "@path/from/root".

- `Number(value:Float)`: A number.
- `Text(value:String)`: Text: a path to an asset, a named choice ("camera"), or what a behavior wants.
- `Flag(value:Bool)`: A bool.
- `Numbers(values:Array<Float>)`: A list of numbers.
- `Color(rgba:Int)`: A color, 0xRRGGBBAA; "#RRGGBB" in the file is alpha ff.
- `Reference(path:String)`: A reference to a node of the file: the name or path after the "@", resolved once every node is made.

## Scenes

*class* in `src/helix/scene/Scenes.hx`

A game's scenes as a stack: the top one runs; push puts one over it (the one under pauses: a pause menu over play), pop takes it off (the one under resumes), replace swaps the top (a title for a level). A transition handed to any of them draws over the frames while the scenes swap at its middle. A scene with a loader (Scene.loader) is shown the loading scene until its loads are done: the built-in Loading unless loadingScene gives another, or none. The window losing focus pauses the game's clock and the top scene (pauseOnBlur, on unless turned off); focus resumes them. Scenes read input through input (Input.instance, or what an autopilot gives through input). frame runs update then draw; an autopilot runs several updates a frame and one draw. A frame's update runs the top scene's behaviors pass (Scene.behaviors) and then its update, under the same gates (a transition's swap first; nothing while it loads or the window is unfocused); a scene's behaviors are cleared, each stopped, just before it exits. Quick (quick; on with the run option quick=1, a developer's) skips the built-in screens' waits and every transition: the game jumps in as soon as it's loaded.

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
- `update`: The frame's logic: the transition's time (the frames'), focus, then the top scene's behaviors and its update, or its loading scene's update while it loads.
- `draw`: The frame's drawing: the top scene's (or its loading scene's), the transition over it, then the frame's end.
- `destroy`: Frees what it made (the transition batch); the scenes are cleared first.

## ShapeSchema

*class* in `src/helix/scene/SceneSchema.hx`

One shape a Model's "mesh" can name: Mesh's generator of that name and its arguments in the generator's order, the required ones first.

```haxe
function new(name:String, arguments:Array<ArgumentSchema>)
final name:String
final arguments:Array<ArgumentSchema>
function argument(name:String):Null<ArgumentSchema>
```

- `new`: A shape name taking arguments.
- `name`: The generator's name: plane, cube, sphere, cylinder, cone, capsule or torus.
- `arguments`: Its arguments in the generator's order, which the writer keeps.
- `argument`: Its argument named name, or null for one it hasn't.

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
