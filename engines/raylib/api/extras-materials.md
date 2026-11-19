# Materials

[Back to the library](README.md)

## Materials

*class* in [`engines/raylib/src/helix/raylib/extras/Materials.hx`](../src/helix/raylib/extras/Materials.hx), `import helix.raylib.extras.Materials;`

Provides what a material emits, where it is cut out, and whether light and shadows fall on it, read by every draw with it: `DrawModel`'s, `DrawMesh`'s and `DrawMeshInstanced`'s, through helix-raylib's default shader and the Lighting extra's lit shaders. Imported apart: `import helix.raylib.extras.Materials.*;`.

A program's own shader reads them as the uniforms `vec3 emissiveColor` (the color times the intensity), `vec3 modelEmissiveColor` (`SetModelEmissive`'s, 0 for a mesh drawn alone) and `float alphaCutoff`, which `<helix/raylib/shaders/lights.glsl>` and `<helix/raylib/shaders/pbr.glsl>` declare.

The example `engines/raylib/examples/extras/materials` uses it.

### materials: what a material emits, where it is cut out, and whether light and shadows fall on it

```haxe
static function SetMaterialAlphaCutoff(material:Material, cutoff:Float):Void
static function GetMaterialAlphaCutoff(material:Material):Float
static function SetMaterialEmissive(material:Material, color:Color, intensity:Float):Void
static function GetMaterialEmissive(material:Material, ?out:Vector3):Vector3
static function SetMaterialUnlit(material:Material, unlit:Bool):Void
static function IsMaterialUnlit(material:Material):Bool
static function SetMaterialShadowed(material:Material, shadowed:Bool):Void
static function IsMaterialShadowed(material:Material):Bool
static function SetModelEmissive(model:Model, color:Color, intensity:Float):Void
```

- `SetMaterialAlphaCutoff`: Sets a material's alpha cutoff: where its albedo's alpha, the albedo map's times its color's, is below the cutoff, the material draws nothing, as a leaf cut from a square does. 0 turns the cutoff off. A glTF material whose `alphaMode` is glTF's `MASK` loads with its `alphaCutoff`, 0.5 when the file sets none.
  - `material`: The material.
  - `cutoff`: The cutoff, 0 to 1.

  Read at each draw by helix-raylib's default shader, which draws exactly as raylib's while the cutoff is 0, and by `LoadPbrShader`'s and `LoadLightingShader`'s draws.
- `GetMaterialAlphaCutoff`: Returns a material's alpha cutoff, as `SetMaterialAlphaCutoff` set it or its glTF file set it: 0 for none.
  - `material`: The material.
  - returns: The cutoff, 0 to 1.
- `SetMaterialEmissive`: Sets the light a material emits whatever lights it: its color times the intensity, added to the lit color, as a glowing lamp. A glTF material loads with its `emissiveFactor`, and the emission map stays in `maps[MATERIAL_MAP_EMISSION]`. Black or an intensity of 0, the default, emits no light. See `SetModelEmissive` for every material of a model at once.
  - `material`: The material.
  - `color`: The color.
  - `intensity`: How strong, 0 or more; 1 adds the color itself.

  Read at each draw by `LoadPbrShader`'s and `LoadLightingShader`'s draws, and by helix-raylib's default shader, which draws exactly as raylib's while the material emits no light.
- `GetMaterialEmissive`: Returns the light a material emits, as `SetMaterialEmissive` set it or its glTF file set it: its color times its intensity, red, green and blue, 0 for none.
  - `material`: The material.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: out, or the new vector.
- `SetMaterialUnlit`: Sets whether a material is unlit: drawn in its albedo, the map's times its color, with no light and no shadow falling on it, as a glowing lamp, a sky or a sign drawn in the world is. A glTF material marked by glTF's `KHR_materials_unlit` loads unlit. Lit until set.
  - `material`: The material.
  - `unlit`: Whether it is unlit.

  Read at each draw by `LoadPbrShader`'s and `LoadLightingShader`'s draws. Its emission is still added.
- `IsMaterialUnlit`: Returns whether a material is unlit, as `SetMaterialUnlit` set it or its glTF file set it.
  - `material`: The material.
  - returns: Whether it is unlit.
- `SetMaterialShadowed`: Sets whether shadows fall on a material: when not, it is lit as if nothing stood between it and each light, as water, a hologram or a decal often is. Shadows fall on every material until set.
  - `material`: The material.
  - `shadowed`: Whether shadows fall on it.

  A program's own shader reads it as the uniform `int shadowed`, 1 or 0, written at each draw.
- `IsMaterialShadowed`: Returns whether shadows fall on a material, as `SetMaterialShadowed` set it: true until set.
  - `material`: The material.
  - returns: Whether shadows fall on it.
- `SetModelEmissive`: Sets light a whole model emits, added to each of its materials' own: a hit flash, or a model glowing whole. Its materials' emission, as `SetMaterialEmissive` set it or the glTF file set it, is kept, so an intensity of 0 leaves the model as authored. Read at each draw of the model (`DrawModel`, `DrawModelEx`), not by a draw of one of its meshes alone.
  - `model`: The model.
  - `color`: The color.
  - `intensity`: How strong, 0 or more; 1 adds the color itself.

  ```haxe
  SetModelEmissive(enemy, WHITE, hitTime > 0 ? 0.8 : 0);
  DrawModel(enemy, position, 1, WHITE);
  ```
