# helix.platform.tools

[Back to the index](README.md)

## ShaderCompiler

*class* in [`platform/src/helix/platform/tools/ShaderCompiler.hx`](../../platform/src/helix/platform/tools/ShaderCompiler.hx), `import helix.platform.tools.ShaderCompiler;`

Provides compiling a program's GLSL into a `ShaderSource` for every graphics adapter: standard Vulkan-style GLSL 450, a vertex stage and a fragment stage, compiled once to SPIR-V by glslang and translated by SPIRV-Cross (`ShaderTools`), which also reflects it.

What a program's source declares is what it binds: each uniform block at `layout(binding = n)`, at its declared size rounded up to whole `vec4`s, and each texture, a combined sampler at `layout(binding = n)`, whether the code reads it or not; blocks and textures are numbered apart. A texture's kind comes from its type (`sampler2D`, `sampler2DArray`, `samplerCube`, `sampler2DArrayShadow` for a shadow map); one the program only reads with `texelFetch` is never filtered (`ShaderTexture.data`). Every adapter binds uniform blocks 0 to 3 and textures 0 to 11; a binding past them is refused. The vertex attributes are the vertex stage's inputs, at `layout(location = n)` from 0 without gaps; the values passed between the stages may leave their locations out. The vertex stage writes GL's clip space, depth -1 to 1, as every adapter takes it.

For GL each block becomes one `vec4` array named for the block, so a block's members must be all floating point (`float`, `vecN`, `matN`) or all integer (`int`, `ivecN`), and an array member a `vec4`, `ivec4` or `mat4` array.

```haxe
var shader = graphics.createShader(ShaderCompiler.compile("triangle.vert", "triangle.frag"));
```

```haxe
static macro function compile(vertex:String, fragment:String):ShaderSource
```

- `compile`: Compiles a program while the build runs, and returns its `ShaderSource` as a value in the program.
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - returns: The program, as `IGraphics.createShader` takes it.

  A browser build carries GLSL ES 300 alone; a native build GLSL 410 and SDL_GPU's dialects besides. An error stops the build at the call, saying where in the shader it is.
