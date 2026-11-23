# helix-box2d

[Box2D](https://box2d.org) 3.2 for Haxe, under Box2D's own C names: `b2CreateWorld`, `b2DefaultBodyDef`, `b2Body_GetPosition`, the
ids, the defs and the constants, as Box2D's manual and samples write them. Natively Box2D is compiled into the program by hxcpp; in a
page it runs as a WebAssembly module (`box2d.wasm`) the library ships.

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

It holds worlds, bodies, every shape and chain, every joint but the experimental ones, queries, the character mover, contact, sensor,
body and joint events, snapshots and the state hash. It leaves out what Box2D 3.2 calls experimental (the mover and pogo joints,
recording and replay) and the dynamic tree.

The module is single precision and cross-platform deterministic: the same steps from the same state produce the same bits natively and
in a page, and natively the same on Box2D's own threads as on one. In a page it runs one.

## Building it

`python3 tools/gen_box2d.py` in the checkout vendors Box2D from the pinned release, writes hxcpp's list of its sources
(`vendor/box2d/files.xml`) and the calls between Haxe and Box2D from Box2D's own description of its API (`api/box2d_api.json`), and
builds `wasm/box2d.wasm` with Emscripten. A program's native build compiles Box2D with it, so a program needs nothing but hxcpp. Its
tests run the same scene in Node and natively, and compare the two: `python3 helix.py test --native`.

## Third-party code

- [Box2D](https://github.com/erincatto/box2d) 3.2.0, by Erin Catto: `vendor/box2d`, unchanged, and in `wasm/box2d.wasm`. MIT,
  `vendor/box2d/LICENSE`.
