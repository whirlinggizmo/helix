# helix-box2d

[Box2D](https://box2d.org) 3.2 for Haxe, under Box2D's own C names: `b2CreateWorld`, `b2DefaultBodyDef`, `b2Body_GetPosition`, the
ids, the defs and the constants, as Box2D's manual and samples write them. Natively Box2D is compiled into the program by hxcpp; in a
page it runs as a WebAssembly module (`box2d.wasm`) the library ships.

_The API is drafted and not yet built: each function throws "not built yet"._

It depends on helix-math: `B2Vec2` wraps helix-math's `Vector2`, and passes as one without a copy.

```hxml
-lib helix-box2d
--macro helix.box2d.Box2D.copyWasm("web")
```

```haxe
import helix.box2d.*;
import helix.box2d.Box2D.*; // Box2D's functions and constants
```

Box2D's types take a capital first letter in Haxe (`b2BodyDef` is `B2BodyDef`), as Haxe requires. A struct Box2D passes by value is a
Haxe object, and a function returning one accepts an optional `out`. `Box2D`'s doc says how the module loads.

It holds worlds, bodies, every shape and chain, every joint but the experimental ones, queries, contact, sensor, body and joint events,
snapshots and the state hash. It leaves out what Box2D 3.2 calls experimental (the mover and pogo joints, the character mover,
recording and replay) and the dynamic tree.

## Third-party code

- [Box2D](https://github.com/erincatto/box2d) 3.2.0, by Erin Catto. MIT.
