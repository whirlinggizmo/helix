# helix.platform.tools

[Back to the index](README.md)

## ShaderCompileOptions

*typedef* in [`platform/src/helix/platform/tools/ShaderCompileOptions.hx`](../../platform/src/helix/platform/tools/ShaderCompileOptions.hx), `import helix.platform.tools.ShaderCompileOptions;`

Represents how `ShaderCompiler.compileText` compiles: the dialects it makes besides GLSL ES 300 (WebGL2), which every `ShaderSource` carries, where includes are looked for, the names defined, whether loose uniforms are taken, and how the vertex stage is wrapped.

- `sdlGpu:Bool`: Whether to make SDL_GPU's stages: SPIR-V, MSL and HLSL.
- `points:Null<Bool>`: Whether to wrap the vertex stage so it writes a point size of 1, `gl_PointSize = 1.0` after its own `main`, for `Primitive.Points` pipelines. Optional; false by default.
- `looseUniforms:Null<Bool>`: Whether a stage may declare uniforms outside a block (`uniform vec3 diffuse;`), in either form of source. Optional; false by default.
- `includeDirectories:Null<Array<String>>`: Directories `#include` looks in, after the directory of each stage's file. Optional; none by default.
- `glsl410:Bool`: Whether to make GLSL 410, for GL natively.
- `gatheredBlocks:Null<Array<{uniforms:Array<String>, name:String}>>`: Loose uniforms gathered by name into blocks of their own, which both stages read, each laid out in the order its names are given, placed after `helix_uniforms`. Optional; none by default. A name neither stage declares is refused.
- `defines:Null<Array<String>>`: Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`, as glslang's `-D` takes them. Optional; none by default.
- `clipScale:Null<Bool>`: Whether to wrap the vertex stage with a clip scale it multiplies `gl_Position` by, a loose `vec4 helix_clipScale`, for `ClipFlip.ClipScale`. Optional; false by default.

## ShaderCompiler

*class* in [`platform/src/helix/platform/tools/ShaderCompiler.hx`](../../platform/src/helix/platform/tools/ShaderCompiler.hx), `import helix.platform.tools.ShaderCompiler;`

Provides compiling a program's GLSL into a `ShaderSource` for every graphics adapter: a vertex stage and a fragment stage, compiled once to SPIR-V by glslang and translated by SPIRV-Cross (`ShaderTools`), and reflected.

**Two forms of source**, told apart by the `#version` line: `#version 450`, Vulkan-style, where attributes may give `layout(location = n)` and blocks and textures `layout(binding = n)`; and `#version 300 es`, or 330 to 440, as WebGL2 and GL write it, where nothing gives a location or a binding (one written is refused, as GLSL ES 3.0 has none) and the compiler places everything. Both stages are one form. `#include` needs no extension line: the compiler enables `GL_GOOGLE_include_directive` for every stage, and a stage declaring it is still taken.

What a program's source declares is what it binds: each uniform block, at its size rounded up to whole `vec4`s, and each texture, a combined sampler, whether the code reads it or not (`ShaderMember.active` and `ShaderTexture.active` say whether it does). Blocks and textures are numbered apart: every adapter binds blocks 0 to 3 in each stage and textures 0 to 11, and a binding past them is refused. A block both stages declare alike (the same name, binding and members) is one block at one slot, read by both (`ShaderBlock.stage` "both"); two declarations of one name that differ are refused. A block holds `float`, `vecN`, `matN`, `int`, `ivecN`, `uint`, `uvecN`, `bool` and `bvecN` members together, structs, and arrays of any of them, laid out by std140; a field of an array of structs is reflected as one member whose elements are the array's (`lights.color`). An array inside an array of structs, an array of arrays, a `double` and a sampler array are refused. A texture's kind comes from its type (`sampler2D`, `sampler2DArray`, `samplerCube`, `sampler2DArrayShadow`); one only read with `texelFetch` is never filtered. The vertex attributes are the vertex stage's inputs, at locations from 0 without gaps, a matrix a location a column; the values passed between the stages may leave their locations out, matched by name. The vertex stage writes GL's clip space.

**Loose uniforms** (`ShaderCompileOptions.looseUniforms`): uniforms outside a block, in either form, both stages' gathered into one block, `helix_uniforms`, read by both: the vertex stage's in declared order, then the fragment stage's not already there. A uniform both declare is one member; with two types it is refused, and so is an initializer, which the compiler would drop. Loose uniforms named in `ShaderCompileOptions.gatheredBlocks` go into their own blocks, read by both. Gathering is a strict text step over glslang's preprocessed output (`-E`): each global `uniform` declaration is one statement there and is moved whole, and glslang then compiles and validates the result, so a rewrite gone wrong fails the build.

**Placement**, where a source gives none: named blocks at the lowest free block bindings of their stages in the order declared (the vertex stage's first), then `helix_uniforms`, then the gathered blocks, each at the lowest binding free in both stages; textures at the lowest free texture bindings in the order declared; attributes at the lowest free locations in the order declared, a matrix a location a column.

With `ShaderCompileOptions.clipScale` the compiler wraps the vertex stage: `#define main helix_main` before the stage's text, a loose `uniform vec4 helix_clipScale;`, and after it `void main() { helix_main(); gl_Position *= helix_clipScale; }`, so any vertex stage can be flipped through `ClipFlip.ClipScale`. With `ShaderCompileOptions.points` the same wrap writes `gl_PointSize = 1.0` after the stage's `main`, whatever it wrote, for `Primitive.Points` pipelines, and the result's `ShaderSource.points` is true.

```haxe
var shader = graphics.createShader(ShaderCompiler.compile("triangle.vert", "triangle.frag"));
```

```haxe
static macro function compile(vertex:String, fragment:String, ?options:ShaderCompileOptions):ShaderSource
static function compileText(vertex:{text:String, name:String}, fragment:{text:String, name:String}, options:ShaderCompileOptions):ShaderSource
```

- `compile`: Compiles a program while the build runs, and returns its `ShaderSource` as a value in the program.
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Include directories, defines, loose uniforms, gathered blocks, the clip-scale wrap and the point size, as `ShaderCompileOptions` has them; none by default.
  - returns: The program, as `IGraphics.createShader` takes it.

  A browser build carries GLSL ES 300 alone; a native build GLSL 410 and SDL_GPU's dialects besides. An error stops the build at the call, saying where in the shader it is.

  The options are an object literal at the call, read as the program builds: any of `ShaderCompileOptions` but the dialects, which are the build's. Include directories are relative to the file holding the call. A field `ShaderCompileOptions` doesn't have, a dialect, or a value that isn't a constant is refused.

  ```haxe
  var dots = graphics.createShader(ShaderCompiler.compile("dots.vert", "dots.frag", {points: true}));
  ```
- `compileText`: Compiles a program's two stages from their text, in the compiler or a tool.
  - `vertex`: The vertex stage: a name for messages (its file's path, when it has one) and its GLSL.
  - `fragment`: The fragment stage: a name for messages and its GLSL.
  - `options`: The dialects to make, the include directories, the defines, and whether loose uniforms are taken.
  - returns: The program, with its reflection.
  - throws `CommandException`: A stage doesn't compile (glslang's errors, named for the stage), or the program breaks a rule above.

  A macro calls it to compile text it has made or read (a library rewriting another dialect, a library adding defines), and puts the result in the program with `Context.makeExpr`.

  A quoted `#include` resolves beside the stage's file (its name, when that's a path), then in the include directories; the include extension is enabled for every stage. It runs where the system is reachable, in the compiler or a tool; in a program it throws.
