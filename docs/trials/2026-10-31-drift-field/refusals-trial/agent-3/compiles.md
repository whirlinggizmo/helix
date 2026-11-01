# Agent 3: every compile, in order, with its whole output

## Compile 1

```
(Bash completed with no output)
```

## Compile 2

```
Probe.hx:4: characters 3-33 : (fileName : String, loaded : (String -> Void), ?failed : Null<String -> Void>) -> Void should be Int
Probe.hx:5: characters 3-28 : (fileName : String) -> Null<String> should be Int
Probe.hx:6: characters 3-28 : (fileName : String, text : String) -> Bool should be Int
Probe.hx:7: characters 3-32 : () -> helix.ray.FilePathList should be Int
Probe.hx:8: characters 3-29 : () -> Bool should be Int
Probe.hx:9: characters 3-27 : (fileName : String) -> helix.ray.Texture2D should be Int
Probe.hx:10: characters 3-25 : (fileName : String) -> helix.ray.Sound should be Int
Probe.hx:11: characters 3-27 : (camera : helix.ray.Camera2D) -> Void should be Int
Probe.hx:12: characters 3-32 : (x : Int, y : Int, width : Int, height : Int) -> Void should be Int
Probe.hx:13: characters 3-38 : (gamepad : Int, axis : Int) -> Float should be Int
Probe.hx:14: characters 3-33 : () -> Float should be Int
Probe.hx:15: characters 15-23 : Unknown identifier : Camera2D
Probe.hx:16: characters 3-32 : (index : Int) -> helix.ray.Vector2 should be Int
Probe.hx:17: characters 3-34 : (position : helix.ray.Vector2, camera : helix.ray.Camera2D) -> helix.ray.Vector2 should be Int
Probe.hx:18: characters 3-30 : (texture : helix.ray.Texture2D, source : helix.ray.Rectangle, dest : helix.ray.Rectangle, origin : helix.ray.Vector2, rotation : Float, tint : helix.ray.Color) -> Void should be Int
Probe.hx:19: characters 3-29 : (seed : Int) -> Void should be Int
Probe.hx:20: characters 3-30 : (min : Int, max : Int) -> Int should be Int
Probe.hx:21: characters 3-31 : () -> Bool should be Int
```

## Compile 3

```
Probe.hx:5: characters 3-32 : helix.ray.Vector2 should be Int
Probe.hx:6: characters 3-30 : helix.ray.Camera2D should be Int
Probe.hx:7: characters 3-38 : helix.ray.Rectangle should be Int
Probe.hx:8: characters 3-34 : helix.ray.Color should be Int
Probe.hx:11: characters 3-23 : Array<String> should be Int
Probe.hx:12: characters 3-34 : (files : helix.ray.FilePathList) -> Void should be Int
Probe.hx:16: characters 3-25 : (sound : helix.ray.Sound) -> Void should be Int
Probe.hx:17: characters 3-38 : (gamepad : Int, button : Int) -> Bool should be Int
Probe.hx:18: characters 3-25 : () -> Int should be Int
Probe.hx:19: characters 3-36 : (button : Int) -> Bool should be Int
Probe.hx:21: characters 3-34 : () -> Int should be Int
Probe.hx:22: characters 3-29 : () -> Int should be Int
Probe.hx:23: characters 3-28 : () -> Float should be Int
Probe.hx:24: characters 3-27 : (text : String, fontSize : Int) -> Int should be Int
Probe.hx:25: characters 3-36 : (rec : helix.ray.Rectangle, lineThick : Float, color : helix.ray.Color) -> Void should be Int
Probe.hx:26: characters 3-27 : (center : helix.ray.Vector2, radius : Float, color : helix.ray.Color) -> Void should be Int
Probe.hx:27: characters 3-30 : () -> Int should be Int
Probe.hx:28: characters 3-34 : (gamepad : Int) -> Bool should be Int
Probe.hx:29: characters 3-34 : () -> Int should be Int
Probe.hx:30: characters 3-27 : (filePath : String) -> String should be Int
Probe.hx:31: characters 3-25 : helix.ray.Color should be Int
Probe.hx:32: characters 3-24 : helix.ray.Color should be Int
Probe.hx:34: characters 3-32 : () -> Void should be Int
Probe.hx:35: characters 3-31 : (texture : helix.ray.Texture2D) -> Bool should be Int
Probe.hx:36: characters 3-27 : (startPos : helix.ray.Vector2, endPos : helix.ray.Vector2, thick : Float, color : helix.ray.Color) -> Void should be Int
Probe.hx:37: characters 3-31 : () -> Void should be Int
Probe.hx:38: characters 3-35 : (position : helix.ray.Vector2, camera : helix.ray.Camera2D) -> helix.ray.Vector2 should be Int
Probe.hx:39: characters 3-29 : (sound : helix.ray.Sound) -> Bool should be Int
```

## Compile 4

```
Main.hx:460: characters 22-28 : helix.ray.FilePathList has no field length
Main.hx:460: characters 35-40 : Array access is not allowed on helix.ray.FilePathList
Main.hx:460: characters 35-40 : ... For function argument 'body'
```

## Compile 5

```
Main.hx:435: characters 9-20 : LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)
Main.hx:436: characters 10-19 : LoadSound: Synchronous loading is not supported. See LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void)
Main.hx:439: characters 11-23 : LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)
```

## Compile 6

```
(Bash completed with no output)
```
