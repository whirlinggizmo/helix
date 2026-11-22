# helix-jolt

[Jolt Physics](https://github.com/jrouwe/JoltPhysics) 5.6 for Haxe, with the API of [JoltPhysics.js](https://github.com/jrouwe/JoltPhysics.js),
Jolt's own JavaScript binding: the same classes, members and constants, in Jolt's C++ names. Natively Jolt is compiled into the
program by hxcpp; in a page it runs as a WebAssembly module (`jolt.wasm`) the library ships, so neither needs a C++ toolchain beyond
hxcpp's.

It depends on helix-math: `Vec3`, `Quat` and `Mat44` wrap helix-math's `Vector3`, `Quaternion` and `Matrix4`, and pass as them without
a copy, so a body's transform goes straight to helix-raylib's `DrawMeshInstanced`.

```hxml
-lib helix-jolt
--macro helix.jolt.Jolt.copyWasm("web")
```

```haxe
import helix.jolt.*;
import helix.jolt.Jolt.*; // Jolt's constants, such as EMotionType_Dynamic
```

It holds rigid bodies, the layers, the common shapes, ray, point, shape and swept-shape queries, contact events and the common
constraints. `Jolt`'s doc says how the module loads and what is freed how, and each extra's doc names it as one.

The module is single precision, single threaded and cross-platform deterministic: the same steps from the same state produce the same
bits natively and in a page.

## Building it

`python3 tools/gen_jolt.py` in the checkout vendors Jolt from the pinned release, writes hxcpp's list of its sources
(`vendor/jolt/files.xml`), and builds `wasm/jolt.wasm` with Emscripten. A program's native build compiles Jolt with it, so a program
needs nothing but hxcpp. Its tests run the same scene in Node and natively, and compare the two: `python3 helix.py test --native`.

## Third-party code

- [Jolt Physics](https://github.com/jrouwe/JoltPhysics) 5.6.0, by Jorrit Rouwe: `vendor/jolt/Jolt`, unchanged, and in `wasm/jolt.wasm`.
  MIT, `vendor/jolt/LICENSE`.
