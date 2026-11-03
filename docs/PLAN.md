# The plan

helix-2.0 is several haxelibs in one repository, built from the bottom up: the libraries, which know no consumer, and the engines over
them, which may own the loop and keep statics.

## Layers

```
libs/                the libraries
  math/              points, bounds, transforms, curves, deterministic trig   depends on nothing
  geometry/          cameras, rays, meshes, tests on shapes                   depends on math
  log/               levels and tags, to the console or stdio                 depends on nothing
  formats/           file formats read into plain data: glTF, BMFont, fonts   depends on math
  platform/          the hardware and the OS as contracts and adapters        depends on math, formats
  services/          what a program needs over the platform that isn't drawing
  render/            drawing: 2D and 3D batches, materials, lights, post-processing, over the services (DECISIONS 35)
  ...                later scene and UI
engines/             the engines, each an API a program is written in
  raylib/            helix-raylib: raylib's API over the services (DECISIONS 16)
  ...                later Gyre, what HeliX's engine becomes, and a three.js-style one
```

A library imports only the libraries below it that it's built on, and no library reaches an engine (`tools/check_layers.py`); an
engine's tests run on every change to the libraries (`helix.py test`), so a library's change that breaks an engine is seen in the same
commit. A library is split out only where someone could use it without what it sits on: assets, input, audio and time need each other,
so they're one library, services, with a package each. Each becomes a repository of its own, an engine pinning a library's version,
once the platform has held through a second consumer and is versioned.

## A library

- A haxelib with a README beside its `haxelib.json`: what it is, what it depends on and how to add it to a build.
- Self-sufficient: its tests, examples and size ladder (`libs/<library>/tests/sizes/`) build with it and the libraries below, its C
  vendored in it. Its examples build from hxml files beside them with Haxe alone, each showing one thing.
- Platform and services: a program constructs what it uses from them, and calls each thing's `poll` from its own loop. They run no
  loop.
- The layers above: they may own the loop, and build a feature when its API is first touched where the API they match requires it. A
  game on them carries what it uses (DECISIONS 15).

## platform versus services

**platform** is the hardware and the OS: one contract per device, one adapter per API, no policy (no queues, caches, buses, frame order
or idea of an asset). **services** is the policy a program needs over it that another engine on the same platform would take as it is:
assets (manifests, cache modes, bringing a file in when it's missing or stale), saves, audio buses and fades, input state and actions,
a game clock and timers, config. If it must exist for anything to draw or be heard at all, it's platform. If it's a policy, it's
services. If it's how one program runs (its loop, its order), it's that program's.

## The method

1. **The API,** its types and members with their doc comments and no implementation, agreed with the user; its doc comments are the
   spec, and a trial on its reference comes before any code.
2. **The library,** with its README, tests, examples and ladder from the first commit.
3. **A trial:** a fresh agent on the libraries alone writes a small program; what it guessed wrong is what changes.
