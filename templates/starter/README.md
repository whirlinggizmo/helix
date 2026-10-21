# {title}

A game on [HeliX](https://github.com/whirlinggizmo/helix) (`-lib helix`). `src/Game.hx` is the game, `src/Main.hx` starts it.

```console
haxe web.hxml                        # the browser build, out/web/app.js
haxelib run helix site --zip         # the page around it in out/site/, zipped for hosting (itch.io) as out/{name}-web.zip
haxe native.hxml && out/native/Main  # the native build (hxcpp), out/native/Main; it reads assets/ beside itself: copy (or link) the folder to out/native/assets
```

The dev loop, in two terminals: hotreload-hx's server rebuilds on save and swaps the code into the running page at <http://localhost:8064/>
(the assets served at /assets), and HeliX packs the game's shaders (`shaders/*.glsl`, loaded as `shaders/<name>.hxshader`) as they change.

```console
haxe -lib hotreload-hx --run hotreload.DevServer --port 8064 --mount /assets=assets web.hxml
haxelib run helix shader --watch
```
