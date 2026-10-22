# The scene file

The `.scene` file is HeliX's own: JSON, one tree, read by `helix.scene.SceneFile` and instantiated onto a `Stage3D` with a `Behaviors` pass ([ARCHITECTURE.md](ARCHITECTURE.md), "The scene file"; why it is shaped so: [DECISIONS.md](DECISIONS.md) 132). This page is the format. The `scene-file` example is a racer slice written entirely in one, and `tools/gltf2scene.py` writes one from a Blender export.

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
      "kind": "Model",
      "name": "ground",
      "mesh": {"shape": "plane", "width": 400, "length": 400},
      "material": {"baseColor": "#9bbf7c", "roughness": 1}
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
      "projection": "perspective",
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
- **the flags**: `enabled`, `visible`, `pickable`, absent when the kind's own default (true, but a `Text3D` starts unpickable); an override's written whenever said.
- **the kind's properties**, flat beside the above, named as the class names them (`intensity`, `shadowCasting`, `projection` and `fovY`, `range`, `tint`, `text`): one table per kind lists them with their type and default, and both the reader and the writer go through that table, so nothing can be written that can't be read. Colors are `"#RRGGBB"` or `"#RRGGBBAA"`, the CSS order (in memory a color is `0xAARRGGBB`).
- **`file`** on a `Model`: a glTF, loaded through `Models` and instantiated under this node, which becomes the file's root (its parts, skin and name). Its materials are the file's.
- **`mesh`** on a `Model`, in place of `file`: a mesh made by one of `Mesh`'s generators as the model's one part, `{"shape": "plane", "width": 400, "length": 400}`. `shape` is `plane`, `cube`, `sphere`, `cylinder`, `cone`, `capsule` or `torus`, and its numbers are the generator's own arguments by name, in its order: `width`, `length`, `subdivisions` (plane); `width`, `height`, `length` (cube); `radius`, `rings`, `segments` (sphere); `radius`, `height`, `segments` (cylinder, cone); `radius`, `height`, `rings`, `segments` (capsule); `radius`, `thickness`, `rings`, `segments` (torus). An optional one is absent when the generator's default; an unknown shape or key, a missing required number or one that isn't a number is refused. A `Model` has a `file` or a `mesh`, never both, or neither (a model of no parts until code gives it one). Its material is the inline `material`, else a default one. A `Model` made in code with a generated mesh is captured as a `mesh` entry too: the mesh keeps a record of what made it (`Mesh.shape`).
- **`material`** on a `Model`: an inline material (`baseColor`, `metallic`, `roughness`, `texture`, `normalTexture`, `emissive`, `doubleSided`), replacing the mesh's or the file's root material.
- **`scene`**: another file instantiated here as a prefab. A prefab file is an ordinary `.scene`; a file naming itself, directly or through another, is refused.
- **`overrides`**: by path from this node (`road/line`), for nodes a `file` or `scene` made. Each is an entry without `name` or `kind`: properties and transform keys change the node, `children` adds new nodes under it, `behaviors` attach to it. No block is needed for a parent on the path (the first lesson above).
- **`children`**: nodes under this one.
- **`behaviors`**: a list of `{"kind": "...", "props": {...}}` attached to this node when the scene is instantiated. They are written under the node because that is how a hand reads them; at run time they live in the pass, never on the node.
- **`props`**: a plain map of values for the game (`"props": {"team": 2}`), kept by the `SceneInstance` by node, not on the node.

A behavior's prop value is a number, a string, a bool, a list of numbers, a color, or `"@name"` or `"@path/from/root"`: a reference to a node of this instance, resolved once every node is made, by name first (a prefab's subtree before the whole instance) then as a path from the root. A prefab's own file can reference only its own nodes: a behavior that needs a node of the enclosing file is written in that file, on the prefab's node, as the example's car is.

What is not in the file: cameras' viewports (the app's) and anything 2D (after this pass: the format's `kind` admits `Sprite2D` and the rest under a `Node2D` root with no change to the file's shape).

## Loading, saving, converting

```haxe
SceneFiles.load("scenes/track.scene", file -> {
    instance = file.instantiate(stage, scene.behaviors, () -> trace("ready"));
});
```

`SceneFiles` parses a file once and shares it by path. `instantiate` applies the stage section, makes every node at once under a group named after the file on the stage's root, loads the models, prefabs and environment it names through their caches, attaches the behaviors to the pass once every load has landed (their references resolved then), and calls `ready` at the pass's next update. The `SceneInstance` gives `node(path)`, `pathOf(node)`, `props(node)`, its `behaviors`, `ready`, and `destroy()`. A missing model, prefab or environment is logged with the file's path and the node's, and the rest is made.

`SceneFile.capture(instance)` writes the file that would instantiate to what the instance is now: a file or prefab node as its reference plus what differs from what the file gave, a reference as `@name` when the name is unique, and nothing at its default (the stage's, a kind's, a behavior's prop), so a canonical file comes back byte for byte and a hand-written default vanishes.

`python3 tools/gltf2scene.py export.glb out.scene` makes a file from a Blender glTF export: one `Model` node with the glb as its `file`, and the objects' custom properties as overrides by node path: `helix_behavior` with its `helix_<prop>` props, `helix_enabled`, `helix_visible` and `helix_pickable` the node's flags, any other `helix_<name>` the kind's property, `helix_props_<name>` the node's props. Lights and cameras come with the model: the glTF reader instantiates them.

## Behaviors

```haxe
@:phase(Resolve)
class Checkpoint extends Behavior {
    @:prop public var index = 0;
    @:prop public var radius = 10.;
    @:prop public var race:Node3D = null;

    override function update(dt:Float) {
        var found = pass.on(race, Race);
        if (found != null && near(found.car)) found.reach(index);
    }
}
```

- **`Behavior`**: `node:Node3D` (the node it drives, set before `start`), `pass` (the pass it's in), `enabled`, `done` (true ends it: `stop` is called and the pass drops it), `phase`, `start()`, `update(dt)`, `stop()`. Nothing else: no signals, no children, no lookups through the node. A behavior reaches the game as any code does: statics, the scene, what it was given, and another behavior through a node it was given (`pass.on(race, Race)`).
- **`@:phase`** on the class says when in a frame it runs: `Input` (reading devices, deciding intent), `Simulate` (moving the world; without `@:phase`), `Resolve` (settling what Simulate produced: the checkpoint above, combat applying queued hits) or `Late` (following the settled world: the chase camera). The pass runs every behavior of one phase before the next, each phase's in the file's order; a subclass keeps its base's phase (decision 134).
- **`Behaviors`** (the pass): `add(behavior, node)`, `remove(behavior)`, `update(dt)` (starts the new, updates the enabled whose node is enabled phase by phase, stops and drops the done), `count`, `find(cls)`, `findAll(cls)`, `on(node, cls)`, `of(node)`, and `allUnder(node, cls)`: the behaviors of a class or interface on node and under it, how a resolver gathers what has a say on an entity. One pass per `Scene`: `Scene.behaviors`, updated by `Scenes.update` before the scene's own `update`, cleared on `exit`. An app without `Scenes` makes one and updates it, as it does `Tweens`.
- **`@:prop`**: a `public var` with an initializer, of `Int`, `Float`, `Bool`, `String`, `Array<Float>`, a color (`Int` marked `@:prop("color")`), or `Node3D` (a reference, `"@name"` in the file). The macro reads the initializer as the default and `@:range(min, max)` where present.
- **The registry**: `Behavior` carries `@:autoBuild(helix.macro.Behaviors.build())`, which runs on each subclass, generates its `schema()` (name, phase, props with type, default and range, for the loader and an inspector) and `make()`, and records the class by its name (or `@:behavior("Name")`) in `BehaviorRegistry`. A file naming a behavior no class registers is logged, the node left without it. The whole program's behaviors are known at compile time; nothing is found by reflection at run time.
- **Hot reload**: a behavior's methods are re-pointed in the browser as any class's are; its instances keep their fields. Natively an old instance runs its old module until the pass is remade (a scene re-entered), as decision 130 said of closures.
- **The game model, settled**: a node draws, a behavior acts on a node, the pass runs the behaviors, the game's state is the truth (rule 5). Whether an ECS follows is for after (ROADMAP's deferred `ecs-scene`).
