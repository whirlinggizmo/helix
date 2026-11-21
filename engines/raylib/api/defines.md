# helix-raylib's defines

[Back to the library](README.md)

Set in a build's hxml, as `-D helix-raylib-asset-hosts=../assets`. `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-raylib-asset-hosts=<urls and directories>`: Where the program's assets come from (SetAssetHosts), unless the program sets the hosts or the asset_hosts option names them: a list separated by commas, in the order the hosts are asked. Each host is a URL the assets are fetched from, natively and in a page, or a directory, relative to the program's own. Defaults to ../web natively and to the page's own directory in a page.
- `helix-raylib-host-warnings`: Warns where the program's own code reaches the page (localStorage, the page's fullscreen) for what Raylib answers on every target, naming the call. Off by default.
- `helix-raylib-portable-sys`: Adds a Sys to a page (the program's options from the URL's query, the console and the clock) and refuses on every target what a page can't answer: Haxe's file calls (sys.io.File, sys.FileSystem), sys.io.Process and the Sys calls a page has no answer for, each refusal naming the raylib call to use. So a program that builds natively builds for the page. Off by default, when a build is Haxe's as shipped.
- `helix-raylib-frame-stats`: For timing a program without changing it: with the frame_stats option (--frame_stats=120,1200 natively, ?frame_stats=120,1200 in a page), records frames 121 to 1200, prints the stats as frame_stats and a JSON object, and closes the window. In a page the object is also window.helixResult. Off by default.
- `helix-raylib-custom-frame-control`: raylib's SUPPORT_CUSTOM_FRAME_CONTROL: EndDrawing only draws, and the program calls SwapScreenBuffer, WaitTime and PollInputEvents itself.
