# Milestone 11: the scene file and behaviors (design)

The design for the roadmap's milestone 11 entry: the pieces, their names, the file's shape, and the order of work. Decisions 61 (nodes draw only) and 130 (kinds as classes, behaviors never on a node) stand throughout. Settled with the user on 2026-10-18: behaviors are a package of their own (`helix.behavior`), the stage's settings are in the file, a behavior's props nest under `props`, the example is new (`scene-file`), the extension is `.scene`, and 2D comes after this pass.

## What exists

- `helix.scene.Scene` is a screen in the `Scenes` stack (`enter`, `exit`, `pause`, `resume`, `update(dt)`, `draw`), with a `Loader` and transitions. It holds no tree.
- `helix.scene.Node` is what both trees share: `name`, `enabled`, `visible`, `pickable`, children, `find(name)` (never a path). `Node3D` adds the transform, `addChild`, `addChildInPlace`, settable `parent`; the kinds (`Model` with parts, `DirectionalLight`, `PointLight`, `SpotLight`, `Camera3D`, `Sprite3D`, `Text3D`, `Particles3D`) are classes on it. `Stage3D` draws a tree.
- `Models.load(path, loaded)` gives a `ModelFile`; `file.instantiate()` gives a `Node3D` subtree whose nodes carry the glTF's names, its punctual lights and (from this milestone) its cameras as `Camera3D` nodes. The glTF reader takes no `extras`.
- `Timers` and `Tweens` are objects an app makes and updates itself (the motion example).
- The earlier framework's text scene (`wgf-scene 2`, line per fact) and the racer's use of it, with its lessons: a file's nodes are addressable by path for overrides, but every parent on the path needed a block of its own (awkward); no light kind, so the sun stayed code; a dump that lost flags didn't load back as the same world; a model's material numbers couldn't be set from the file; behaviors took parameters on a line (`behavior index=0`) and references to other actors by path.

## Names

The word *scene* is taken twice: a `Scene` is a screen, and a `.scene` file is a tree. Both stay as the roadmap wrote them, the file's classes named after the file. Behaviors are a package of their own, as tweens and timers are: nothing in a behavior needs the scene package, the pass runs on any app's nodes with no file and no screen, and the dependency runs one way, the scene package using behaviors.

| Piece | Class | Package |
|---|---|---|
| the parsed file | `SceneFile` | `helix.scene` |
| its cache and loader | `SceneFiles` (static, over `SceneFileCache`) | `helix.scene` |
| what instantiating gives | `SceneInstance` | `helix.scene` |
| a behavior | `Behavior` | `helix.behavior` |
| the pass | `Behaviors` | `helix.behavior` |
| the registry the macro fills | `BehaviorRegistry` | `helix.behavior` |
| the macro | `Behaviors` | `helix.macro` |

## The file

JSON, HeliX's own, one tree. Written with sorted keys, two-space indentation, numbers in Haxe's shortest round-trip form, so load, save, load gives the same bytes under test.

```json
{
  "helix-scene": 1,
  "stage": {
    "ambient": {"color": "#ffffff", "intensity": 0.25},
    "environment": {"file": "sky/sky.hdr", "intensity": 0.7, "rotation": 0},
    "background": {"file": "sky/sky.hdr", "blur": 0},
    "tonemap": "neutral",
    "exposure": 0
  },
  "nodes": [
    {
      "kind": "DirectionalLight",
      "name": "sun",
      "rotation": [-0.6, 0.7, 0],
      "color": "#fff4e0",
      "intensity": 3.5,
      "shadowCasting": true,
      "shadowDistance": 35
    },
    {
      "kind": "Model",
      "name": "track",
      "file": "track/track.glb",
      "overrides": {
        "road": {"shadowCasting": false},
        "road/line": {"shadowCasting": false},
        "gates/gate_0": {"children": [
          {"kind": "Node3D", "name": "checkpoint", "position": [0, 2, 0],
           "behaviors": [{"kind": "Checkpoint", "props": {"index": 0}}]}
        ]}
      }
    },
    {
      "kind": "Model",
      "name": "cone_1",
      "file": "props/cone.glb",
      "position": [12, 0, -3],
      "material": {"baseColor": "#ff8800", "roughness": 0.3}
    },
    {
      "scene": "prefabs/car.scene",
      "name": "car",
      "position": [0, 0.5, 12],
      "overrides": {"body": {"material": {"baseColor": "#2040c0"}}},
      "behaviors": [{"kind": "Car", "props": {"topSpeed": 60}}]
    },
    {
      "kind": "Camera3D",
      "name": "chase",
      "position": [0, 3, -8],
      "fovY": 0.9,
      "behaviors": [{"kind": "ChaseCamera", "props": {"target": "@car"}}]
    }
  ]
}
```

**`stage`** holds what `Stage3D` keeps apart from its tree: `ambient` (`setAmbient`), `environment` and `background` (files loaded through `Environments`, then `setEnvironment` and `setBackground`), `tonemap` and `exposure`; each absent when the stage's default. Only a file instantiated onto a stage applies it; a prefab's `stage` is logged and ignored.

What a node entry holds:

- **`kind`**: the class (`Node3D` for a plain group, else a kind's name). Absent when `scene` is present.
- **`name`**: the node's name; required, unique among siblings (paths depend on it).
- **the transform**: `position` `[x, y, z]`, `rotation` `[x, y, z]` radians (Euler, as `setRotation` takes), `scale` `[x, y, z]`; each absent when identity. (A quaternion isn't written: `rotation` is what a hand edits.)
- **the flags**: `enabled`, `visible`, `pickable`, absent when true.
- **the kind's properties**, flat beside the above, named as the class names them (`intensity`, `shadowCasting`, `fovY`, `range`, `tint`, `text`): one table per kind lists them with their type and default, and both the reader and the writer go through that table, so nothing can be written that can't be read. Colors are `"#RRGGBB"` or `"#RRGGBBAA"`.
- **`file`** on a `Model`: a glTF, loaded through `Models` and instantiated under this node, which becomes the file's root (its parts, skin and name). Its materials are the file's.
- **`material`** on a `Model`: an inline material (`baseColor`, `metallic`, `roughness`, `texture`, `normalTexture`, `emissive`, `doubleSided`), replacing the mesh's or the file's root material.
- **`scene`**: another file instantiated here as a prefab. A prefab file is an ordinary `.scene`; a file naming itself, directly or through another, is refused.
- **`overrides`**: by path from this node (`road/line`), for nodes a `file` or `scene` made. Each is an entry without `name` or `kind`: properties and transform keys change the node, `children` adds new nodes under it, `behaviors` attach to it. No block is needed for a parent on the path (the first lesson above).
- **`children`**: nodes under this one.
- **`behaviors`**: a list of `{"kind": "...", "props": {...}}` attached to this node when the scene is instantiated. They are written under the node because that is how a hand reads them; at run time they live in the pass, never on the node.
- **`props`**: a plain map of values for the game (`"props": {"team": 2}`), kept by the `SceneInstance` by node, not on the node.

A behavior's prop value is a number, a string, a bool, a list of numbers, a color, or `"@name"` or `"@path/from/root"`: a reference to a node of this file, resolved once every node is made (Blender-style names first, then paths).

What is not in the file: cameras' viewports (the app's) and anything 2D (after this pass: the format's `kind` admits `Sprite2D` and the rest under a `Node2D` root with no change to the file's shape).

## Loading

```haxe
SceneFiles.load("levels/track.scene", file -> {
    instance = file.instantiate(stage, scene.behaviors, ready);
});
```

- `SceneFiles` is the static over `SceneFileCache`, as `Models` over `ModelCache`: `load(path, loaded, ?failed):IRequest`, `find`, `isLoaded`, `forget`. The cache parses once; a file's prefabs and models are loaded through their own caches as the file is instantiated, so a level's models aren't fetched twice.
- `file.instantiate(stage, behaviors, ?ready)` applies the `stage` section, makes the tree at once from what the file says under the stage's root (every node, with placeholders where a `file` or `scene` is still loading) and returns a `SceneInstance`; `ready` is called once every model, environment and prefab has landed and the behaviors have started. A prefab is instantiated under a node by the same code with no stage. A game that wants the level whole before play waits for `ready`; one that streams draws what has landed.
- `SceneInstance`: `root:Node3D`, `node(path):Null<Node3D>`, `props(node):Null<Map<String, Dynamic>>`, `behaviors:Array<Behavior>` (the ones it attached), `ready:Bool`, `destroy()` (removes its nodes from their parent and its behaviors from the pass).
- A missing model or prefab is logged through `Failure` with the scene's path and the node's, the node left as an empty group, the rest instantiated: a level with one bad prop is still a level.

## Saving

`SceneFile.capture(instance):SceneFile` and `file.write():Bytes`. Capture walks the instance, not the live tree blindly: nodes that came from a `file` or a `scene` are written as the reference plus the overrides that differ from what the file gave (the instance remembers each node's origin and the values as made), so a round trip of an untouched level is byte identical and a hand edit stays an override. This answers the earlier framework's dump that lost flags.

Under test (`tests/`): parse, write, parse, write equal bytes for a sample with every kind, a file node, a prefab, an override, a behavior with each prop type and a reference; capture of an untouched instance equals the file.

## Behaviors

```haxe
class Checkpoint extends Behavior {
    @:prop public var index = 0;
    @:prop public var radius = 4.;

    override function start() {}
    override function update(dt:Float) {
        if (nearCar()) { Race.passed(index); done = true; }
    }
    override function stop() {}
}
```

- **`Behavior`**: `node:Node3D` (the node it drives, set before `start`), `enabled`, `done` (true ends it: `stop` is called and the pass drops it), `start()`, `update(dt)`, `stop()`. Nothing else: no signals, no children, no lookups through the node. A behavior reaches the game as any code does: statics, the scene, what it was given.
- **`Behaviors`** (the pass): `add(behavior, node)`, `remove(behavior)`, `update(dt)` (starts the new, updates the enabled whose node is enabled, stops and drops the done), `count`, `find(cls)`, `of(node)`. One pass per `Scene`: `Scene.behaviors`, updated by `Scenes.update` before the scene's own `update`, cleared on `exit`. An app without `Scenes` makes one and updates it, as it does `Tweens`.
- **`@:prop`**: a `public var` with an initializer, of `Int`, `Float`, `Bool`, `String`, `Array<Float>`, a color (`Int` marked `@:prop("color")`), or `Node3D` (a reference, `"@name"` in the file). The macro reads the initializer as the default and `@:range(min, max)` where present.
- **The registry**: `Behavior` carries `@:autoBuild(helix.macro.Behaviors.build())`, which runs on each subclass, generates its `schema()` (name, props with type, default and range, for the loader and an inspector) and `make()`, and records the class by its name (or `@:behavior("Name")`) in `BehaviorRegistry`. A file naming a behavior no class registers is logged, the node left without it. The whole program's behaviors are known at compile time; nothing is found by reflection at run time.
- **Hot reload**: a behavior's methods are re-pointed in the browser as any class's are; its instances keep their fields. Natively an old instance runs its old module until the pass is remade (a scene re-entered), as decision 130 said of closures.
- **The game model, settled**: a node draws, a behavior acts on a node, the pass runs the behaviors, the game's state is the truth (rule 5). Whether an ECS follows is for after (ROADMAP's deferred `ecs-scene`).

## Schemas for an inspector

`SceneSchema.kinds:Array<KindSchema>` (each kind's properties with type, default, range, from the same table the reader and writer use) and `BehaviorRegistry.schemas` (from the macro). Exposed, tested (every kind's table reads and writes every property), used by nothing in the framework yet: the editor is a separate package over the JS build, after this milestone.

## Blender

`tools/gltf2scene.py <export.glb> <out.scene>`: a Blender glTF export becomes one `Model` node with `file` pointing at the glb, and its objects' custom properties become overrides by node path: `helix_behavior = "Checkpoint"` with `helix_index = 0` makes a behavior with props; `helix_shadowCasting = false` a property; the export's lights and cameras need nothing from the tool, the glTF reader instantiates them with the model. A `.blend` under `examples/<name>/blender/` with its export checked in, so the conversion is reproducible.

## The example

A new example, `scene-file`: a track-like floor with gates, cones, a sun with shadows, a sky, a chase camera and a driven box, every piece from `scenes/track.scene` and the behaviors above, with an autopilot checking the box passes the gates alike on both targets. `scene3d` keeps proving the stage in code.

## Order of work

1. `SceneFile` parse and write, the kinds' tables, the unit tests for the round trip (browser loop and interp tests only).
2. `Behavior`, `Behaviors`, the macro and registry, `Scene.behaviors`; the motion or scenes example gains one behavior to prove the pass.
3. `instantiate` with models, prefabs, overrides, references; `SceneInstance`; `capture`.
4. The example and its autopilot; `gltf2scene.py` with a Blender export checked in.
5. Docs: CONVENTIONS (a behavior's shape), ARCHITECTURE (the file and the pass), DECISIONS (the game model settled), the API reference; checkpoint on both targets.

Phases 1 to 3 are supervised agents from this plan, as the API rework was; 4 and 5 by hand with the user at the desk for the Blender part.
