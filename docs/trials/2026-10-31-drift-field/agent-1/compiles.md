# Agent 1: every compile, in order, with its whole output

## Compile 1

```
Exit code 1
Main.hx:5: characters 13-45 : LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)
Main.hx:6: characters 13-53 : LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)
```

## Compile 2

```
Exit code 1
Main.hx:5: characters 11-27 : Warning : (fileName : String, loaded : (helix.ray.Texture2D -> Void), ?failed : Null<String -> Void>) -> Void
Main.hx:6: characters 11-25 : Warning : (fileName : String, loaded : (helix.ray.Sound -> Void), ?failed : Null<String -> Void>) -> Void
Main.hx:7: characters 11-24 : Warning : (fileName : String, loaded : (helix.ray.Wave -> Void), ?failed : Null<String -> Void>) -> Void
Main.hx:8: characters 11-27 : Warning : () -> helix.ray.FilePathList
Main.hx:9: characters 11-24 : Warning : () -> Bool
Main.hx:10: characters 11-23 : Warning : (fileName : String, text : String) -> Bool
Main.hx:11: characters 11-23 : Macro functions must be called immediately
Main.hx:11: characters 11-23 : Invalid macro access
Main.hx:12: characters 11-21 : Macro functions must be called immediately
Main.hx:12: characters 11-21 : Invalid macro access
Main.hx:13: characters 11-27 : Unknown identifier : SaveStorageValue
Main.hx:14: characters 11-27 : Warning : (x : Int, y : Int, width : Int, height : Int) -> Void
Main.hx:15: characters 11-19 : Unknown identifier : Camera2D
Main.hx:16: characters 11-29 : Warning : (position : helix.ray.Vector2, camera : helix.ray.Camera2D) -> helix.ray.Vector2
Main.hx:17: characters 11-28 : Warning : () -> Float
Main.hx:18: characters 11-33 : Warning : (gamepad : Int, axis : Int) -> Float
Main.hx:19: characters 11-33 : Warning : (gamepad : Int, button : Int) -> Bool
Main.hx:20: characters 11-24 : Warning : () -> Int
Main.hx:21: characters 11-29 : Warning : () -> Int
Main.hx:22: characters 11-29 : Warning : () -> Int
Main.hx:23: characters 11-25 : Warning : (flags : Int) -> Void
Main.hx:24: characters 11-32 : Warning : Int
Main.hx:25: characters 11-25 : Warning : (texture : helix.ray.Texture2D, source : helix.ray.Rectangle, dest : helix.ray.Rectangle, origin : helix.ray.Vector2, rotation : Float, tint : helix.ray.Color) -> Void
Main.hx:26: characters 11-22 : Warning : (text : String, fontSize : Int) -> Int
Main.hx:27: characters 11-22 : Warning : (filePath : String) -> String
Main.hx:28: characters 11-22 : Unknown identifier : SetMainLoop
```

## Compile 3

```
Exit code 1
Main.hx:6: characters 13-35 : FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)
Main.hx:7: characters 13-37 : LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)
Main.hx:8: characters 13-51 : FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)
Main.hx:10: characters 11-19 : Warning : Int
Main.hx:11: characters 11-19 : Warning : Array<String>
Main.hx:13: characters 11-21 : Warning : helix.ray.Vector2
Main.hx:15: characters 11-14 : Warning : helix.ray.Color
Main.hx:17: characters 11-28 : Warning : (fileName : String, loaded : (String -> Void), ?failed : Null<String -> Void>) -> Void
Main.hx:18: characters 11-29 : Warning : (files : helix.ray.FilePathList) -> Void
Main.hx:19: characters 11-23 : Warning : () -> Float
Main.hx:20: characters 11-20 : Warning : (sound : helix.ray.Sound) -> Void
Main.hx:21: characters 11-26 : Warning : () -> Void
Main.hx:22: characters 11-22 : Warning : (center : helix.ray.Vector2, radius : Float, color : helix.ray.Color) -> Void
Main.hx:23: characters 11-34 : Warning : (center : helix.ray.Vector2, radius : Float, rec : helix.ray.Rectangle) -> Bool
Main.hx:24: characters 11-25 : Warning : (min : Int, max : Int) -> Int
Main.hx:25: characters 11-24 : Warning : (seed : Int) -> Void
Main.hx:26: characters 11-19 : Warning : (text : String, posX : Int, posY : Int, fontSize : Int, color : helix.ray.Color) -> Void
Main.hx:27: characters 11-25 : Warning : () -> Int
Main.hx:28: characters 11-31 : Warning : (button : Int) -> Bool
Main.hx:29: characters 11-27 : Warning : () -> helix.ray.Vector2
Main.hx:30: characters 11-27 : Warning : (index : Int) -> helix.ray.Vector2
Main.hx:31: characters 11-29 : Warning : (gamepad : Int) -> Bool
Main.hx:32: characters 11-30 : Warning : Int
Main.hx:33: characters 11-34 : Warning : () -> Int
Main.hx:34: characters 11-31 : Warning : (rec : helix.ray.Rectangle, lineThick : Float, color : helix.ray.Color) -> Void
```

## Compile 4

```
(Bash completed with no output)
```

## Compile 5

```
OK
```

## Compile 6

```
OK
```
