# Raylib6

[Back to the library](README.md)


```haxe
static function UpdateModelAnimationEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void
```

- `UpdateModelAnimationEx`: Poses a model by two animations mixed by a blend, raylib 6.0's `UpdateModelAnimationEx`.
  - `model`: The model.
  - `animA`: The first animation.
  - `frameA`: Its frame, fractional.
  - `animB`: The second animation.
  - `frameB`: Its frame, fractional.
  - `blend`: How much of the second: 0 the first alone, 1 the second alone.

  Takes each animation at its frame as `UpdateModelAnimation` takes one, then mixes the two by the blend.

  Moves the bones and the vertices on the GPU or the CPU as `UpdateModelAnimation` does.

  Wraps a frame to its animation's frames before taking its fraction, as raylib's does, so a frame past the last holds the frame it wrapped to.

  Does nothing for a blend outside 0 to 1.
