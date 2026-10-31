# helix.services.screenshots

[Back to the index](README.md)

## Screenshots

*class* in [`services/src/helix/services/screenshots/Screenshots.hx`](../../services/src/helix/services/screenshots/Screenshots.hx), `import helix.services.screenshots.Screenshots;`

Captures frames as images: the next frame that ends is read back from the GPU, for a screenshot or a check.

The program constructs one over its `IGraphics`, and calls `frameEnded` once a frame, between `IGraphics.endFrame` and `present`. A capture waits for the GPU, so the frame it's taken in is slower.

```haxe
var screenshots = new Screenshots(graphics);
screenshots.captureFrame(image -> export.export("shot.png", "image/png", PngFile.write(image.width, image.height, 4, image.pixels), _ -> {},
_ -> {}));
// each frame:
graphics.endFrame();
screenshots.frameEnded();
graphics.present();
```

```haxe
function new(graphics:IGraphics)
function captureFrame(captured:Image -> Void, ?failed:String -> Void):Void
function frameEnded():Void
```

- `new`: Creates the screenshots over the graphics whose frames they read.
  - `graphics`: The graphics.
- `captureFrame`: Captures the next frame that ends as an image, the size of the framebuffer.
  - `captured`: Receives the image.
  - `failed`: Optional. Receives why the frame couldn't be read. When omitted, the failure is logged.

  One of `captured` or `failed` is called once, as that frame ends or later, never during this call.
- `frameEnded`: Reads the frame that just ended for the captures asked for. Call it once a frame, between `IGraphics.endFrame` and `present`.
