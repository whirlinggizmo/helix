# helix.services.tools

[Back to the index](README.md)

## AssetManifests

*class* in [`services/src/helix/services/tools/AssetManifests.hx`](../../services/src/helix/services/tools/AssetManifests.hx), `import helix.services.tools.AssetManifests;`

Provides a build-time macro that writes the manifests `Assets` reads.

Each directory of a tree gets a manifest listing the hash of each file in it and of each subdirectory's own manifest. An unchanged directory is then known from its parent's manifest alone.

Call `write` once in the program, over the directory its files ship in and its server serves. It runs while the program builds. A manifest is rewritten only when what it lists changed. A file is hashed again only when its size or modification time changed since the last run. Those are kept in a hidden file beside the directory, such as `.assets.manifests` for `assets`. Hidden files, and names `IFileSystem` refuses, are skipped.

```haxe
AssetManifests.write("assets");
```

```haxe
static macro function write(directory:String, name:String = "manifest.json"):Void
```

- `write`: Writes the manifests of a directory and every directory under it, while the program builds.
  - `directory`: The tree's root, relative to where the build runs.
  - `name`: Optional. Each manifest's file name, which matches `AssetsOptions.manifestName`. Defaults to "manifest.json".

  The build fails when the path isn't a directory.

## ShaderBlockCompiler

*class* in [`services/src/helix/services/tools/ShaderBlockCompiler.hx`](../../services/src/helix/services/tools/ShaderBlockCompiler.hx), `import helix.services.tools.ShaderBlockCompiler;`

Provides build-time macros making a shared block's values from its declaration alone, so no shader that shares it is needed to make it (a renderer's camera before any material is loaded). They live here, apart from `ShaderBlockValues`, so typing them never types the values classes in the macro context (`Shader`'s note on macros).

```haxe
static macro function compile(file:String, blockName:String, ?uniforms:Array<String>):ShaderBlockValues
static macro function compileText(text:String, blockName:String, ?uniforms:Array<String>):ShaderBlockValues
```

- `compile`: Makes values for a shared block from its declaration alone, a file the shaders that share it include, compiled while the program builds, so no shader that shares it is needed to make it (a renderer's camera before any material is loaded).
  - `file`: The GLSL file declaring the block (a named `uniform` block, or the loose uniforms `uniforms` names), relative to the file holding the call.
  - `blockName`: The block's name.
  - `uniforms`: Optional. Loose uniforms in the file gathered into the block, as `ShaderSharedBlock.uniforms`.
  - returns: New values for the block, every member 0: each evaluation makes a new one.

  ```haxe
  var camera = ShaderBlockCompiler.compile("camera.glsl", "Camera");
  ```
- `compileText`: Makes values for a shared block from its declaration as GLSL text known while the program builds, as `Shader.compileText` takes text (a literal, or a class's string constant), so a library keeping its GLSL in constants needs no file.
  - `text`: The GLSL declaring the block.
  - `blockName`: The block's name.
  - `uniforms`: Optional. Loose uniforms in the text gathered into the block.
  - returns: New values for the block, every member 0.

## ShaderValueClasses

*class* in [`services/src/helix/services/tools/ShaderValueClasses.hx`](../../services/src/helix/services/tools/ShaderValueClasses.hx), `import helix.services.tools.ShaderValueClasses;`

Provides the build macros that make typed values classes, as sokol-shdc's generated structs are: a member for each uniform and texture, checked by the compiler, each holding its handle, so nothing is looked up by name.

**Members.** For each uniform a class gains members named for its path, the parts joined in camel case (`material.roughness` as `MaterialRoughness`, `lights.color` as `LightsColor`). A member of a block with no instance name is named alone (`uniform Glow { vec4 tint; };` gives `Tint`); with one, the instance name leads (`... } glow;` gives `GlowTint`). Loose uniforms are named alone.

- A scalar (`float`, `int`, `uint`, `bool`): `setX(value)`. - A vector: `setX(x, y, ...)` with its components. A `vec3` or `vec4` whose name holds `color`, `colour` or `tint` (any case) also gets `setXArgb(color)` from 0xAARRGGBB as stored and `setXLinearArgb(color)` decoded to linear light (`writeLinearColor`), and no other vector does: a position has no color form. - A matrix: `setX(matrix)` for a `mat4`, `setX(values)` with its floats by columns for a `mat2` or `mat3`. - An array, or a field of an array of structs: the same, the element's index first (`setLightsRange(i, 10)`). - A texture: `setX(texture, ?sampling)` and `shareX(shared)` for a `ShaderSharedTexture`.

Every generated member starts with `set` or `share`, and nothing of the values classes does but `shareBlock`, `shareTexture` and their `unshare` forms (their handle methods are `write`), so any uniform's name works (`color`, `matrix`, `texture`); a texture named `block` or `texture` (`shareBlock`, `shareTexture`) fails the build, as do two uniforms whose members would share a name. A uniform of a shared block (`ShaderOptions.shared`) gets no member on a shader's or a material's class: it is written once on the block's own class (`buildBlock`).

**Statics.** A class gains its compiled `SHADER` or `VARIANTS` and a `ShaderFeatures` constant for each feature, named for it (`SKINNED`); a feature named `SHADER` or `VARIANTS` fails the build. These are the compiled program, a constant as a literal is; nothing a program writes is static. Defaults are values the program makes and passes (`base`), so two renderers have their own.

**Binding.** A class is bound to any shader of its program, the compiled-in one by default, or one replaced in place or loaded from the same files (checked at construction: the shader declares what the class was generated for, with the same types), and follows a replacement as `ShaderValues` does. The same files and options compile once a build, so every class over them shares one `SHADER` or `VARIANTS`.

**The exact shape**, for a class `X` (members as above, each with a doc comment naming its GLSL declaration and, for variants, the variants that have it):

| Macro, base class | Statics | Constructor | Overrides | |---|---|---|---| | `build`, `ShaderValues` | `SHADER:Shader` | `new(?base:ShaderValues, ?scene:ShaderScene, ?shader:Shader)` | none | | `buildVariants`, `ShaderValues` | `VARIANTS:ShaderVariants`, a `ShaderFeatures` per feature | `new(features:ShaderFeatures, ?base:ShaderValues, ?scene:ShaderScene)` | none | | `buildVariants`, `ShaderVariantValues` | as above | `new(?base:X, ?scene:ShaderScene)` | `getValues(features):V` and `makeValues(shader, base):ShaderValues`, `V` the `values` class | | `buildBlock`, `ShaderBlockValues` | none | `new()` | none |

A material class (`ShaderVariantValues`) has the texture members (`setX`, `shareX`) as well as the uniforms', each writing every variant that samples it.

```haxe
static macro function build(vertex:String, fragment:String, ?options:ShaderOptions):Array<Field>
static macro function buildVariants(vertex:String, fragment:String, features:Array<String>, ?options:ShaderVariantOptions, ?values:String):Array<Field>
static macro function buildBlock(source:String, blockName:String):Array<Field>
```

- `build`: Makes the class it builds, extending `ShaderValues`, a class of typed values for one shader, compiled as `Shader.compile` compiles.
  - `vertex`: The vertex stage's file, relative to the file holding the class.
  - `fragment`: The fragment stage's file, relative to the file holding the class.
  - `options`: Optional. Defines, includes, shared blocks, a check, and a file, as `Shader.compile` takes them, at the call or a class's static constant.
  - returns: The class's fields with the generated ones.

  The class gains `SHADER` and a constructor `new(?base, ?scene, ?shader)`: the values it reads what it doesn't write from, the scene, and the shader, `SHADER` when omitted.

  ```haxe
  @:build(helix.services.tools.ShaderValueClasses.build("glow.vert", "glow.frag", {file: "shaders/glow.shader"}))
  class GlowValues extends ShaderValues {}

  shaders.watch(GlowValues.SHADER);
  var defaults = new GlowValues();
  defaults.setStrength(1);
  var glow = new GlowValues(defaults, scene);
  glow.setTintArgb(0xffffc040);
  glow.setImage(texture);
  ```
- `buildVariants`: Makes the class it builds a class of typed values for a set of variants, compiled as `ShaderVariants.compile` compiles: a member for every uniform and texture any variant has, each member's doc naming the variants that have it.
  - `vertex`: The vertex stage's file, relative to the file holding the class.
  - `fragment`: The fragment stage's file, relative to the file holding the class.
  - `features`: The features, each a name, at the call or a class's static constant.
  - `options`: Optional. The combinations, defines, includes, shared blocks, a check, and a file, at the call or a class's static constant.
  - `values`: Optional. For a `ShaderVariantValues` class, the typed class of one variant's values (built over the same files and features) that `getValues` returns; `ShaderValues` when omitted.
  - returns: The class's fields with the generated ones.

  What it gains besides `VARIANTS` and the feature constants depends on what it extends:

  - `ShaderValues`: values for one variant, and a constructor `new(features, ?base, ?scene)`. - `ShaderVariantValues`: one material's values across every variant, and a constructor `new(?base, ?scene)`. Its `getValues(features)` returns the class named by `values`, typed values for one variant, so a draw's own uniforms keep their types.

  On values for a variant without a member, the member keeps the value and writes nothing, as a handle does.

  ```haxe
  @:build(helix.services.tools.ShaderValueClasses.buildVariants("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], Lit.OPTIONS))
  class LitValues extends ShaderValues {}

  @:build(helix.services.tools.ShaderValueClasses.buildVariants("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], Lit.OPTIONS,
  "LitValues"))
  class LitMaterial extends ShaderVariantValues {}

  var red = new LitMaterial(sceneDefaults);
  red.setBaseColorArgb(0xffd04040);
  var drawn = new LitValues(LitMaterial.SKINNED);   // the renderer's draw values for the variant
  drawn.base = red.getValues(LitMaterial.SKINNED);  // a LitValues, typed
  drawn.setModel(transform);
  ```
- `buildBlock`: Makes the class it builds, extending `ShaderBlockValues`, a class of typed values for one shared block, as a shader or a set of variants names it shared.
  - `source`: A static field holding a `Shader` or `ShaderVariants` compiled by one of the macros, by its dotted path from the file holding the class (`LitMaterial.VARIANTS`, `Lighting.SHADER`).
  - `blockName`: The shared block's name.
  - returns: The class's fields with the generated ones.

  The class gains a member for each of the block's uniforms, named as above, and a constructor taking nothing, over the block as the shader or set given lays it out. It follows the block's layout as `ShaderBlockValues` does.

  ```haxe
  @:build(helix.services.tools.ShaderValueClasses.buildBlock("LitMaterial.VARIANTS", "Camera"))
  class CameraValues extends ShaderBlockValues {}

  var camera = new CameraValues();          // each renderer its own
  scene.shareBlock(camera);
  // each frame, once:
  camera.setViewProjection(viewProjection);
  ```
