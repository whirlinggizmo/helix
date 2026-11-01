# Agent 2: every compile, in order, with its whole output

## Compile 1

```
Main.hx:5: characters 11-21 : Warning : (width : Int, height : Int, title : String) -> Void
Main.hx:6: characters 11-22 : Macro functions must be called immediately
Main.hx:6: characters 11-22 : Invalid macro access
Main.hx:7: characters 11-20 : Macro functions must be called immediately
Main.hx:7: characters 11-20 : Invalid macro access
Main.hx:8: characters 11-23 : Macro functions must be called immediately
Main.hx:8: characters 11-23 : Invalid macro access
Main.hx:9: characters 11-24 : Warning : (texture : helix.ray.Texture2D, position : helix.ray.Vector2, rotation : Float, scale : Float, tint : helix.ray.Color) -> Void
Main.hx:10: characters 11-22 : Warning : (camera : helix.ray.Camera2D) -> Void
Main.hx:11: characters 11-29 : Warning : (position : helix.ray.Vector2, camera : helix.ray.Camera2D) -> helix.ray.Vector2
Main.hx:12: characters 11-27 : Warning : () -> helix.ray.FilePathList
Main.hx:13: characters 11-19 : Warning : helix.ray.Color
Main.hx:14: characters 11-23 : Warning : (fps : Int) -> Void
Main.hx:15: characters 11-27 : Unknown identifier : SaveStorageValue
Main.hx:16: characters 11-21 : Macro functions must be called immediately
Main.hx:16: characters 11-21 : Invalid macro access
Main.hx:17: characters 11-33 : Warning : (gamepad : Int, axis : Int) -> Float
Main.hx:18: characters 11-27 : Warning : (rec : helix.ray.Rectangle, color : helix.ray.Color) -> Void
Main.hx:19: characters 11-27 : Warning : (x : Int, y : Int, width : Int, height : Int) -> Void
Main.hx:20: characters 11-24 : Warning : () -> Int
Main.hx:21: characters 11-16 : Warning : Int
Main.hx:22: characters 11-25 : Warning : (flags : Int) -> Void
Main.hx:23: characters 11-32 : Warning : Int
```

## Compile 2

```
Main.hx:6: characters 19-51 : LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)
/tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/helix/ray/src/helix/ray/Raylib.hx:5350: characters 9-37 : Warning : helix.ray.Texture2D
Main.hx:7: characters 19-47 : LoadSound: Synchronous loading is not supported. See LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void)
/tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/helix/ray/src/helix/ray/Raylib.hx:5427: characters 9-33 : Warning : helix.ray.Sound
Main.hx:8: characters 19-59 : LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)
/tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/helix/ray/src/helix/ray/Raylib.hx:5296: characters 9-30 : Warning : Null<String>
Main.hx:9: characters 19-57 : FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)
/tmp/claude-1000/-home-rknopf-projects-github-whirlinggizmo-helix-2-0/60669423-441a-4b69-b693-33655c8d5ced/scratchpad/trial-2d-run/helix/ray/src/helix/ray/Raylib.hx:5291: characters 9-23 : Warning : Bool
Main.hx:10: characters 11-23 : Warning : (fileName : String, text : String) -> Bool
Main.hx:11: characters 11-27 : Unknown identifier : LoadStorageValue
Main.hx:17: characters 11-19 : Warning : Int
Main.hx:17: characters 28-36 : Warning : Array<String>
Main.hx:18: characters 11-24 : Warning : () -> Bool
Main.hx:19: characters 11-22 : Warning : (filePath : String) -> String
Main.hx:20: characters 11-20 : Warning : (sound : helix.ray.Sound) -> Void
Main.hx:21: characters 11-26 : Warning : () -> Void
Main.hx:22: characters 11-28 : Warning : () -> Float
Main.hx:23: characters 11-29 : Warning : () -> Int
Main.hx:24: characters 11-29 : Warning : (gamepad : Int) -> Bool
Main.hx:25: characters 11-34 : Warning : () -> Int
Main.hx:26: characters 11-22 : Warning : (text : String, fontSize : Int) -> Int
Main.hx:27: characters 11-22 : Warning : (center : helix.ray.Vector2, radius : Float, color : helix.ray.Color) -> Void
Main.hx:28: characters 11-31 : Warning : (rec : helix.ray.Rectangle, lineThick : Float, color : helix.ray.Color) -> Void
Main.hx:29: characters 11-23 : Warning : () -> Float
Main.hx:30: characters 11-21 : Warning : (text : String, args : haxe.extern.Rest<Dynamic>) -> String
Main.hx:31: characters 11-34 : Warning : (center : helix.ray.Vector2, radius : Float, rec : helix.ray.Rectangle) -> Bool
```

## Compile 3

```
(Bash completed with no output)
```
