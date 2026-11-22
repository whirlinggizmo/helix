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
