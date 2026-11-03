# helix.services.shaders

[Back to the index](README.md)

## IShaderHandles

*interface* in [`libs/services/src/helix/services/shaders/IShaderHandles.hx`](../../libs/services/src/helix/services/shaders/IShaderHandles.hx), `import helix.services.shaders.IShaderHandles;`

Defines finding what a shader, or any variant of a set, declares: `Shader` and `ShaderVariants` implement it, so a by-name layer works over either.

A `get` form throws for a name nothing declares, listing what is declared and, for a path written with brackets, the spelling it takes; a `find` form returns null. On a set, a name is found when any variant declares it.

```haxe
var uniforms(get, never):Array<ShaderUniform>
var samplers(get, never):Array<ShaderSampler>
function hasUniform(name:String):Bool
function hasSampler(name:String):Bool
function getUniform(name:String):ShaderUniform
function findUniform(name:String):Null<ShaderUniform>
function getUniformPath(path:String):ShaderUniformPath
function findUniformPath(path:String):Null<ShaderUniformPath>
function getSampler(name:String):ShaderSampler
function findSampler(name:String):Null<ShaderSampler>
function hasSharedBlock(blockName:String):Bool
function reserveUniform(name:String):ShaderUniform
function reserveUniformPath(path:String):ShaderUniformPath
function reserveSampler(name:String):ShaderSampler
function getAttribute(name:String):ShaderAttribute
function findAttribute(name:String):Null<ShaderAttribute>
```

- `uniforms`: Gets every uniform's handle: each block member, struct field and field of an array of structs, in block order. On a set, every variant's, each name once.
- `samplers`: Gets every sampled texture's handle, in slot order; on a set, every variant's, each name once.
- `hasUniform`: Returns whether a uniform is declared.
  - `name`: Its path, or the name `Shader.withNames` gave it.
  - returns: True when it is declared (on a set, by any variant).
- `hasSampler`: Returns whether a texture is sampled.
  - `name`: Its GLSL name, or the name `Shader.withNames` gave it.
  - returns: True when it is declared (on a set, by any variant).
- `getUniform`: Returns the handle of a uniform.
  - `name`: Its path (`roughness`, `material.roughness`, `lights.color`), or the name `Shader.withNames` gave it.
  - returns: The handle, the same each call.
  - throws `String`: A name nothing declares; given `lights[0].position`, it names `lights.position` and `getUniformPath`.
- `findUniform`: Finds the handle of a uniform that may not be declared.
  - `name`: Its path, or the name `Shader.withNames` gave it.
  - returns: The handle, the same each call, or null.
- `getUniformPath`: Returns a uniform and element from a path as GLSL writes it, with brackets (`pointLights[1].color`, `bones[3]`), or without.
  - `path`: The path.
  - returns: The uniform and the element, the same object for the same path.
  - throws `String`: A path whose uniform nothing declares, or an index past its elements.
- `findUniformPath`: Finds a uniform and element from a path that may not be declared.
  - `path`: The path.
  - returns: The uniform and the element, or null: for a uniform nothing declares, an index past its elements, a path naming a struct or a struct's element rather than a field (`lights[1]`, `lights`).
- `getSampler`: Returns the handle of a sampled texture.
  - `name`: Its GLSL name, or the name `Shader.withNames` gave it.
  - returns: The handle, the same each call.
  - throws `String`: A name nothing declares.
- `findSampler`: Finds the handle of a sampled texture that may not be declared.
  - `name`: Its GLSL name, or the name `Shader.withNames` gave it.
  - returns: The handle, or null.
- `hasSharedBlock`: Returns whether a shared block is named (`ShaderOptions.shared`).
  - `blockName`: The block's name.
  - returns: True when it is (on a set, by any variant).
- `reserveUniform`: Returns a handle for a uniform that may be declared only after a replacement, binding when it is (`Shader.reserveUniform`).
  - `name`: Its path.
  - returns: The handle, the same each call.
- `reserveUniformPath`: Returns a uniform and element for a bracketed path that may be declared only after a replacement.
  - `path`: The path.
  - returns: The uniform and the element.
- `reserveSampler`: Returns a handle for a texture that may be sampled only after a replacement, binding when it is.
  - `name`: Its GLSL name.
  - returns: The handle, the same each call.
- `getAttribute`: Returns a vertex attribute (on a set, the first variant's that reads it).
  - `name`: Its GLSL name, or the name `Shader.withNames` gave it.
  - returns: The attribute.
  - throws `String`: A name nothing declares.
- `findAttribute`: Finds a vertex attribute that may not be read.
  - `name`: Its GLSL name.
  - returns: The attribute, or null.

## IShaderValues

*interface* in [`libs/services/src/helix/services/shaders/IShaderValues.hx`](../../libs/services/src/helix/services/shaders/IShaderValues.hx), `import helix.services.shaders.IShaderValues;`

Defines what values for a whole program take besides uniforms: textures, and the blocks and textures they share. `ShaderValues` and `ShaderVariantValues` implement it.

Sharing on a values made over a base (`ShaderValues.base`) is its own; what it doesn't share itself it reads from its base, so sharing once on a scene's defaults shares on every values made over them, before or after.

```haxe
var scene(get, set):Null<ShaderScene>
function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void
function writeSamplerValue(sampler:ShaderSampler, value:ShaderValue):Void
function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void
function unshareTexture(sampler:ShaderSampler):Void
function shareBlock(block:ShaderBlockValues):Void
function unshareBlock(blockName:String):Void
function findSharedBlock(blockName:String):Null<ShaderBlockValues>
```

- `scene`: Gets or sets the scene the values read shared blocks and textures from when neither they nor their base share them, or null for their base's. Changing it copies nothing (`ShaderScene`).
- `writeTexture`: Writes the texture a sampler reads, and how.
  - `sampler`: The sampler.
  - `texture`: The texture, as an `IGraphics` handle of the sampler's kind, or 0 for none.
  - `sampling`: Optional. How it is sampled; defaults to `Sampling.LINEAR`.

  The handle is trusted: it is passed to `IGraphics.draw` as it is, so a layer above that hands out textures checks they are alive. A shadow map or a data texture is sampled as its kind requires, whatever the sampling.
- `writeSamplerValue`: Writes a sampler from a value held as data, as a by-name layer's table holds a texture beside its uniforms.
  - `sampler`: The sampler.
  - `value`: A `ShaderValue.Texture`.
  - throws `String`: A value of another case.
- `shareTexture`: Makes a sampler read a shared texture, until `unshareTexture`, in place of a texture written.
  - `sampler`: The sampler.
  - `shared`: The shared texture.
- `unshareTexture`: Stops a sampler reading a shared texture.
  - `sampler`: The sampler.
- `shareBlock`: Makes the shader's block of a shared block's name read the shared block's bytes, until `unshareBlock`. A block of that name already shared is replaced, as a shadow pass's values swap the camera's block for the light's.
  - `block`: The shared block.
  - throws `String`: A shader (none of a set's variants) that names no shared block of that name (`ShaderOptions.shared`).
- `unshareBlock`: Stops sharing a block of a name; what it reads is then its base's, or nothing, and a draw throws until one is shared.
  - `blockName`: The block's name.
- `findSharedBlock`: Returns the shared block a block of a name reads now: its own, or its base's.
  - `blockName`: The block's name.
  - returns: The shared block, or null when none is shared.

## Shader

*class* in [`libs/services/src/helix/services/shaders/Shader.hx`](../../libs/services/src/helix/services/shaders/Shader.hx), `import helix.services.shaders.Shader;`, implements `IShaderHandles`

Represents a compiled shader: the program `IGraphics.createShader` builds, and what it declares, found by name.

A shader is compiled while the program builds, never while it runs: `compile` from GLSL files, `compileText` from GLSL text known then, `ShaderVariants.compile` for a set of variants, `makeExpr` for a library's macro. With `ShaderOptions.file`, `Shaders.watch` replaces it in place each time its file changes, so one shader, never null, serves a release build and a development build alike. It holds no GPU resource and no values: `ShaderPrograms` builds it on the GPU, and `ShaderValues` hold what it reads, the defaults included, as values the program makes (`ShaderValues.base`).

**Stages.** Both stages are written in one of two forms, told apart by the `#version` line:

- **`#version 450`**, Vulkan-style: attributes may give `layout(location = n)`, blocks and textures `layout(binding = n)`. - **`#version 300 es`, or 330 to 440,** as WebGL2 and GL write it: nothing gives a location or a binding, as GLSL ES 3.0 can't, and the compiler places everything; a `binding` or `location` written in this form is refused. GLSL ES 100's `attribute`, `varying`, `gl_FragColor` and `texture2D` are not taken.

**Loose uniforms** (`uniform vec4 tint;`, outside a block) are taken in either form, so a variant's own uniforms, declared under its `#ifdef`, need no block of their own. Both stages' are gathered into one block, `helix_uniforms`, read by both (platform proposal 6): the vertex stage's in the order it declares them (an include's where it is included), then the fragment stage's not already there. A uniform both stages declare loose is one member; declared with two types, it is refused. A program with none has no such block. Every block is laid out by std140, whether or not it says `layout(std140)`.

**Types.** Blocks hold `float`, `vecN`, `matN`, `int`, `ivecN`, `uint`, `uvecN`, `bool` and `bvecN` members together, structs, and arrays of any of them. Each struct field is a uniform found by its path (`material.roughness`); a field of an array of structs is one uniform whose elements are the array's (`lights.color`). An array inside an array of structs, a `double`, and a sampler array (`sampler2D maps[4]`) are refused, naming them.

**Placement**, where nothing gives it. Blocks and textures are numbered apart: blocks 0 to 3 in each stage (platform proposal 10, as SDL_GPU binds four a stage; a block both stages read takes a slot in each), textures 0 to 11, as every adapter binds them; one past them is refused. Named blocks without a binding take the lowest free block bindings in the order declared, then `helix_uniforms`, then the shared blocks gathered from loose uniforms (`ShaderSharedBlock.uniforms`). Textures without a binding take the lowest free texture bindings, in the order declared. Attributes without a location take the lowest free locations in the order declared, a matrix a location a column. A block both stages declare alike is one block at one binding, read by both. Since everything is found by name, and a pipeline names the uniform it flips by its place (`ShaderPipelineState.flipUniform`, platform proposal 9), no rule of placement is the program's to keep: `findUniformPlace` says where a uniform is, and a library with a rule of its own passes a `check`.

**Includes and defines.** A quoted `#include` resolves beside the including file, then in `ShaderOptions.includeDirectories`; one in angle brackets in the texts `ShaderOptions.includes` names, then in each of the build's class paths (`#include <helix/draw/color.glsl>`). No stage declares the include extension: the compiler enables it. Defines are given to the compiler, so a line in an error is the file's; each stage also has `HELIX_VERTEX` or `HELIX_FRAGMENT`.

**Macros and the program's own types.** The service's types that hold macros import nothing with a build macro, so they type in the macro context. A program's own class holding a macro, or calling one at its class level, that also names a platform enum built by a macro (`Sampling`'s `Filter`) puts that use under `#if !macro`, or keeps the macro in a class of its own, as `ShaderValueClasses` is.

**Strict, where GL is lenient.** A write of the wrong kind throws, where GL ignores a `glUniform` of the wrong type; a layer matching GL (helix-raylib's `SetShaderValue`) checks the handle's `type` itself and skips.

**With hotreload-hx's code reload**, statics keep their values, so a `static final` holding a compiled shader keeps the old one when its text constant changes and the code reloads: an edit reaches a running page through the shader's `file` and `Shaders.watch`, not through the code reload.

A uniform's initializer in the GLSL (`uniform float roughness = 0.5;`) is refused, naming `ShaderValues.base`, as the compiler would drop it. Every declared uniform is reflected, read by the code or not (`ShaderUniform.active` says which). An error stops the build at the call, naming the file and line.

```haxe
var glow = Shader.compile("quad.vert", "glow.frag", {file: "shaders/glow.shader"});
var defaults = new ShaderValues(glow);
defaults.writeFloat(glow.getUniform("strength"), 1);
var values = new ShaderValues(glow, defaults);
values.writeColor(glow.getUniform("tint"), 0xffffc040);
values.writeTexture(glow.getSampler("image"), texture);
```

```haxe
function new(source:ShaderSource, ?filePath:String)
static macro function compile(vertex:String, fragment:String, ?options:ShaderOptions):Shader
static macro function compileText(vertex:String, fragment:String, ?options:ShaderOptions):Shader
var source(default, null):ShaderSource
var attributes(default, null):Array<ShaderAttribute>
var uniforms(get, never):Array<ShaderUniform>
var samplers(get, never):Array<ShaderSampler>
var reloadCount(default, null):Int
final reloadListeners:Array<Shader -> Void>
var reloadError(default, null):Null<String>
final filePath:Null<String>
function hasUniform(name:String):Bool
function hasSharedBlock(blockName:String):Bool
function reserveUniform(name:String):ShaderUniform
function reserveUniformPath(path:String):ShaderUniformPath
function reserveSampler(name:String):ShaderSampler
function hasSampler(name:String):Bool
function getUniform(name:String):ShaderUniform
function findUniform(name:String):Null<ShaderUniform>
function getUniformPath(path:String):ShaderUniformPath
function findUniformPath(path:String):Null<ShaderUniformPath>
function getSampler(name:String):ShaderSampler
function findSampler(name:String):Null<ShaderSampler>
function findUniformPlace(uniform:ShaderUniform):Null<{offset:Int, blockSlot:Int}>
function getAttribute(name:String):ShaderAttribute
function findAttribute(name:String):Null<ShaderAttribute>
function computeVertexBuffer(names:Array<String>, ?instanced:Bool = false):VertexBuffer
function computeUnfedAttributes(buffers:Array<VertexBuffer>):Array<ShaderAttribute>
function withNames(names:Map<String, String>):Shader
```

- `new`: Creates a shader from a compiled program, reading its reflection.
  - `source`: The program, with its blocks' members and its attributes' types.
  - `filePath`: Optional. The asset path of its file.

  The macros put a call to it in the program, and `Shaders.load` makes one for each file it loads.
- `compile`: Compiles a vertex and a fragment stage while the program builds, and returns the shader as a value in the program.
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes, shared blocks, a check, and a file: a constant object, at the call or a class's static constant (`LitShader.OPTIONS`), so options many calls share live in one place.
  - returns: The shader.

  A browser build carries GLSL ES 300 alone; a native build GLSL 410 and SDL_GPU's dialects besides. Both stages are given: a layer whose users may leave one out (raylib's `LoadShader(null, "x.fs")`) supplies its own default, through `makeExpr`.
- `compileText`: Compiles a vertex and a fragment stage from GLSL text known while the program builds, and returns the shader as a value in the program.
  - `vertex`: The vertex stage's GLSL.
  - `fragment`: The fragment stage's GLSL.
  - `options`: Optional. Defines, includes, shared blocks, a check, and a file.
  - returns: The shader.

  Each stage's text is a string literal, a static `String` constant of a class (`static inline final` or `static final` with a constant value), or such strings joined with `+`, so a class can keep its GLSL where it is used (`StandardMaterial.VERTEX`). A quoted `#include` resolves beside the file declaring the text: the call's for a literal, the constant's class's for a constant.
- `source`: Gets the compiled program in every dialect the build's adapters take, as `IGraphics.createShader` takes it, with its reflection: its blocks' members (`ShaderBlock.members`) and its attributes' types.
- `attributes`: Gets the vertex attributes, by slot: entry i is the attribute at slot i, so a matrix, which takes a slot a column from its own, is the entry at each of its columns' slots, the same record each time.
- `uniforms`: Gets every uniform's handle, in block order.
- `samplers`: Gets every sampled texture's handle, in slot order.
- `reloadCount`: Gets the number of times a change of its file has replaced it in place (`Shaders.watch`): 0 until then.
  After a replacement, `source` and the reflection are the new file's, and every handle and values made for it follows on its own. What was built on the GPU from it is its holder's to build again (`ShaderPrograms` does). A shader `withNames` made from it is replaced with it. A replacement happens at `Shaders.prepareFrame`, never mid-frame. Code that acts on one adds a `reloadListeners` function rather than watching this count.
- `reloadListeners`: Gets the functions called after each replacement in place, once the reflection, every handle and every values made for it have followed, in the order added: a program adds and removes its own (`reloadListeners.push(f)`, `reloadListeners.remove(f)`). Each receives the shader. A rejected replacement (`reloadError`) calls none.
- `reloadError`: Gets why the last replacement wasn't taken, or null when it was: a file that doesn't read or holds another kind of shader or other features (`Shaders`), or a replaced program the GPU refused (`ShaderPrograms`). The shader, and what was built from it, stay as they were, and this says so where a holder can see it as well as in the log.
- `filePath`: Gets the asset path of its file (`ShaderOptions.file`), which `Shaders.watch` watches, or null when it was compiled without one. It is set whatever the build, whether or not the build wrote the file.
- `hasUniform`: Returns whether the shader declares a uniform.
  - `name`: Its path, or the name `withNames` gave it.
  - returns: True when it is declared.
- `hasSharedBlock`: Returns whether the shader names a shared block (`ShaderOptions.shared`).
  - `blockName`: The block's name.
  - returns: True when it does.
- `reserveUniform`: Returns a handle for a uniform the shader may declare now or only after a replacement, for code written ahead of the GLSL: one not declared now is `declared` false, keeps what is written through it, and binds when a replacement declares it, its type then the declaration's. A value kept that the declared type doesn't take is logged and dropped.
  - `name`: Its path, or the name `withNames` gave it.
  - returns: The handle, the same each call; the declared one's when the shader declares it.
- `reserveUniformPath`: Returns a uniform and element for a path as GLSL writes it (`pointLights[1].color`) that the shader may declare only after a replacement, binding as `reserveUniform` does.
  - `path`: The path.
  - returns: The uniform and the element, the same object for the same path.
- `reserveSampler`: Returns a handle for a texture the shader may sample now or only after a replacement, binding, its kind then the declaration's, when a replacement declares it.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: The handle, the same each call.
- `hasSampler`: Returns whether the shader samples a texture.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: True when it is declared.
- `getUniform`: Returns the handle of a uniform the shader declares.
  - `name`: Its path (`roughness`, `material.roughness`, `lights.color`), or the name `withNames` gave it.
  - returns: The handle, the same each call.
  - throws `String`: A name the shader doesn't declare, listing those it does; given `lights[0].position`, it names `lights.position` and `getUniformPath`.
- `findUniform`: Finds the handle of a uniform the shader may not declare.
  - `name`: Its path, or the name `withNames` gave it.
  - returns: The handle, the same each call, or null.
- `getUniformPath`: Returns a uniform and element from a path as GLSL writes it, with brackets (`pointLights[1].color`, `bones[3]`), or without.
  - `path`: The path.
  - returns: The uniform and the element, the same object for the same path.
  - throws `String`: A path whose uniform the shader doesn't declare, or an index past its elements.
- `findUniformPath`: Finds a uniform and element from a path that may not be declared.
  - `path`: The path.
  - returns: The uniform and the element, or null: for a uniform the shader doesn't declare, an index past its elements, a path naming a struct or a struct's element rather than a field (`lights[1]`, `lights`), or a sampler's name.
- `getSampler`: Returns the handle of a texture the shader samples.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: The handle, the same each call.
  - throws `String`: A name the shader doesn't declare, listing those it does.
- `findSampler`: Finds the handle of a texture the shader may not sample.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: The handle, or null.
- `findUniformPlace`: Returns where a uniform is in this shader: its block's slot and its byte offset, as a pipeline's flip (proposal 9) or a check reads them.
  - `uniform`: The uniform.
  - returns: The slot and offset, the first block's when two stages' blocks hold it, or null when this shader doesn't declare it.
- `getAttribute`: Returns a vertex attribute the shader reads.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: The attribute, with its slot and type.
  - throws `String`: A name the shader doesn't declare, listing those it does.
- `findAttribute`: Finds a vertex attribute the shader may not read.
  - `name`: Its GLSL name, or the name `withNames` gave it.
  - returns: The attribute, or null.
- `computeVertexBuffer`: Returns the layout of a vertex buffer built for this shader, its records holding the attributes named, packed as floats in the order given.
  - `names`: The attributes, in their order in a record, by GLSL name or the name `withNames` gave them.
  - `instanced`: Optional. Whether the buffer steps once an instance; defaults to false.
  - returns: The buffer's layout: its stride, the sum of the attributes' sizes, and an attribute a column.
  - throws `String`: A name the shader doesn't declare, or an integer attribute (`ivec4`), which the platform can't feed yet.

  It suits a buffer a program fills for this shader (a sprite batch's, a variant's own). A mesh whose records are laid out already, drawn by any shader, is a `ShaderVertexLayout` (`ShaderVertexLayout.fromAttributes` packs one the same way for any shader). Each attribute takes its type's floats (`ShaderValueType.componentCount` times `columnCount`), and a matrix a `VertexAttribute` a column at consecutive slots, as `PipelineDesc.buffers` takes them.

  ```haxe
  var layout = shader.computeVertexBuffer(["position", "normal", "texCoord"]);   // 32-byte records
  var instances = shader.computeVertexBuffer(["instanceTransform"], true);       // 64-byte records, a slot a column
  ```
- `computeUnfedAttributes`: Returns the attributes the shader reads that no buffer of a layout feeds, for a check before a pipeline is made.
  - `buffers`: The layout, as `PipelineDesc.buffers` holds it.
  - returns: The attributes no buffer feeds, empty when every one is fed.

  Such an attribute reads its layout's constant (`ShaderVertexLayout.constants`), or (0, 0, 0, 1) (platform proposal 8).
- `withNames`: Returns this shader with some of its names changed, for code that finds what a shader declares by names other than its GLSL's.
  - `names`: Each GLSL name, mapped to the name it is to be found by.
  - returns: The shader with the names changed.
  - throws `String`: Two names mapped to one, or a new name that another attribute, uniform or texture of the same kind already has.

  The program is the same: only the names the finds and gets take change. A renamed thing is found by its new name alone; a struct's name renames the paths that start with it (`light` the `light.color`); a name in the map that the shader doesn't declare is skipped, so one map serves shaders that declare different parts of it. The shader returned is replaced with it; this one is unchanged.

  ```haxe
  // raylib's names, as helix-draw fills them
  var lit = Shader.compile("lit.vs", "lit.fs").withNames([
  "vertexPosition" => "position", "vertexTexCoord" => "texCoord", "vertexColor" => "color",
  "mvp" => "modelViewProjection", "colDiffuse" => "baseColor", "texture0" => "baseColorTexture"
  ]);
  ```

## ShaderAttribute

*typedef* in [`libs/services/src/helix/services/shaders/ShaderAttribute.hx`](../../libs/services/src/helix/services/shaders/ShaderAttribute.hx), `import helix.services.shaders.ShaderAttribute;`

Represents one of a shader's vertex attributes: the vertex stage's input at a slot, which a pipeline's `VertexAttribute` feeds.

- `type:ShaderValueType`: Its type, which says how many floats a record gives it (`Vec3` three).
- `slot:Int`: Its slot, its `layout(location = n)`: what `VertexAttribute.slot` names. A matrix takes a slot a column from it, each column fed as an attribute of its own.
- `glslName:String`: The input's name in the GLSL.
- `active:Bool`: Whether the vertex stage's code reads it, as the compiler finds; one unread is still reflected and fed.

## ShaderBlockValues

*class* in [`libs/services/src/helix/services/shaders/ShaderBlockValues.hx`](../../libs/services/src/helix/services/shaders/ShaderBlockValues.hx), `import helix.services.shaders.ShaderBlockValues;`, extends `ShaderUniformValues`

Represents the values of one shared block (`ShaderOptions.shared`), read by every values that shares it (`IShaderValues.shareBlock`, `ShaderScene.shareBlock`).

Per-frame data that many draws and shaders read alike (a camera, the lights) is a shared block: one the shaders declare alike in a file they include, or loose uniforms gathered by name (`ShaderSharedBlock.uniforms`). A renderer makes its own, and shares it on its scene (`ShaderScene`), so two renderers each have their own camera:

```haxe
var camera = ShaderBlockCompiler.compile("camera.glsl", "Camera");
scene.shareBlock(camera);                     // every material drawn in the scene reads it
// each frame, once:
camera.writeMatrix(lit.getUniform("viewProjection"), viewProjection);
// a shadow pass's scene holds the light's camera instead:
shadowScene.shareBlock(lightCamera);
```

It starts with every member 0, and is written by the handles of any shader that shares it; a handle outside the block throws. A typed class for it is `ShaderValueClasses.buildBlock`'s.

**A layout that changes.** When a shader sharing it is replaced in place with the block laid out anew, the block follows: it is laid out as the new shader has it, its values kept by name, and every values sharing it reads the new bytes. A sharer whose shader still has the old layout, until its own file is replaced, reads a copy packed from the block by name each time the block is written, so its values stay right. A layout two sharers' shaders declare differently once both are replaced, and so can't be one, is `layoutError`; the block keeps the newest.

```haxe
function new(source:IShaderHandles, blockName:String)
final blockName:String
var bytes(default, null):haxe.io.Bytes
var layoutError(default, null):Null<String>
```

- `new`: Creates the values of a shared block, every member 0.
  - `source`: A shader, or a set of variants, that names the block shared; any shader naming it shared alike may share it.
  - `blockName`: The block's name.
  - throws `String`: A source that names no shared block of that name (`ShaderOptions.shared`).
- `blockName`: Gets the block's GLSL name.
- `bytes`: Gets the block's bytes, at its declared size, as the newest layout lays it out: what each sharing values' `uniforms` holds at its slot. The platform never writes them: an adapter flipping a matrix for a render target flips its own copy (proposal 9).
- `layoutError`: Gets why two sharers' shaders can't share the block now (their layouts differ after both were replaced), or null when they can.

## ShaderBuildOptions

*typedef* in [`libs/services/src/helix/services/shaders/ShaderBuildOptions.hx`](../../libs/services/src/helix/services/shaders/ShaderBuildOptions.hx), `import helix.services.shaders.ShaderBuildOptions;`

Represents how `Shader.makeExpr` and `ShaderVariants.makeExpr` compile, for a library's macro: `ShaderOptions`' choices as values the macro has made rather than constants at a call.

- `shared:Null<Array<ShaderSharedBlock>>`: The blocks whose values are shared, as `ShaderOptions.shared`. Optional; none by default.
- `points:Null<Bool>`: Whether the compiler wraps the vertex stage to write a point size of 1, as `ShaderOptions.points`. Optional; false by default.
- `includes:Null<Map<String, String>>`: Texts an angle-bracket `#include` takes by name, before the build's class paths are looked in. Optional; none by default.
- `includeDirectories:Null<Array<String>>`: Directories a quoted `#include` looks in after the including file's own. Optional; none by default.
- `file:Null<String>`: The asset path of the file, as `ShaderOptions.file`. Optional; no file by default.
- `defines:Null<Array<String>>`: Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`, besides each stage's `HELIX_VERTEX` or `HELIX_FRAGMENT`. Optional; none by default.
- `clipScale:Null<Bool>`: Whether the compiler wraps the vertex stage with a clip scale, as `ShaderOptions.clipScale`. Optional; false by default.
- `check:Null<Shader -> Null<String>>`: The library's rules, run on the compiled shader: returns why it breaks them, which stops the build, or null. Optional.

## ShaderFeatures

*abstract* in [`libs/services/src/helix/services/shaders/ShaderFeatures.hx`](../../libs/services/src/helix/services/shaders/ShaderFeatures.hx), `import helix.services.shaders.ShaderFeatures;`

Represents a set of a `ShaderVariants`' features, the defines its variants differ by, as bits: `ShaderVariants.getShader` takes it.

A feature is a name alone, defined as 1 when on and not defined when off; a define with a value is a shared define (`ShaderOptions.defines`), the same in every variant. A set's features come from its variants (`ShaderVariants.getFeature`), or as static constants of a class `ShaderValueClasses.buildVariants` made (`LitValues.SKINNED | LitValues.INSTANCED`), so the compiler checks the names.

```haxe
static inline var NONE:ShaderFeatures
function with(other:ShaderFeatures):ShaderFeatures
function without(other:ShaderFeatures):ShaderFeatures
function toggled(other:ShaderFeatures):ShaderFeatures
function switched(other:ShaderFeatures, on:Bool):ShaderFeatures
function hasFeatures(other:ShaderFeatures):Bool
```

- `NONE`: No features: the variant compiled with none on.
- `with`: Returns the set with another set's features added.
  - `other`: The other set.
  - returns: The union.
- `without`: Returns the set with another set's features removed.
  - `other`: The features to remove.
  - returns: The set without them.
- `toggled`: Returns the set with another set's features turned over: each on turned off, each off turned on.
  - `other`: The features to turn over.
  - returns: The set with them turned over.
- `switched`: Returns the set with another set's features on or off, as a flag says.
  - `other`: The features.
  - `on`: Whether they are on.
  - returns: The set with them on or off.

  ```haxe
  features = features.switched(USE_MAP, map != 0).switched(USE_FOG, fog);
  ```
- `hasFeatures`: Returns whether the set holds every feature of another.
  - `other`: The other set.
  - returns: True when each of its features is in this one.

## ShaderOptions

*typedef* in [`libs/services/src/helix/services/shaders/ShaderOptions.hx`](../../libs/services/src/helix/services/shaders/ShaderOptions.hx), `import helix.services.shaders.ShaderOptions;`

Represents how a build-time compile at a call compiles: every macro that compiles a shader takes it, as a constant object written at the call or a class's static constant holding one (`static final OPTIONS:ShaderOptions = {...}`), so options several calls share live in one place. An array of them composes, left to right: `[Lit.OPTIONS, {file: "shaders/lit.shader"}]` takes `Lit.OPTIONS` and sets `file`; a later array (`defines`, `shared`) is added to an earlier one, a later value replaces an earlier one.

```haxe
Shader.compile("lit.vert", "lit.frag", {defines: ["MAX_LIGHTS=8"], includes: "three.ShaderChunk", shared: [{name: "Frame"}],
file: "shaders/lit.shader"});
```

- `shared:Null<Array<ShaderSharedBlock>>`: The blocks whose values are shared (`ShaderBlockValues`): a block the shader declares, or loose uniforms gathered into one. Optional; none by default. A values drawn while a shared block is shared neither on it nor on its base throws, so a frame's data is never silently 0, and a typed values class leaves a shared block's members out (`ShaderValueClasses.buildBlock` makes the block's own).
- `points:Null<Bool>`: Whether the compiler wraps the vertex stage so it writes a point size of 1 after the stage's own `main`, whatever the stage wrote, so a pipeline may draw it as points (`ShaderPipelineState.primitive` `Points`, which the platform refuses over any other shader). Optional; false by default.
- `includes:Null<String>`: A class whose static `String` constants (`static inline final` or `static final` with a constant value) are texts an angle-bracket `#include` takes by the constant's name: `#include <common>` takes `common`. It is named as Haxe names it from the call's file: `ShaderChunk`, `three.ShaderChunk`, or `three.Chunks.Standard` for a type in another type's module. Optional; none by default. An included text may include others. They are looked in before the build's class paths.
- `includeDirectories:Null<Array<String>>`: Directories a quoted `#include` looks in after the including file's own, relative to the file holding the call. Optional; none by default.
- `file:Null<String>`: The asset path of a file holding the compiled shader (`shaders/lit.shader`), which `Shaders.watch` watches, so the shader is replaced in place when the file changes. Optional; no file by default.
- `defines:Null<Array<String>>`: Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`. Optional; none by default. Each stage also has its own: `HELIX_VERTEX` in the vertex stage, `HELIX_FRAGMENT` in the fragment stage, so a file both include tells them apart.
- `clipScale:Null<Bool>`: Whether the compiler wraps the vertex stage so a draw into a render target is turned the right way up whatever the shader writes: it declares a loose `vec4 helix_clipScale` and multiplies `gl_Position` by it, component by component, after the stage's own `main`. Optional; false by default. A pipeline flips it with `flip: ClipScale, flipUniform: "helix_clipScale"` (`ShaderPipelineState.CLIP_SCALE`): a layer whose users write their own vertex stages (helix-raylib) needs no named matrix.
- `check:Null<String>`: A static function `Shader->Null<String>`, by its dotted path (`helix.draw.ShaderRules.check`), run on the compiled shader while the program builds: it returns why the shader breaks a library's rules, which stops the build at the call, or null. Optional; no check by default.

## ShaderPipeline

*class* in [`libs/services/src/helix/services/shaders/ShaderPipeline.hx`](../../libs/services/src/helix/services/shaders/ShaderPipeline.hx), `import helix.services.shaders.ShaderPipeline;`

Represents a pipeline `ShaderPrograms` keeps for a shader, a state and a vertex layout: an object a renderer holds, whose `handle` stays current across the shader's replacements.

It is never built inside a pass. After its shader is replaced, `handle` keeps the old pipeline, which draws as before, until the next `ShaderPrograms.prepareFrame`, the frame's start, disposes the old program and its pipelines and builds the new; `buildCount` then moves. A replaced program the GPU refuses is never a throw: the old program and pipeline stay, and `buildError` and the shader's `reloadError` say why.

```haxe
final shader:Shader
final state:ShaderPipelineState
final layout:ShaderVertexLayout
var handle(get, never):Int
var buildCount(default, null):Int
var buildError(default, null):Null<String>
```

- `shader`: Gets the shader.
- `state`: Gets the state.
- `layout`: Gets the vertex layout.
- `handle`: Gets the pipeline's `IGraphics` handle: the one built last, the old one until the frame after a replacement.
- `buildCount`: Gets the number of times it has been built: a renderer comparing it with the count it saw knows the handle changed.
- `buildError`: Gets why the last build failed (a replaced program the GPU refused, with its log), the old pipeline kept, or null.

## ShaderPipelineState

*class* in [`libs/services/src/helix/services/shaders/ShaderPipelineState.hx`](../../libs/services/src/helix/services/shaders/ShaderPipelineState.hx), `import helix.services.shaders.ShaderPipelineState;`

Represents what a pipeline fixes besides its program and its vertex layout: a `PipelineDesc` without `shader` and `buffers`, and the uniform flipped for a render target by name, for `ShaderPrograms`, which keeps one pipeline for each state by its values.

```haxe
var shadowCaster = ShaderPipelineState.OPAQUE.with({depthOnly: true, cull: Front});
```

```haxe
function new(?values:{primitive:Null<Primitive>, indexed:Null<Bool>, flipUniform:Null<String>, flip:Null<ClipFlip>, depthWrite:Null<Bool>, depthTest:Null<DepthTest>, depthOnly:Null<Bool>, cull:Null<CullFace>, colorWrite:Null<ColorChannels>, clockwise:Null<Bool>, blend:Null<Blend>})
static final OPAQUE(default, null):ShaderPipelineState
static final ALPHA(default, null):ShaderPipelineState
static final ADDITIVE(default, null):ShaderPipelineState
static final SPRITES(default, null):ShaderPipelineState
static final CLIP_SCALE(default, null):ShaderPipelineState
final primitive:Primitive
final indexed:Bool
final blend:Blend
final depthTest:DepthTest
final depthWrite:Bool
final cull:CullFace
final clockwise:Bool
final depthOnly:Bool
final colorWrite:ColorChannels
final flip:ClipFlip
final flipUniform:String
function with(values:{primitive:Null<Primitive>, indexed:Null<Bool>, flipUniform:Null<String>, flip:Null<ClipFlip>, depthWrite:Null<Bool>, depthTest:Null<DepthTest>, depthOnly:Null<Bool>, cull:Null<CullFace>, colorWrite:Null<ColorChannels>, clockwise:Null<Bool>, blend:Null<Blend>}):ShaderPipelineState
```

- `new`: Creates a state, each value given or as `OPAQUE` has it.
  - `values`: Optional. The values that differ from `OPAQUE`'s.
- `OPAQUE`: Opaque triangles, indexed, depth tested and written, back faces culled, the uniform `viewProjection` flipped for a render target: the name a library's shaders use. A layer whose shaders name it otherwise gives its own (raylib's `mvp`: `OPAQUE.with({flipUniform: "mvp"})`).
- `ALPHA`: As `OPAQUE`, blended by alpha, depth not written.
- `ADDITIVE`: As `ALPHA`, adding light.
- `SPRITES`: 2D: blended by alpha, no depth, nothing culled, `projection` flipped.
- `CLIP_SCALE`: As `OPAQUE`, flipping the clip scale a shader compiled with `ShaderOptions.clipScale` declares, whatever else it reads.
- `primitive`: Gets the primitive the draws make.
- `indexed`: Gets whether the draws are indexed, by uint32 indices.
- `blend`: Gets how the colors are combined with the target's.
- `depthTest`: Gets the depth test.
- `depthWrite`: Gets whether the draws write depth.
- `cull`: Gets which faces are culled.
- `clockwise`: Gets whether clockwise winding is the front face.
- `depthOnly`: Gets whether the draws write depth alone, for a shadow pass.
- `colorWrite`: Gets the color channels the draws write.
- `flip`: Gets how a draw into a render target is turned the right way up: `ViewProjection` a matrix's y row, `ClipScale` a vec4 clip scale the shader multiplies `gl_Position` by, `None` nothing.
  A shader is flipped only through a uniform it reads, one of those two; `ShaderOptions.clipScale` gives any shader one (`CLIP_SCALE`). A flipped draw's winding is reversed with it, by the adapter, so `clockwise` and `cull` mean what they say in a target and on the screen alike. A shadow pass is never flipped: a shadow map is stored bottom first, as clip space maps to it (`IGraphics.createShadowMap`).
- `flipUniform`: Gets the uniform `flip` reads, by name. `ShaderPrograms` finds its place in each shader (`Shader.findUniformPlace`), again after a replacement, and the pipeline names that place (platform proposal 9); `ShaderPrograms.getPipeline` refuses a shader without it unless `flip` is `None`.
- `with`: Returns this state with some values changed; this one is unchanged.
  - `values`: The values that differ.
  - returns: The new state.

## ShaderPrograms

*class* in [`libs/services/src/helix/services/shaders/ShaderPrograms.hx`](../../libs/services/src/helix/services/shaders/ShaderPrograms.hx), `import helix.services.shaders.ShaderPrograms;`

Provides shaders built on the GPU: a program for each shader, a pipeline for each state and vertex layout it is drawn with, each built again when the shader is replaced in place.

`getPipeline` returns a `ShaderPipeline`, the same object for the same shader, state and layout (the state told apart by its values, the layout by its values too, so a layout made again with the same buffers, placements and constants finds the same pipeline), which a renderer holds and draws through by its `handle`. The layout is resolved for each shader by name or slot (`ShaderVertexLayout.computeBuffers`), with what no buffer feeds read as its constant; the state's `flipUniform` is found in each shader (`Shader.findUniformPlace`). Both are done once, and again after a replacement; nothing is made per draw.

**Nothing is built inside a pass**, and that is enforced. A frame runs from `prepareFrame`, which the program, or the renderer it draws through, calls before the frame's first pass (before `IGraphics.beginTargetPass`, `beginShadowPass` or `beginFrame`), to `finishFrame`, after its last. `prepareFrame` rebuilds what a replaced shader made stale; until it does, draws use the old pipeline. Between the two, a `getPipeline`, `getProgram` or `prepare` that would build throws, naming the pipeline, while `findPipeline` and a `getPipeline` of one already built never build. First builds happen at setup, or while a level loads, through `prepare` and `prepareVariants`.

```haxe
var programs = new ShaderPrograms(graphics);
programs.prepareVariants(lit, [
{features: ShaderFeatures.NONE, state: ShaderPipelineState.OPAQUE, layout: mesh},
{features: skinned, state: ShaderPipelineState.OPAQUE, layout: skinnedMesh},
{features: ShaderFeatures.NONE, state: shadowCaster, layout: mesh}
]);
var pipeline = programs.getPipeline(lit.getShader(skinned), ShaderPipelineState.OPAQUE, skinnedMesh);   // kept by the renderer
// each frame:
programs.prepareFrame();
graphics.beginFrame(width, height, 0xff000000);
graphics.draw(pipeline.handle, buffers, indices, 0, count, 0, 1, values.textures, values.samplings, values.uniforms);
graphics.endFrame();
programs.finishFrame();
```

```haxe
function new(graphics:IGraphics)
function prepareFrame():Void
function finishFrame():Void
function getProgram(shader:Shader):Int
function getPipeline(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):ShaderPipeline
function findPipeline(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):Null<ShaderPipeline>
function prepare(shader:Shader, state:ShaderPipelineState, layout:ShaderVertexLayout):Void
function prepareVariants(variants:ShaderVariants, pipelines:Array<{state:ShaderPipelineState, layout:ShaderVertexLayout, features:ShaderFeatures}>):Array<ShaderPipeline>
function disposeShader(shader:Shader):Void
function dispose():Void
```

- `new`: Creates the programs over the graphics they are built on.
  - `graphics`: The graphics.
- `prepareFrame`: Starts a frame, before its first pass: rebuilds every program and pipeline whose shader was replaced since, then refuses builds until `finishFrame`. A rebuild the GPU refuses keeps the old (`ShaderPipeline.buildError`, `Shader.reloadError`).
- `finishFrame`: Ends a frame, after its last pass: builds are allowed again.
- `getProgram`: Returns a shader's program, built the first time and again at the `prepareFrame` after each replacement.
  - `shader`: The shader.
  - returns: The program's `IGraphics` handle.
  - throws `String`: A first build inside a frame (between `prepareFrame` and `finishFrame`), or a first program the GPU doesn't build, with its log.
- `getPipeline`: Returns the pipeline drawing a shader with a state and a vertex layout, built the first time.
  - `shader`: The shader.
  - `state`: What the pipeline fixes besides its program and layout.
  - `layout`: The mesh's vertex layout.
  - returns: The pipeline, the same object for the same shader, state and layout.
  - throws `String`: A first build inside a frame; a layout the shader can't read (`ShaderVertexLayout.computeBuffers`); a state whose `flip` isn't `None` for a shader without its `flipUniform`; or a first build the GPU refuses.
- `findPipeline`: Finds a pipeline already built, never building one, as a draw inside a pass may ask.
  - `shader`: The shader.
  - `state`: The state.
  - `layout`: The vertex layout.
  - returns: The pipeline, or null when none was built for them.
- `prepare`: Builds a shader's program and a pipeline ahead of its draws, outside a frame.
  - `shader`: The shader.
  - `state`: The state.
  - `layout`: The vertex layout.
  - throws `String`: A call inside a frame, or what `getPipeline` throws.
- `prepareVariants`: Builds the pipelines some variants are drawn with, each variant with the state and layout it pairs with, outside a frame.
  - `variants`: The set.
  - `pipelines`: Each pipeline to build: a variant's features, a state and a layout. A variant may come several times.
  - returns: The pipelines, by the same index.
  - throws `String`: A call inside a frame, a combination not compiled, or what `getPipeline` throws.
- `disposeShader`: Disposes a shader's program and its pipelines, as when it is no longer drawn. Inside a frame it is deferred to `finishFrame`, so draws already made keep working. Its held `ShaderPipeline`s then have `handle` 0, and are built again, the same objects, by the next `getPipeline` or `prepare` for them outside a frame.
  - `shader`: The shader.
- `dispose`: Disposes every program and pipeline it built.

## ShaderSampler

*class* in [`libs/services/src/helix/services/shaders/ShaderSampler.hx`](../../libs/services/src/helix/services/shaders/ShaderSampler.hx), `import helix.services.shaders.ShaderSampler;`

Represents a texture a shader samples, found once by name, which `writeTexture` and `shareTexture` take.

`getSampler` and `findSampler` (`IShaderHandles`) return it. The same name gives the same handle each time, updated in place when its shader is reloaded, and it works on values of any shader, resolved there once by name. A sampler array (`uniform sampler2D maps[4]`) is refused while the program builds: every adapter binds one texture a slot.

A sampler given no texture reads the platform's clear texture of its kind (`IGraphics.draw`): 0 in every channel for 2D, cube, array and data textures, and for a shadow map one cleared to the farthest depth, so a comparison reads lit (1). A render target sampled in a later pass reads the right way up on every adapter (stored top row first, texture coordinates from 0 at the top).

A texture handle is an `Int`, so the values can't tell its kind: one of another kind than `kind` is the program's mistake, which `IGraphics.draw` refuses.

```haxe
final name:String
var kind(default, null):ShaderSamplerKind
var slot(default, null):Int
var active(default, null):Bool
var declared(default, null):Bool
```

- `name`: Gets the name it is found by: its GLSL name, or the name `Shader.withNames` gave it.
- `kind`: Gets the kind of texture it reads.
- `slot`: Gets its texture slot in its shader, as `IGraphics.draw`'s `textures` holds it; on a set's handle, the first variant's.
- `active`: Gets a value indicating whether its shader's code samples it, as the compiler finds; one unsampled is still reflected and bound.
- `declared`: Gets a value indicating whether its shader declares it now: false after a reload removed it, or in a variant without it.

## ShaderSamplerKind

*abstract* in [`libs/services/src/helix/services/shaders/ShaderSamplerKind.hx`](../../libs/services/src/helix/services/shaders/ShaderSamplerKind.hx), `import helix.services.shaders.ShaderSamplerKind;`

Specifies what kind of texture a sampler reads, from its GLSL type, as `IGraphics` creates them.

- `ShaderSamplerKind.Texture2D`: A `sampler2D`: an image or a render target (`IGraphics.createTexture`, `createRenderTarget`).
- `ShaderSamplerKind.Cube`: A `samplerCube`: a cubemap (`IGraphics.createCubeTexture`).
- `ShaderSamplerKind.Array2D`: A `sampler2DArray`: a texture of layers.
- `ShaderSamplerKind.Shadow`: A `sampler2DArrayShadow`: a shadow map read through a comparison sampler (`IGraphics.createShadowMap`).
- `ShaderSamplerKind.Data`: A `sampler2D` the code reads only with `texelFetch`: a data texture, never filtered (`IGraphics.createDataTexture`). `textureSize` is a query, not a read, so using it leaves a sampler `Data`; any `texture` call makes it `Texture2D`.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Texture2D, Cube): what Std.string, interpolation and trace show.

## ShaderScene

*class* in [`libs/services/src/helix/services/shaders/ShaderScene.hx`](../../libs/services/src/helix/services/shaders/ShaderScene.hx), `import helix.services.shaders.ShaderScene;`

Represents what a scene, or one pass of it, shares with every material drawn in it, whatever their shaders: its shared blocks (a camera, the lights) and shared textures (a shadow map), by name.

A values reads a shared block or texture from, in order: what it shares itself, its base's (and its base's base), then its scene (`IShaderValues.scene`), its own or else its base's. So a material made once is drawn in any scene by giving its draw that scene, and one scene binds every material in it:

```haxe
var main = new ShaderScene();
main.shareBlock(camera);
main.shareBlock(lights);
main.shareTexture("shadowMap", shadowMap);
// a depth-only pass drawing the lit variants binds every shared block they name, its own camera among them
var shadowPass = new ShaderScene();
shadowPass.shareBlock(lightCamera);
shadowPass.shareBlock(lights);
// each draw:
drawn.scene = pass == Shadow ? shadowPass : main;
```

Changing a values' scene, or a scene's blocks and textures, costs no copy: each shared slot of the values points at the new bytes or texture at its next read. A block a shader names shared that neither the values, its base nor the scene shares makes a draw throw, naming it. A block whose layout a shader doesn't have is refused where it is shared with the shader's values, and skipped by a scene for a shader that doesn't name it.

```haxe
function new()
function shareBlock(block:ShaderBlockValues):Void
function unshareBlock(blockName:String):Void
function shareTexture(samplerName:String, shared:ShaderSharedTexture):Void
function unshareTexture(samplerName:String):Void
function findSharedBlock(blockName:String):Null<ShaderBlockValues>
function findSharedBlockOf(uniform:ShaderUniform):Null<ShaderBlockValues>
function findSharedTexture(samplerName:String):Null<ShaderSharedTexture>
```

- `new`: Creates an empty scene.
- `shareBlock`: Shares a block with every values reading this scene, replacing one of its name.
  - `block`: The shared block.
- `unshareBlock`: Stops sharing a block of a name.
  - `blockName`: The block's name.
- `shareTexture`: Shares a texture, by sampler name, with every values reading this scene whose shader samples a texture of that name.
  - `samplerName`: The sampler's GLSL name.
  - `shared`: The shared texture.
- `unshareTexture`: Stops sharing a texture of a sampler name.
  - `samplerName`: The sampler's GLSL name.
- `findSharedBlock`: Finds a shared block by name.
  - `blockName`: The block's name.
  - returns: The block, or null.
- `findSharedBlockOf`: Finds the shared block holding a uniform, so a uniform of a shared block is written through the scene (`scene.findSharedBlockOf(viewProjection).writeMatrix(viewProjection, m)`).
  - `uniform`: The uniform.
  - returns: The block shared under its block's name, or null when the uniform isn't a shared block's or none is shared.
- `findSharedTexture`: Finds a shared texture by sampler name.
  - `samplerName`: The sampler's GLSL name.
  - returns: The shared texture, or null.

## ShaderSharedBlock

*typedef* in [`libs/services/src/helix/services/shaders/ShaderSharedBlock.hx`](../../libs/services/src/helix/services/shaders/ShaderSharedBlock.hx), `import helix.services.shaders.ShaderSharedBlock;`

Represents a block whose values many shaders share (`ShaderBlockValues`), named in `ShaderOptions.shared`.

A block the shader declares is named alone (`{name: "Frame"}`). Loose uniforms are gathered into one by naming them (`{name: "Lights", uniforms: ["lights", "ambient", "viewPos"]}`), so a shader written with loose uniforms, as raylib's `lighting.fs` is, shares them without its GLSL changing: they become one block both stages read, laid out in the order given, each uniform's declaration taken from wherever the stages declare it.

- `uniforms:Null<Array<String>>`: Loose uniforms gathered into the block, by name, a struct array whole (`lights`). Optional; when omitted, the shader declares the block itself.
- `name:String`: The block's name: one the shader declares, or the name of the block the `uniforms` are gathered into.

## ShaderSharedTexture

*class* in [`libs/services/src/helix/services/shaders/ShaderSharedTexture.hx`](../../libs/services/src/helix/services/shaders/ShaderSharedTexture.hx), `import helix.services.shaders.ShaderSharedTexture;`

Represents a texture many values read, as a scene's shadow map or a white fallback, changeable at any time and seen at once by every values sharing it (`IShaderValues.shareTexture`), whatever their shader.

```haxe
var shadowMap = new ShaderSharedTexture(graphics.createShadowMap(2048, 1));
scene.shareTexture("shadowMap", shadowMap);   // every material drawn in the scene reads it
shadowMap.texture = largerMap;                                        // every sharer reads the new one from its next draw
```

```haxe
function new(?texture:Int = 0, ?sampling:Sampling)
var texture:Int
var sampling:Sampling
```

- `new`: Creates a shared texture.
  - `texture`: Optional. The texture; defaults to none.
  - `sampling`: Optional. How it is sampled; defaults to `Sampling.LINEAR`.
- `texture`: Gets or sets the texture, as an `IGraphics` handle, or 0 for none. The handle is trusted, as `writeTexture`'s is.
- `sampling`: Gets or sets how it is sampled; `Sampling.LINEAR` by default.

## ShaderSnapshot

*class* in [`libs/services/src/helix/services/shaders/ShaderSnapshot.hx`](../../libs/services/src/helix/services/shaders/ShaderSnapshot.hx), `import helix.services.shaders.ShaderSnapshot;`

Represents a copy of values as a draw would read them now, for a batcher that records draws and submits them later.

A draw through `IGraphics.draw` reads the values during the call, so a draw made at once needs none of this. A recorded draw does: `ShaderValues.capture` fills a snapshot with the bytes, textures and samplings as they are, and the recorded draw submits the snapshot's arrays. A snapshot reuses its bytes and arrays from one capture to the next, so a batcher keeping a pool of them allocates nothing per draw once they have grown.

A snapshot is of the layout it was captured in. Replacements take effect only at a frame's start (`Shaders.prepareFrame`, then `ShaderPrograms.prepareFrame`), so a snapshot captured and submitted within one frame always meets the program it was captured for; one kept across frames is captured again.

```haxe
function new()
final uniforms:Array<Null<haxe.io.Bytes>>
final textures:Array<Int>
final samplings:Array<Sampling>
```

- `new`: Creates an empty snapshot.
- `uniforms`: Gets each block's bytes as captured, by slot, as `IGraphics.draw`'s `uniforms`.
- `textures`: Gets the textures as captured, by slot.
- `samplings`: Gets the samplings as captured, by slot.

## ShaderUniform

*class* in [`libs/services/src/helix/services/shaders/ShaderUniform.hx`](../../libs/services/src/helix/services/shaders/ShaderUniform.hx), `import helix.services.shaders.ShaderUniform;`

Represents a uniform, found once by name, which the values' `write` methods take: a block member, a struct's field, or a field of an array of structs.

`getUniform` and `findUniform` (`IShaderHandles`) return it. The same name gives the same handle each time. It is never looked up again: when its shader is replaced in place (`Shader.reloadCount`), the shader updates it. A handle works on values of any shader, as on another variant of its set or a shader sharing its block: it is resolved there once, by name, and kept.

An array of structs is not indexed by name. Each of its fields is one uniform whose elements are the array's (`lights.color`, with `elementCount` 4), so per-frame code builds no strings: `values.writeVector3(lightColor, r, g, b, i)`. A by-name layer holding paths like `lights[1].color` turns each into a handle and an element once (`getUniformPath`).

```haxe
final name:String
var type(default, null):ShaderValueType
var elementCount(default, null):Int
var blockName(default, null):String
var shared(default, null):Bool
var active(default, null):Bool
var declared(default, null):Bool
```

- `name`: Gets the name it is found by: its GLSL path (`roughness`, `material.roughness`, `lights.color`), or the name `Shader.withNames` gave it.
- `type`: Gets its type: its declaration's, or, for one reserved (`reserveUniform`) and not declared yet, `Float` until it is.
- `elementCount`: Gets the number of elements: 1, an array's length, or the length of the array of structs it is a field of.
- `blockName`: Gets the GLSL name of the block it is in: a named block, a shared block's (`ShaderSharedBlock.name`), or `helix_uniforms` for a loose uniform.
- `shared`: Gets a value indicating whether its block is shared (`ShaderOptions.shared`), so it is written on a `ShaderBlockValues`.
- `active`: Gets a value indicating whether its shader's code reads it, as the compiler finds: GL's `glGetUniformLocation` gives -1 for one that isn't, which a layer matching GL (helix-raylib) does too. Every declared uniform is reflected, read or not. It is the whole uniform's: an array read at any element is active, as the compiler can't tell which elements a dynamic index reads.
- `declared`: Gets a value indicating whether its shader declares it now. False after a reload removed it, or in a variant without it: values written through it are then kept, and written once a reload brings it back.

## ShaderUniformPath

*class* in [`libs/services/src/helix/services/shaders/ShaderUniformPath.hx`](../../libs/services/src/helix/services/shaders/ShaderUniformPath.hx), `import helix.services.shaders.ShaderUniformPath;`

Represents a uniform path as GLSL and three.js write it (`pointLights[1].color`, `bones[3]`), turned once into the uniform and the element it names.

`getUniformPath` and `findUniformPath` (`IShaderHandles`) return it, the same object for the same path, so a layer that sets values by such names parses each once: `values.writeColor(path.uniform, color, path.elementIndex)`.

```haxe
final path:String
final uniform:ShaderUniform
final elementIndex:Int
```

- `path`: Gets the path as given.
- `uniform`: Gets the uniform it names (`pointLights.color`).
- `elementIndex`: Gets the index of the element it names: the index in its brackets, or 0.

## ShaderUniformValues

*class* in [`libs/services/src/helix/services/shaders/ShaderUniformValues.hx`](../../libs/services/src/helix/services/shaders/ShaderUniformValues.hx), `import helix.services.shaders.ShaderUniformValues;`

Provides writing uniform values by handle, which `ShaderValues`, `ShaderBlockValues` and `ShaderVariantValues` share.

Each `write` method takes a `ShaderUniform`, found once (`getUniform`), and writes the value at its std140 offset at once, so nothing is looked up or converted when it draws. Every name here starts with `write`, so a typed class's generated `setX` members (`ShaderValueClasses`) never meet one, whatever a uniform is called.

A value of the wrong kind for the uniform's type (a float for a `mat4`, an element past its end) throws, naming the uniform: it is the program's mistake. A handle the values' shader doesn't declare now (`ShaderUniform.declared` false, in a variant without it or after a reload removed it) is kept and written once the shader declares it.

Colors: `writeColor` writes 0xAARRGGBB's channels as stored, each over 255, so 0 to 1 and still sRGB-encoded, as raylib and a 2D tint want; `writeLinearColor` decodes red, green and blue from sRGB to linear light first (alpha as stored), as three.js's color management does with a hex color. A color without alpha (0xRRGGBB) is written with `writeRgb` or `writeLinearRgb`, the latter with a scale (a light's color times its intensity); `writeColor` would read its top byte as alpha 0. A color above 1 otherwise is written with `writeVector3` or `writeVector`.

A values made over a base (`ShaderValues.base`) reads, for each uniform it hasn't written, its base's value now: a block it hasn't written into is the base's bytes by reference, and its first write into one copies it (copy on write).

```haxe
function write(uniform:ShaderUniform, value:ShaderValue, ?elementIndex:Int = 0):Void
function writeFloat(uniform:ShaderUniform, value:Float, ?elementIndex:Int = 0):Void
function writeVector(uniform:ShaderUniform, x:Float, y:Float, z:Float, w:Float, ?elementIndex:Int = 0):Void
function writeVector3(uniform:ShaderUniform, x:Float, y:Float, z:Float, ?elementIndex:Int = 0):Void
function writeVector2(uniform:ShaderUniform, x:Float, y:Float, ?elementIndex:Int = 0):Void
function writeColor(uniform:ShaderUniform, color:Int, ?elementIndex:Int = 0):Void
function writeRgb(uniform:ShaderUniform, rgb:Int, ?elementIndex:Int = 0):Void
function writeLinearRgb(uniform:ShaderUniform, rgb:Int, ?scale:Float = 1, ?elementIndex:Int = 0):Void
function writeLinearColor(uniform:ShaderUniform, color:Int, ?elementIndex:Int = 0):Void
function writeBool(uniform:ShaderUniform, value:Bool, ?elementIndex:Int = 0):Void
function writeMatrix(uniform:ShaderUniform, matrix:Matrix3D, ?elementIndex:Int = 0):Void
function writeFloats(uniform:ShaderUniform, values:Array<Float>, ?firstElementIndex:Int = 0):Void
function writeInt(uniform:ShaderUniform, value:Int, ?elementIndex:Int = 0):Void
function writeInts(uniform:ShaderUniform, values:Array<Int>, ?firstElementIndex:Int = 0):Void
```

- `write`: Writes a uniform from a value held as data.
  - `uniform`: The uniform.
  - `value`: The value, written as its method writes it; a `Texture` is refused (it is a sampler's, `writeSamplerValue`).
  - `elementIndex`: Optional. The index of the array element written first; defaults to 0.
- `writeFloat`: Writes a float uniform, or an element of one.
  - `uniform`: The uniform.
  - `value`: The value.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeVector`: Writes a `vec2`, `vec3` or `vec4` uniform's components, as many as it has, or an element of one.
  - `uniform`: The uniform.
  - `x`: The first component.
  - `y`: The second component.
  - `z`: The third component, for a `vec3` or `vec4`.
  - `w`: The fourth component, for a `vec4`.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeVector3`: Writes a `vec3` uniform, or an element of one.
  - `uniform`: The uniform.
  - `x`: The first component.
  - `y`: The second component.
  - `z`: The third component.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeVector2`: Writes a `vec2` uniform, or an element of one.
  - `uniform`: The uniform.
  - `x`: The first component.
  - `y`: The second component.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeColor`: Writes a `vec4` uniform as a color's red, green, blue and alpha, or a `vec3` as its red, green and blue, or an element of one.
  - `uniform`: The uniform.
  - `color`: The color, as 0xAARRGGBB.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeRgb`: Writes a `vec3` or `vec4` uniform's red, green and blue from 0xRRGGBB as stored, each over 255, leaving a `vec4`'s fourth component as it was, or an element of one: a color without alpha, as three.js writes one (`0xff8040`), which `writeColor` would read as alpha 0.
  - `uniform`: The uniform.
  - `rgb`: The color, as 0xRRGGBB.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeLinearRgb`: Writes a `vec3` or `vec4` uniform's red, green and blue from 0xRRGGBB decoded from sRGB to linear light and multiplied by a scale, leaving a `vec4`'s fourth component as it was, or an element of one: three.js's `color.setHex(hex)` times a light's intensity.
  - `uniform`: The uniform.
  - `rgb`: The color, as 0xRRGGBB, sRGB-encoded.
  - `scale`: Optional. What each linear channel is multiplied by; defaults to 1.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeLinearColor`: Writes a `vec4` uniform as a color decoded from sRGB to linear light (red, green and blue; alpha as stored), or a `vec3` as its red, green and blue so decoded, or an element of one.
  - `uniform`: The uniform.
  - `color`: The color, as 0xAARRGGBB, sRGB-encoded.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeBool`: Writes a `bool` uniform, as 1 or 0, or an element of one.
  - `uniform`: The uniform.
  - `value`: The value.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeMatrix`: Writes a `mat4` uniform, or an element of one.
  - `uniform`: The uniform.
  - `matrix`: The matrix.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeFloats`: Writes a float uniform from its floats in GLSL's order, packed: each element its type's floats one after another, with no padding (3 for a `vec3`, 9 for a `mat3` by columns), whatever std140 pads them to in the block.
  - `uniform`: The uniform.
  - `values`: The floats, a whole number of elements, which must not run past the uniform's last element: a write past it throws, writing nothing.
  - `firstElementIndex`: Optional. The index of the first element written; defaults to 0.
- `writeInt`: Writes an integer uniform (`int`, `uint` as the value's bits, `bool` as 0 or not), or the first component of an integer vector, or an element of one.
  - `uniform`: The uniform.
  - `value`: The value.
  - `elementIndex`: Optional. The index of the array element written; defaults to 0.
- `writeInts`: Writes an integer, unsigned or `bool` uniform from integers in order, packed as `writeFloats` packs floats: an `ivecN`'s or `bvecN`'s components, elements one after another (a `bool` 0 or not).
  - `uniform`: The uniform.
  - `values`: The integers, a whole number of elements, which must not run past the uniform's last element: a write past it throws, writing nothing.
  - `firstElementIndex`: Optional. The index of the first element written; defaults to 0.

## ShaderValue

*enum* in [`libs/services/src/helix/services/shaders/ShaderValue.hx`](../../libs/services/src/helix/services/shaders/ShaderValue.hx), `import helix.services.shaders.ShaderValue;`

Specifies a uniform's value for `ShaderUniformValues.write`, for code that holds values as data (a material's table of them).

Each is written as its method writes it: `Vector` as `writeVector`, `Color` as `writeColor`, `LinearColor` as `writeLinearColor`.

- `Float(value:Float)`: A float.
- `Vector(x:Float, y:Float, z:Float, w:Float)`: A vector's components, as many as the uniform has.
- `Color(color:Int)`: A color, 0xAARRGGBB, its channels over 255.
- `LinearColor(color:Int)`: A color, 0xAARRGGBB, decoded from sRGB to linear light.
- `Rgb(rgb:Int)`: A color without alpha, 0xRRGGBB, as stored (`writeRgb`).
- `LinearRgb(rgb:Int, scale:Float)`: A color without alpha, 0xRRGGBB, decoded to linear light and multiplied by a scale (`writeLinearRgb`).
- `Texture(texture:Int, ?sampling:Sampling)`: A texture and how it is sampled, for a sampler (`IShaderValues.writeSamplerValue`); `write` refuses it.
- `Bool(value:Bool)`: A `bool`.
- `Matrix(matrix:Matrix3D)`: A `mat4`.
- `Floats(values:Array<Float>)`: Floats in GLSL's order: a vector's components, a matrix's by columns, elements one after another.
- `Int(value:Int)`: An integer.
- `Ints(values:Array<Int>)`: Integers in order: an `ivecN`'s components, elements one after another.

## ShaderValueType

*abstract* in [`libs/services/src/helix/services/shaders/ShaderValueType.hx`](../../libs/services/src/helix/services/shaders/ShaderValueType.hx), `import helix.services.shaders.ShaderValueType;`

Specifies the GLSL type of a uniform or a vertex attribute, as its GLSL name.

- `ShaderValueType.Float`: One float.
- `ShaderValueType.Vec2`: Two floats.
- `ShaderValueType.Vec3`: Three floats; in a block it takes 16 bytes' alignment and 12 of room.
- `ShaderValueType.Vec4`: Four floats.
- `ShaderValueType.Mat2`: A 2x2 matrix of floats, by columns, each column 16 bytes in a block.
- `ShaderValueType.Mat3`: A 3x3 matrix of floats, by columns, each column 16 bytes in a block.
- `ShaderValueType.Mat4`: A 4x4 matrix of floats, by columns.
- `ShaderValueType.Int`: One 32-bit integer.
- `ShaderValueType.Ivec2`: Two integers.
- `ShaderValueType.Ivec3`: Three integers.
- `ShaderValueType.Ivec4`: Four integers.
- `ShaderValueType.Bool`: One `bool`, 4 bytes in a block, written as 0 or 1 (`writeBool`, `writeInt`).
- `ShaderValueType.Bvec2`: Two `bool`s.
- `ShaderValueType.Bvec3`: Three `bool`s.
- `ShaderValueType.Bvec4`: Four `bool`s.
- `ShaderValueType.Uint`: One 32-bit unsigned integer, written as an `Int`'s bits (`writeInt`).
- `ShaderValueType.Uvec2`: Two unsigned integers.
- `ShaderValueType.Uvec3`: Three unsigned integers.
- `ShaderValueType.Uvec4`: Four unsigned integers.

```haxe
var componentCount(get, never):Int
var columnCount(get, never):Int
var integer(get, never):Bool
```

- `componentCount`: Gets the number of components in one column: 1 for a scalar, 2 to 4 for a vector, a matrix's rows.
- `columnCount`: Gets the number of columns: a matrix's 2 to 4, and 1 for anything else. As a vertex attribute, a matrix takes a slot a column.
- `integer`: Gets a value indicating whether it holds integers, unsigned integers or bools rather than floats.

## ShaderValues

*class* in [`libs/services/src/helix/services/shaders/ShaderValues.hx`](../../libs/services/src/helix/services/shaders/ShaderValues.hx), `import helix.services.shaders.ShaderValues;`, extends `ShaderUniformValues`, implements `IShaderValues`

Represents values for one shader's uniforms and textures, kept as `IGraphics.draw` takes them.

Each uniform block is kept as its bytes at its declared size, by slot; each texture slot as a texture handle and its sampling. A draw hands the three arrays over as they are:

```haxe
graphics.draw(pipeline.handle, [vertices], indices, 0, 6, 0, 1, values.textures, values.samplings, values.uniforms);
```

`IGraphics.draw` reads them during the call, so a value changed between two draws gives each its own. Values are written by handle (`ShaderUniformValues`' `write` methods, `writeTexture`).

**Layers.** A values made over a base reads, for each uniform and texture it hasn't written and each block and texture it hasn't shared, the base's as they are now. A block it hasn't written into is the base's own bytes, shared by reference, so nothing is copied. Its first write into one of the base's blocks gives it its own copy of that block (copy on write), which takes the base's later changes to the block's other uniforms at its next read, once a change, never per draw. A base may itself have a base.

The layers a program makes: a scene's defaults; each material over them, its values written once; and a draw's own values over the material, its per-draw uniforms (a model's matrix, its bones) written each draw. A material-wide write then never reaches what a draw wrote, and a renderer keeps one draw values per shader, its `base` set to each draw's material, so nothing is allocated per draw:

```haxe
var defaults = new ShaderValues(lit);
var red = new ShaderValues(lit, defaults);              // a material
var drawn = new ShaderValues(lit);                      // the renderer's, for every draw through `lit`
// a draw:
drawn.base = red;
drawn.scene = mainScene;
drawn.writeMatrix(model, transform);
graphics.draw(pipeline.handle, buffers, indices, 0, count, 0, 1, drawn.textures, drawn.samplings, drawn.uniforms);
```

Setting `base` copies nothing for the blocks the draw values haven't written into; the block holding their per-draw uniforms is filled again from the new base once (one copy of that block a draw). With no base, a uniform reads 0, a texture none.

**When values are read.** `IGraphics.draw` reads the arrays during the call, so a value written after a draw doesn't reach it. A batcher recording draws to submit later captures each (`capture`, into a reused `ShaderSnapshot`).

**Shared blocks and textures.** A block the shader names shared (`ShaderOptions.shared`) is read from a `ShaderBlockValues` shared on these values, their base, or their scene (`ShaderScene`), its bytes shared, never copied; a `ShaderSharedTexture` likewise for a sampler. Reading `uniforms` while a shared block is shared nowhere throws, naming the block, so a frame's data is never silently 0. Writing a shared block's uniform on these values throws too: it is written on the block.

**After a replacement** of the shader (`Shader.reloadCount`), the values are packed again into the new layout from what was written on them, at the next write or read; what the new shader lacks is kept, and written again if a later replacement brings it back.

For a material whose values serve every variant of a set, `ShaderVariantValues` makes and keeps one of these for each variant.

```haxe
function new(shader:Shader, ?base:ShaderValues, ?scene:ShaderScene)
final shader:Shader
var base(default, set):Null<ShaderValues>
var scene(get, set):Null<ShaderScene>
var uniforms(get, never):Array<Null<haxe.io.Bytes>>
var textures(get, never):Array<Int>
var samplings(get, never):Array<Sampling>
function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void
function writeSamplerValue(sampler:ShaderSampler, value:ShaderValue):Void
function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void
function unshareTexture(sampler:ShaderSampler):Void
function shareBlock(block:ShaderBlockValues):Void
function unshareBlock(blockName:String):Void
function findSharedBlock(blockName:String):Null<ShaderBlockValues>
function capture(snapshot:ShaderSnapshot):Void
function deleteValue(uniform:ShaderUniform):Void
function deleteValues():Void
```

- `new`: Creates values for a shader.
  - `shader`: The shader.
  - `base`: Optional. Values of the same shader to read what these don't write or share from: a material's, under a draw's own.
  - `scene`: Optional. The scene to read shared blocks and textures from.
  - throws `String`: A base of another shader.
- `shader`: Gets the shader whose values these are.
- `base`: Gets or sets the values these read what they haven't written or shared from, or null: values of the same shader, as a material under a draw's own values. Setting it copies nothing for a block these haven't written into; a block they have written into is filled again, once, from the new base's for what they didn't write.
  - throws `String`: Values of another shader.
- `scene`: Gets or sets the scene these read shared blocks and textures from when neither they nor their base share them, or null for their base's. Changing it copies nothing.
- `uniforms`: Gets each uniform block's bytes, by slot (by stage and slot, proposal 10), at its declared size, or null for a slot the shader lacks: `IGraphics.draw`'s `uniforms`. The array is kept and updated in place: reading it allocates nothing. A shared block's slot holds its `ShaderBlockValues.bytes`. Reading it throws while a block the shader names shared is shared nowhere.
- `textures`: Gets the texture handle bound at each texture slot, by slot, 0 for none: `IGraphics.draw`'s `textures`, kept and updated in place.
- `samplings`: Gets how each texture slot is sampled, by slot: `IGraphics.draw`'s `samplings`, kept and updated in place.
- `writeTexture`: Writes the texture a sampler reads, and how.
  - `sampler`: The sampler.
  - `texture`: The texture, as an `IGraphics` handle of the sampler's kind, or 0 for none.
  - `sampling`: Optional. How it is sampled; defaults to `Sampling.LINEAR`.
- `writeSamplerValue`: Writes a sampler from a value held as data (`ShaderValue.Texture`).
  - `sampler`: The sampler.
  - `value`: A `ShaderValue.Texture`.
  - throws `String`: A value of another case.
- `shareTexture`: Makes a sampler read a shared texture, until `unshareTexture`.
  - `sampler`: The sampler.
  - `shared`: The shared texture.
- `unshareTexture`: Stops a sampler reading a shared texture; it reads what was written, or its base's.
  - `sampler`: The sampler.
- `shareBlock`: Makes the shader's block of a shared block's name read the shared block's bytes, replacing one of that name shared before.
  - `block`: The shared block.
  - throws `String`: A shader that names no shared block of that name.
- `unshareBlock`: Stops sharing a block of a name: it reads its base's, or nothing.
  - `blockName`: The block's name.
- `findSharedBlock`: Returns the shared block a block of a name reads now: its own, or its base's.
  - `blockName`: The block's name.
  - returns: The shared block, or null.
- `capture`: Copies the values as a draw would read them now into a snapshot, for a draw recorded and submitted later.
  - `snapshot`: The snapshot, its bytes and arrays reused.
- `deleteValue`: Removes a uniform's written value, so it reads its base's again (or 0).
  - `uniform`: The uniform.
- `deleteValues`: Removes every written value, texture and share, so everything reads its base's again (or nothing).

## ShaderVariantOptions

*typedef* in [`libs/services/src/helix/services/shaders/ShaderVariantOptions.hx`](../../libs/services/src/helix/services/shaders/ShaderVariantOptions.hx), `import helix.services.shaders.ShaderVariantOptions;`

Represents how a set of variants compiles: `ShaderOptions`, and which combinations of features.

- `shared:Null<Array<ShaderSharedBlock>>`: The blocks whose values are shared (`ShaderBlockValues`): a block the shader declares, or loose uniforms gathered into one. Optional; none by default. A values drawn while a shared block is shared neither on it nor on its base throws, so a frame's data is never silently 0, and a typed values class leaves a shared block's members out (`ShaderValueClasses.buildBlock` makes the block's own).
- `points:Null<Bool>`: Whether the compiler wraps the vertex stage so it writes a point size of 1 after the stage's own `main`, whatever the stage wrote, so a pipeline may draw it as points (`ShaderPipelineState.primitive` `Points`, which the platform refuses over any other shader). Optional; false by default.
- `includes:Null<String>`: A class whose static `String` constants (`static inline final` or `static final` with a constant value) are texts an angle-bracket `#include` takes by the constant's name: `#include <common>` takes `common`. It is named as Haxe names it from the call's file: `ShaderChunk`, `three.ShaderChunk`, or `three.Chunks.Standard` for a type in another type's module. Optional; none by default. An included text may include others. They are looked in before the build's class paths.
- `includeDirectories:Null<Array<String>>`: Directories a quoted `#include` looks in after the including file's own, relative to the file holding the call. Optional; none by default.
- `file:Null<String>`: The asset path of a file holding the compiled shader (`shaders/lit.shader`), which `Shaders.watch` watches, so the shader is replaced in place when the file changes. Optional; no file by default.
- `defines:Null<Array<String>>`: Names defined in both stages, each `NAME` (defined as 1) or `NAME=VALUE`. Optional; none by default. Each stage also has its own: `HELIX_VERTEX` in the vertex stage, `HELIX_FRAGMENT` in the fragment stage, so a file both include tells them apart.
- `combinations:Null<Array<Array<String>>>`: The combinations to compile, each a list of features (`[]` for none on). Optional; omitted, every combination of the features is compiled, at most 8 features (256 variants), and a larger set must give its combinations.
- `clipScale:Null<Bool>`: Whether the compiler wraps the vertex stage so a draw into a render target is turned the right way up whatever the shader writes: it declares a loose `vec4 helix_clipScale` and multiplies `gl_Position` by it, component by component, after the stage's own `main`. Optional; false by default. A pipeline flips it with `flip: ClipScale, flipUniform: "helix_clipScale"` (`ShaderPipelineState.CLIP_SCALE`): a layer whose users write their own vertex stages (helix-raylib) needs no named matrix.
- `check:Null<String>`: A static function `Shader->Null<String>`, by its dotted path (`helix.draw.ShaderRules.check`), run on the compiled shader while the program builds: it returns why the shader breaks a library's rules, which stops the build at the call, or null. Optional; no check by default.

## ShaderVariantValues

*class* in [`libs/services/src/helix/services/shaders/ShaderVariantValues.hx`](../../libs/services/src/helix/services/shaders/ShaderVariantValues.hx), `import helix.services.shaders.ShaderVariantValues;`, extends `ShaderUniformValues`, implements `IShaderValues`

Represents values for every variant of a set at once, as a material's: written once, and packed for each variant a draw uses.

`getValues` makes the values for a variant the first time a draw asks, from everything written so far, over the variant's values of the base when there is one (its unwritten blocks the base's by reference, as `ShaderValues` has them), and keeps them; each value written after is written to every variant's values made, each handle resolved once per variant. A handle the variant doesn't declare (a skinned variant's `boneMatrices` on a plain one) is kept and skipped. Nothing is copied by name when a draw switches between variants. A typed class (`ShaderValueClasses.buildVariants`) returns its own typed values for each variant, so a draw's own uniforms keep their types.

A draw's own uniforms (the model's matrix, its bones) go on a draw values over the variant's values (`ShaderValues.base`), never on the material's: a material-wide write then can't reach them.

```haxe
var defaults = new ShaderVariantValues(lit);
var red = new ShaderVariantValues(lit, defaults);
red.writeColor(lit.getUniform("baseColor"), 0xffd04040);
drawn.base = red.getValues(skinned);         // the renderer's draw values for the skinned variant
drawn.writeMatrix(model, transform);
```

```haxe
function new(variants:ShaderVariants, ?base:ShaderVariantValues)
final variants:ShaderVariants
final base:Null<ShaderVariantValues>
var scene(get, set):Null<ShaderScene>
function getValues(features:ShaderFeatures):ShaderValues
function getShaderValues(shader:Shader):ShaderValues
function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void
function writeSamplerValue(sampler:ShaderSampler, value:ShaderValue):Void
function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void
function unshareTexture(sampler:ShaderSampler):Void
function shareBlock(block:ShaderBlockValues):Void
function unshareBlock(blockName:String):Void
function findSharedBlock(blockName:String):Null<ShaderBlockValues>
function deleteValues():Void
```

- `new`: Creates values for every variant of a set.
  - `variants`: The set.
  - `base`: Optional. Values of the same set to read what these don't write or share from, as a scene's defaults.
  - throws `String`: A base of another set.
- `variants`: Gets the variants these are values for.
- `base`: Gets the values these read what they haven't written or shared from, variant by variant, or null.
- `scene`: Gets or sets the scene every variant's values read shared blocks and textures from when neither they nor their base share them, or null for their base's. Changing it copies nothing.
- `getValues`: Returns the values for the variant with a combination of features, made the first time and kept in step after.
  - `features`: The combination.
  - returns: Its values, the same each call; a typed class's own typed values.
  - throws `String`: A combination not compiled.
- `getShaderValues`: Returns the values for one variant, made the first time and kept in step after.
  - `shader`: A variant of the set (`ShaderVariants.getShader`).
  - returns: Its values, the same each call.
  - throws `String`: A shader that isn't one of the set's.
- `writeTexture`: Writes the texture a sampler reads, and how, in every variant that samples it.
  - `sampler`: The sampler.
  - `texture`: The texture, as an `IGraphics` handle, or 0 for none.
  - `sampling`: Optional. How it is sampled; defaults to `Sampling.LINEAR`.
- `writeSamplerValue`: Writes a sampler from a value held as data (`ShaderValue.Texture`).
  - `sampler`: The sampler.
  - `value`: A `ShaderValue.Texture`.
  - throws `String`: A value of another case.
- `shareTexture`: Makes a sampler read a shared texture in every variant that samples it.
  - `sampler`: The sampler.
  - `shared`: The shared texture.
- `unshareTexture`: Stops a sampler reading a shared texture in every variant.
  - `sampler`: The sampler.
- `shareBlock`: Shares a block on every variant's values, made and to be made, replacing one of that name shared before.
  - `block`: The shared block.
  - throws `String`: A set none of whose variants names the block shared.
- `unshareBlock`: Stops sharing a block of a name on every variant's values.
  - `blockName`: The block's name.
- `findSharedBlock`: Returns the shared block a block of a name reads now: its own, or its base's.
  - `blockName`: The block's name.
  - returns: The shared block, or null.
- `deleteValues`: Removes every written value, texture and share, in every variant, so everything reads its base's again.

## ShaderVariants

*class* in [`libs/services/src/helix/services/shaders/ShaderVariants.hx`](../../libs/services/src/helix/services/shaders/ShaderVariants.hx), `import helix.services.shaders.ShaderVariants;`, implements `IShaderHandles`

Represents one shader compiled once for each combination of features while the program builds, and found by its features.

A feature is a define a variant has on or off (`USE_MAP`, `SKINNED`): a name alone, defined as 1 when on. A value that differs between variants is a feature's business in the GLSL (`#ifdef MANY_LIGHTS`), so no two spellings of one feature exist. A feature's own uniforms are loose uniforms under its `#ifdef`, in either form of stage (`Shader`). The combinations are fixed by the build: `getShader` throws for one not compiled, naming it; `findShader` returns null.

A shared block (`ShaderOptions.shared`) is laid out alike in every variant that declares it, which the build checks, refusing a feature that changes it: one `ShaderBlockValues` serves every variant.

Each variant is a shader of its own, carried whole in the program, its size the size of its dialects: every combination of n features is 2^n of them, compiled when `ShaderVariantOptions.combinations` is omitted, at most 8 features. A library keeps them few by compiling only the combinations it draws with, and by making what doesn't change a stage's inputs a uniform.

```haxe
var lit = ShaderVariants.compile("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], {combinations: [[], ["SKINNED"], ["INSTANCED"]]});
var skinned = lit.getShader(lit.getFeature("SKINNED"));
```

A class `ShaderValueClasses.buildVariants` makes holds the features as constants (`LitValues.SKINNED`), so the compiler checks them. With `ShaderOptions.file`, `Shaders.watchVariants` replaces each variant in place when the file changes.

```haxe
function new(featureNames:Array<String>, variantFeatures:Array<ShaderFeatures>, shaders:Array<Shader>, ?filePath:String)
static macro function compile(vertex:String, fragment:String, features:Array<String>, ?options:ShaderVariantOptions):ShaderVariants
static macro function compileText(vertex:String, fragment:String, features:Array<String>, ?options:ShaderVariantOptions):ShaderVariants
final featureNames:Array<String>
final shaders:Array<Shader>
final variantFeatures:Array<ShaderFeatures>
var uniforms(get, never):Array<ShaderUniform>
var samplers(get, never):Array<ShaderSampler>
final filePath:Null<String>
var reloadError(default, null):Null<String>
var reloadCount(default, null):Int
final reloadListeners:Array<ShaderVariants -> Void>
function getFeature(name:String):ShaderFeatures
function getFeatures(names:Array<String>):ShaderFeatures
function computeFeatureNames(features:ShaderFeatures):Array<String>
function hasUniform(name:String):Bool
function hasSharedBlock(blockName:String):Bool
function reserveUniform(name:String):ShaderUniform
function reserveUniformPath(path:String):ShaderUniformPath
function reserveSampler(name:String):ShaderSampler
function getAttribute(name:String):ShaderAttribute
function findAttribute(name:String):Null<ShaderAttribute>
function hasSampler(name:String):Bool
function getShader(features:ShaderFeatures):Shader
function findShader(features:ShaderFeatures):Null<Shader>
function getUniform(name:String):ShaderUniform
function findUniform(name:String):Null<ShaderUniform>
function getUniformPath(path:String):ShaderUniformPath
function findUniformPath(path:String):Null<ShaderUniformPath>
function getSampler(name:String):ShaderSampler
function findSampler(name:String):Null<ShaderSampler>
```

- `new`: Creates variants from shaders compiled with the features given, as the macros do.
  - `featureNames`: The features, in bit order.
  - `variantFeatures`: Each shader's features.
  - `shaders`: The shaders, by the same index.
  - `filePath`: Optional. The asset path of their file.
  - throws `String`: Arrays of different lengths, or one combination given twice.
- `compile`: Compiles a vertex and a fragment stage once for each combination of features while the program builds, and returns the variants as a value in the program.
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `features`: The features, each a name, bit i of a `ShaderFeatures` the i-th: a constant array at the call or a class's static constant, as the options.
  - `options`: Optional. The combinations, the defines every variant has, includes, shared blocks, a check, and a file: a constant object, at the call or a class's static constant (`Lit.OPTIONS`), so the combinations live in one place.
  - returns: The variants.

  Each variant compiles as `Shader.compile` does, with its features defined and the options' defines.
- `compileText`: Compiles stages from GLSL text known while the program builds once for each combination of features, and returns the variants.
  - `vertex`: The vertex stage's GLSL.
  - `fragment`: The fragment stage's GLSL.
  - `features`: The features, each a name.
  - `options`: Optional. The combinations, defines, includes, shared blocks, a check, and a file.
  - returns: The variants.

  Each stage's text is as `Shader.compileText` takes it.
- `featureNames`: Gets the features, in order: feature i is bit i of a `ShaderFeatures`.
- `shaders`: Gets the variants compiled, in the order of `variantFeatures`.
- `variantFeatures`: Gets each variant's features, by its index in `shaders`.
- `uniforms`: Gets every uniform's handle any variant declares, each name once.
- `samplers`: Gets every sampled texture's handle any variant declares, each name once.
- `filePath`: Gets the asset path of the variants' file (`ShaderOptions.file`), which `Shaders.watchVariants` watches, or null. It is set whatever the build.
- `reloadError`: Gets why the last change of the variants' file wasn't taken (another set of features, a file that doesn't read), or null.
- `reloadCount`: Gets the number of times a change of the variants' file has replaced them in place, each variant's `reloadCount` moving with it.
- `reloadListeners`: Gets the functions called after each replacement of the variants in place, once every variant, handle and values has followed, in the order added. Each variant's own `Shader.reloadListeners` are called too.
- `getFeature`: Returns a feature by name, as a set of one.
  - `name`: The feature.
  - returns: The set holding it.
  - throws `String`: A name that isn't one of the features.
- `getFeatures`: Returns a combination from its features' names, as data or a by-name layer holds it.
  - `names`: The features' names, in any order.
  - returns: The combination.
  - throws `String`: A name that isn't one of the features.
- `computeFeatureNames`: Returns the names of a combination's features, in bit order, as messages and logs show a combination (`computeFeatureNames(skinned | instanced)` is `["SKINNED", "INSTANCED"]`); `variantFeatures` lists the combinations compiled.
  - `features`: The combination.
  - returns: Its features' names.
- `hasUniform`: Returns whether any variant declares a uniform.
  - `name`: Its path.
  - returns: True when one does.
- `hasSharedBlock`: Returns whether any variant names a shared block.
  - `blockName`: The block's name.
  - returns: True when one does.
- `reserveUniform`: Returns a handle for a uniform no variant may declare until a replacement, binding when one does (`Shader.reserveUniform`).
  - `name`: Its path.
  - returns: The handle, the same each call.
- `reserveUniformPath`: Returns a uniform and element for a bracketed path no variant may declare until a replacement (`Shader.reserveUniformPath`).
  - `path`: The path.
  - returns: The uniform and the element.
- `reserveSampler`: Returns a handle for a texture no variant may sample until a replacement, binding when one does.
  - `name`: Its GLSL name.
  - returns: The handle, the same each call.
- `getAttribute`: Returns a vertex attribute, the first variant's that reads it.
  - `name`: Its GLSL name.
  - returns: The attribute.
  - throws `String`: A name no variant reads.
- `findAttribute`: Finds a vertex attribute no variant may read.
  - `name`: Its GLSL name.
  - returns: The attribute, or null.
- `hasSampler`: Returns whether any variant samples a texture.
  - `name`: Its GLSL name.
  - returns: True when one does.
- `getShader`: Returns the variant with exactly a combination of features.
  - `features`: The combination.
  - returns: The variant.
  - throws `String`: A combination not compiled, naming its features.
- `findShader`: Finds the variant with exactly a combination of features, which may not have been compiled.
  - `features`: The combination.
  - returns: The variant, or null.
- `getUniform`: Returns the handle of a uniform any variant declares, which works on every variant's values.
  - `name`: Its path, or the name `Shader.withNames` gave it.
  - returns: The handle, the same each call.
  - throws `String`: A name no variant declares; given `lights[0].position`, it names `lights.position` and `getUniformPath`.
- `findUniform`: Finds the handle of a uniform that no variant may declare.
  - `name`: Its path.
  - returns: The handle, or null.
- `getUniformPath`: Returns a uniform and element from a path as GLSL writes it, with brackets or without, from any variant.
  - `path`: The path.
  - returns: The uniform and the element, the same object for the same path.
  - throws `String`: A path whose uniform no variant declares, or an index past its elements.
- `findUniformPath`: Finds a uniform and element from a path no variant may declare.
  - `path`: The path.
  - returns: The uniform and the element, or null: for a uniform no variant declares, an index past its elements, or a path naming a struct or a struct's element rather than a field.
- `getSampler`: Returns the handle of a texture any variant samples, which works on every variant's values.
  - `name`: Its GLSL name.
  - returns: The handle, the same each call.
  - throws `String`: A name no variant declares.
- `findSampler`: Finds the handle of a texture no variant may sample.
  - `name`: Its GLSL name.
  - returns: The handle, or null.

## ShaderVertexConstant

*typedef* in [`libs/services/src/helix/services/shaders/ShaderVertexConstant.hx`](../../libs/services/src/helix/services/shaders/ShaderVertexConstant.hx), `import helix.services.shaders.ShaderVertexConstant;`

Represents the value an attribute reads when no buffer feeds it, as raylib's `rlSetVertexAttributeDefault` sets one (a vertex color white): the same for every vertex.

- `values:Array<Float>`: The value's components, up to four; the rest are 0, 0, 1 as GL's default (0, 0, 0, 1) has them. A matrix attribute takes four a column, column by column (16 for a `mat4`): past four, each four are the next slot's.
- `slot:Null<Int>`: The attribute's slot. Optional; one of `name` and `slot` is given.
- `name:Null<String>`: The attribute's name. Optional; one of `name` and `slot` is given.

## ShaderVertexLayout

*class* in [`libs/services/src/helix/services/shaders/ShaderVertexLayout.hx`](../../libs/services/src/helix/services/shaders/ShaderVertexLayout.hx), `import helix.services.shaders.ShaderVertexLayout;`

Represents how a mesh's vertex buffers hold its attributes, by name, for any shader drawing it: each buffer's stride, whether it steps per instance, and where each attribute is; and what an attribute no buffer feeds reads.

It is made once, for a kind of mesh, and handed to `ShaderPrograms.getPipeline`, which resolves it for each shader (slots, a matrix a slot a column) once, again after a replacement, and keeps the result: nothing is made per draw. An attribute a shader reads that no buffer feeds reads its constant, or (0, 0, 0, 1) when the layout gives none (platform proposal 8); a constant for an attribute the shader doesn't read is skipped. A buffer none of whose placements the shader reads is a gap: the pipeline reads nothing from it, and a draw may pass 0 for it. An attribute is floats unless its placement gives another `VertexFormat`: a normal as four signed bytes, the weights as four unsigned shorts, below.

```haxe
var skinnedMesh = new ShaderVertexLayout([{stride: 40, placements: [
{name: "position", offset: 0}, {name: "normal", offset: 12, format: Byte4Norm, optional: true},
{name: "joints", offset: 16, optional: true}, {name: "weights", offset: 32, format: UShort4Norm, optional: true}
]}], [{name: "color", values: [1, 1, 1, 1]}]);
```

```haxe
function new(buffers:Array<{stride:Int, placements:Array<ShaderVertexPlacement>, instanced:Null<Bool>}>, ?constants:Array<ShaderVertexConstant>)
static function fromAttributes(source:IShaderHandles, names:Array<String>, ?instanced:Bool = false):ShaderVertexLayout
final buffers:Array<{stride:Int, placements:Array<ShaderVertexPlacement>, instanced:Null<Bool>}>
final constants:Array<ShaderVertexConstant>
function computeBuffers(shader:Shader):Array<VertexBuffer>
```

- `new`: Creates a layout.
  - `buffers`: Each buffer's stride in bytes, whether it steps per instance (false when omitted), and its placements.
  - `constants`: Optional. What attributes no buffer feeds read; none by default.
- `fromAttributes`: Returns a one-buffer layout packing some attributes as floats in the order given, as `Shader.computeVertexBuffer` packs them, for a buffer a program fills (a sprite batch's): from a shader, or from a set, whose variants share the attributes' types.
  - `source`: The shader or variants declaring the attributes.
  - `names`: The attributes, in their order in a record.
  - `instanced`: Optional. Whether the buffer steps once an instance; defaults to false.
  - returns: The layout: its stride the sum of the attributes' sizes.
  - throws `String`: A name nothing declares, or an integer attribute.
- `buffers`: Gets the buffers, by their index in a draw's buffers.
- `constants`: Gets the values attributes no buffer feeds read.
- `computeBuffers`: Returns the layout as one shader reads it, in the platform's form: placements the shader doesn't read left out, a matrix a `VertexAttribute` a column.
  - `shader`: The shader.
  - returns: The buffers' layouts, as `PipelineDesc.buffers` holds them.
  - throws `String`: A placement the shader doesn't read and isn't `optional`, an integer attribute, or one that runs past its stride.

## ShaderVertexPlacement

*typedef* in [`libs/services/src/helix/services/shaders/ShaderVertexPlacement.hx`](../../libs/services/src/helix/services/shaders/ShaderVertexPlacement.hx), `import helix.services.shaders.ShaderVertexPlacement;`

Represents where an attribute is in a vertex buffer's records, at a byte offset: by name, or by slot for a layer that numbers attributes as GL does (raylib's `rlSetVertexAttribute`).

- `slot:Null<Int>`: The attribute's slot, its `layout(location = n)`, for a shader whose slots the layer fixes. Optional; one of `name` and `slot` is given.
- `optional:Null<Bool>`: Whether a shader may leave it unread, as an unlit shader leaves a mesh's normals, unread meaning not declared or declared and not read alike; its bytes are then skipped. Optional; false by default, and an undeclared placement not marked so is refused.
- `offset:Int`: Its byte offset in a record.
- `name:Null<String>`: The attribute's name: its GLSL name, or the name `Shader.withNames` gave it. Optional; one of `name` and `slot` is given.
- `format:Null<VertexFormat>`: How a record holds it (`VertexFormat`): floats, half floats, or normalized integers read as floats. A format of fewer components than the attribute takes reads the rest as 0, 0, 1 as (0, 0, 0, 1) has them (a `Float3` position fed into a `vec4` input reads w 1, as GL feeds it); one of more reads the first ones (a `Byte4Norm` normal into a `vec3`). A matrix takes it for each column, each column its `bytes` after the last. Optional; the attribute's own floats when omitted (`Float3` for a `vec3`, a `Float4` a column for a `mat4`).

## Shaders

*class* in [`libs/services/src/helix/services/shaders/Shaders.hx`](../../libs/services/src/helix/services/shaders/Shaders.hx), `import helix.services.shaders.Shaders;`

Provides shaders replaced in place when their files change, and shaders that are only files, through the assets.

A shader compiled into the program with `ShaderOptions.file` is watched (`watch`): each time the assets are told its file changed (`Assets.notifyChanged`), the new file replaces it in place. Nothing is compiled while the program runs: the build compiled the file. A program that is only given shaders as files (a mod's) loads them (`load`) and they are watched alike.

A replacement changes the shader's `source` and reflection and moves its `reloadCount`. Its handles and every `ShaderValues` made for it follow on their own. What was built on the GPU from it is its holder's: comparing `reloadCount` with the count it built at, the holder disposes its program (and the pipelines made with it, which `IGraphics.disposeShader` disposes) and builds again, as `ShaderPrograms` does. A file that no longer reads, or holds a shader of another kind (one shader where variants were, or other features), leaves the shader as it was: its `reloadError` says why, and the log says so with the path.

**Who wires it.** Nothing watches files on its own. The program wires its hot reloader to the assets, one line in a page's development build with hotreload-hx: `reloader.assetsChanged = urls -> for (url in urls) assets.notifyUrlChanged(url);`. Nothing is polled beyond the assets' adapters (the HTTP client and file systems the program already polls each frame): this has no `poll`.

**A release build** needs no conditional. hotreload-hx's `Reloader` does nothing outside a hot JS build (`-D hotreload`), on any target, so the line above compiles in a release build and links only that empty class; a program not using hotreload-hx exports a plain function the page's own development script calls with the changed paths. A release build writes no file and tells the assets of nothing, so a watch waits and costs nothing.

**When a replacement happens.** A changed file is read when the assets bring it, and held: it replaces its shader at the next `prepareFrame`, which the program, or the renderer it draws through, calls at the frame's start, before `ShaderPrograms.prepareFrame` and before any values are written for the frame. So nothing changes in the middle of a frame: values repack, handles move and pipelines are rebuilt at the same boundary. Then the shader's reload listeners (`Shader.reloadListeners`) are called; nothing need poll `reloadCount`. helix-draw and helix-raylib call both `prepareFrame`s inside their own frames.

```haxe
var shaders = new Shaders(assets);
var glow = Shader.compile("quad.vert", "glow.frag", {file: "shaders/glow.shader"});
shaders.watch(glow);
```

```haxe
function new(assets:Assets)
function prepareFrame():Void
function watch(shader:Shader):() -> Void
function watchVariants(variants:ShaderVariants):() -> Void
function load(path:String, loaded:Shader -> Void, ?failed:String -> Void):() -> Void
function loadVariants(path:String, loaded:ShaderVariants -> Void, ?failed:String -> Void):() -> Void
```

- `new`: Creates the shaders over the assets their files are read through.
  - `assets`: The assets.
- `prepareFrame`: Applies, at a frame's start, every replacement whose file has arrived since the last call, and calls their reload listeners. Before `ShaderPrograms.prepareFrame`, and before the frame's values are written.
- `watch`: Replaces a shader in place each time its file changes (at the `prepareFrame` after it arrives), until the returned function is called.
  - `shader`: A shader compiled with `ShaderOptions.file`.
  - returns: A function that stops watching it, the same for every call with the same shader (watching twice is watching once).
  - throws `String`: A shader compiled without `ShaderOptions.file` (`filePath` null), whatever the build.
- `watchVariants`: Replaces each variant in place each time their file changes, until the returned function is called.
  - `variants`: Variants compiled with `ShaderOptions.file`.
  - returns: A function that stops watching them, the same for every call with the same variants.
  - throws `String`: Variants compiled without `ShaderOptions.file`, whatever the build.
- `load`: Loads a shader that is only a file, written by a build's `ShaderOptions.file`, and watches it.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the shader.
  - `failed`: Optional. Receives why it couldn't be loaded or read. When omitted, the failure is logged.
  - returns: A function that aborts the load and stops watching; nothing is called after it.

  One of `loaded` or `failed` is called once, at a later `poll` of the assets, never during this call.
- `loadVariants`: Loads variants that are only a file, and watches them.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the variants.
  - `failed`: Optional. Receives why they couldn't be loaded or read. When omitted, the failure is logged.
  - returns: A function that aborts the load and stops watching; nothing is called after it.

  One of `loaded` or `failed` is called once, at a later `poll` of the assets, never during this call.
