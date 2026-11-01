# Agent 2: every compile, in order, with its whole output

## Compile 1

```
rc=0
[{"file":"Main.hx","symbols":[{"name":"Main","kind":1,"range":{"start":{"line":1,"character":0},"end":{"line":5,"character":1}}},{"name":"main","kind":8,"range":{"start":{"line":2,"character":2},"end":{"line":4,"character":3}},"containerName":"Main"}]}]
```

## Compile 2

```
Exit code 1
Main.hx:4: characters 11-21 : Warning : (width : Int, height : Int, title : String) -> Void
Main.hx:5: characters 11-28 : Warning : () -> Bool
Main.hx:6: characters 11-22 : Unknown identifier : SetMainLoop
Main.hx:7: characters 11-22 : Warning : (fileName : String) -> helix.ray.Texture2D
Main.hx:8: characters 11-20 : Warning : (fileName : String) -> helix.ray.Sound
Main.hx:9: characters 11-26 : Warning : () -> Void
Main.hx:10: characters 11-23 : Warning : (fileName : String) -> Null<String>
Main.hx:11: characters 11-28 : Warning : (fileName : String, loaded : (String -> Void), ?failed : Null<String -> Void>) -> Void
Main.hx:12: characters 11-21 : Warning : (fileName : String) -> Bool
Main.hx:13: characters 11-27 : Warning : () -> helix.ray.FilePathList
Main.hx:14: characters 11-24 : Warning : () -> Bool
Main.hx:15: characters 11-27 : Unknown identifier : SaveStorageValue
Main.hx:16: characters 11-27 : Unknown identifier : LoadStorageValue
Main.hx:17: characters 11-22 : Warning : (camera : helix.ray.Camera2D) -> Void
Main.hx:18: characters 11-25 : Warning : (texture : helix.ray.Texture2D, source : helix.ray.Rectangle, dest : helix.ray.Rectangle, origin : helix.ray.Vector2, rotation : Float, tint : helix.ray.Color) -> Void
Main.hx:19: characters 11-19 : Warning : (text : String, posX : Int, posY : Int, fontSize : Int, color : helix.ray.Color) -> Void
Main.hx:20: characters 11-22 : Warning : (text : String, fontSize : Int) -> Int
Main.hx:21: characters 11-28 : Warning : () -> Float
Main.hx:22: characters 11-29 : Warning : (position : helix.ray.Vector2, camera : helix.ray.Camera2D) -> helix.ray.Vector2
Main.hx:23: characters 11-27 : Warning : (x : Int, y : Int, width : Int, height : Int) -> Void
Main.hx:24: characters 11-24 : Warning : () -> Int
Main.hx:25: characters 11-33 : Warning : (gamepad : Int, axis : Int) -> Float
Main.hx:26: characters 11-29 : Warning : (gamepad : Int) -> Bool
Main.hx:27: characters 11-29 : Warning : () -> Int
Main.hx:28: characters 11-25 : Warning : (flags : Int) -> Void
Main.hx:29: characters 11-34 : Warning : (center : helix.ray.Vector2, radius : Float, rec : helix.ray.Rectangle) -> Bool
Main.hx:30: characters 11-31 : Warning : (rec : helix.ray.Rectangle, lineThick : Float, color : helix.ray.Color) -> Void
Main.hx:31: characters 11-25 : Warning : (min : Int, max : Int) -> Int
Main.hx:32: characters 11-24 : Warning : (seed : Int) -> Void
Main.hx:33: characters 11-29 : Warning : (files : helix.ray.FilePathList) -> Void
Main.hx:34: characters 11-22 : Warning : (filePath : String) -> String
Main.hx:35: characters 11-21 : Warning : (text : String, args : haxe.extern.Rest<Dynamic>) -> String
Main.hx:36: characters 11-20 : Warning : (sound : helix.ray.Sound) -> Void
Main.hx:37: characters 11-34 : Warning : () -> Int
Main.hx:38: characters 11-25 : Warning : (text : Null<String>) -> Void
```

## Compile 3

```
Exit code 1
Main.hx:11: characters 23-24 : Expected (
```

## Compile 4

```
Exit code 1
Main.hx:5: characters 11-23 : Warning : (fileName : String, text : String) -> Bool
Main.hx:6: characters 11-35 : Unknown identifier : emscripten_set_main_loop
Main.hx:7: characters 11-23 : Warning : (fps : Int) -> Void
Main.hx:9: characters 11-18 : Warning : Int
Main.hx:10: characters 11-18 : Warning : Array<String>
Main.hx:11: characters 11-23 : Warning : (offset : Null<helix.ray.Vector2>, target : Null<helix.ray.Vector2>, rotation : Float, zoom : Float) -> helix.ray.Camera2D
Main.hx:12: characters 11-22 : Warning : (x : Float, y : Float) -> helix.ray.Vector2
Main.hx:13: characters 11-24 : Warning : (x : Float, y : Float, width : Float, height : Float) -> helix.ray.Rectangle
Main.hx:14: characters 11-20 : Warning : (r : Int, g : Int, b : Int, a : Int) -> helix.ray.Color
Main.hx:15: characters 11-19 : Warning : helix.ray.Color
Main.hx:16: characters 11-32 : Warning : Int
Main.hx:17: characters 11-16 : Warning : Int
Main.hx:18: characters 11-30 : Warning : Int
Main.hx:19: characters 11-28 : Warning : Int
Main.hx:20: characters 11-27 : Warning : (index : Int) -> helix.ray.Vector2
Main.hx:21: characters 11-26 : Warning : () -> Bool
Main.hx:22: characters 11-23 : Warning : () -> Float
Main.hx:23: characters 11-27 : Warning : () -> helix.ray.Vector2
Main.hx:24: characters 11-31 : Warning : (button : Int) -> Bool
Main.hx:25: characters 11-28 : Warning : (gesture : Int) -> Bool
Main.hx:26: characters 11-22 : Warning : Int
Main.hx:27: characters 11-25 : Warning : (texture : helix.ray.Texture2D) -> Bool
Main.hx:28: characters 11-23 : Warning : (sound : helix.ray.Sound) -> Bool
Main.hx:29: characters 11-15 : Warning : (color : helix.ray.Color, alpha : Float) -> helix.ray.Color
Main.hx:30: characters 11-22 : Warning : (center : helix.ray.Vector2, radius : Float, color : helix.ray.Color) -> Void
Main.hx:31: characters 11-27 : Warning : (rec : helix.ray.Rectangle, color : helix.ray.Color) -> Void
Main.hx:32: characters 11-20 : Warning : (startPos : helix.ray.Vector2, endPos : helix.ray.Vector2, color : helix.ray.Color) -> Void
Main.hx:33: characters 11-26 : Warning : (color : helix.ray.Color) -> Void
Main.hx:34: characters 11-25 : Warning : () -> Void
Main.hx:35: characters 11-25 : Warning : () -> Int
Main.hx:36: characters 11-24 : Warning : (text : String) -> Int
Main.hx:37: characters 11-20 : Warning : (text : String, delimiter : Int, count : Array<Int>) -> Array<String>
Main.hx:38: characters 11-27 : Warning : (fileName : String) -> String
Main.hx:39: characters 11-29 : Warning : (rec1 : helix.ray.Rectangle, rec2 : helix.ray.Rectangle) -> Bool
Main.hx:40: characters 11-34 : Warning : () -> Int
Main.hx:41: characters 11-33 : Warning : (gamepad : Int, button : Int) -> Bool
Main.hx:42: characters 11-24 : Warning : (texture : helix.ray.Texture2D, position : helix.ray.Vector2, rotation : Float, scale : Float, tint : helix.ray.Color) -> Void
```

## Compile 5

```
Main.hx:68: characters 13-24 : LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)
Main.hx:69: characters 15-24 : LoadSound: Synchronous loading is not supported. See LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void)
Main.hx:72: characters 7-17 : FileExists: Synchronous file access is not supported. See FileExistsAsync(fileName:String, answer:Bool->Void)
Main.hx:73: characters 15-27 : LoadFileText: Synchronous loading is not supported. See LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)
rc=1
```

## Compile 6

```
534:			DrawTexturePro(shipTex, new Rectangle(0, 0, shipTex.width, shipTex.height),
535-				new Rectangle(shipX - SHIP_SIZE / 2, shipY - SHIP_SIZE / 2, SHIP_SIZE, SHIP_SIZE), new Vector2(0, 0), 0, WHITE);
536-		else
537-			DrawRectangleRec(shipRect(shipX, shipY), WHITE);
538-		EndMode2D();
rc=0
```
