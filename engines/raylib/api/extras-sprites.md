# Sprites

[Back to the library](README.md)

## Sprites

*class* in [`engines/raylib/src/helix/raylib/extras/Sprites.hx`](../src/helix/raylib/extras/Sprites.hx), `import helix.raylib.extras.Sprites;`

Provides helix-raylib's instanced texture draw, `DrawTextureInstanced`: many copies of one part of a texture, each placed by a matrix, in one call, as three.js's InstancedMesh, Godot's MultiMesh and Unity's instancing draw many of one thing (docs/DECISIONS.md 47). Imported apart: `import helix.raylib.extras.Sprites.*;`. The example `engines/raylib/examples/extras/sprites` uses it.

```haxe
var copies = [for (i in 0...100) MatrixMultiply(MatrixRotateZ(i * 0.1), MatrixTranslate(i * 8, 100, 0))];
DrawTextureInstanced(texture, new Rectangle(0, 0, 32, 32), copies, WHITE);
```

### sprites: many copies of one part of a texture, each placed by a matrix, in one call

```haxe
static function DrawTextureInstanced(texture:Texture2D, source:Rectangle, transforms:Array<Matrix>, tint:Color):Void
```

- `DrawTextureInstanced`: Draws one part of a texture many times in one call, each copy placed by its own matrix. See `DrawTexturePro` for drawing a single copy.
  - `texture`: The texture.
  - `source`: The part of it, in pixels.
  - `transforms`: Each copy's matrix.
  - `tint`: The tint, every copy's.

  Each copy is what `DrawTexturePro` draws, in the batch's order, so the copies join the frame's sprite run and cost what the same draws would.

  A copy is the part, `source.width` by `source.height` pixels with its top left at the origin, taken through its matrix as `Vector2Transform` applies one. The fields read are `m0`, `m4` and `m12` across, and `m1`, `m5` and `m13` down.

  `MatrixTranslate` places a copy, `MatrixRotateZ` turns it about its top left and `MatrixScale` sizes it. Their products do all three.

  A negative `source.width` or `source.height` flips the part.

  Nothing is drawn when the texture's id, width or height is 0.
