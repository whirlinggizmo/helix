# helix-services

What a game program needs over [helix-platform](../platform/README.md) that isn't drawing:

| Package | What |
|---|---|
| `helix.services.time` | `Time`: the game's time, scaled and paused, its timers, and real time beside it |
| `helix.services.input` | `Input`: keys, mouse and gamepads held or pressed this frame; `Actions`: names bound to several of them |
| `helix.services.assets` | `Assets`: files by path, from a file system or downloaded from an HTTP server and kept |
| `helix.services.audio` | `Audio`: sounds loaded whole or streamed, played in groups, with fades |
| `helix.services.saves` | `Saves`: small values kept between runs |
| `helix.services.config` | `Config`: the options the program was started with |

## Using it

```
-lib helix-services
```

Until it is published, link it, and the libraries it's built on (helix-platform, helix-math and helix-log), from a checkout:

```
haxelib dev helix-services <checkout>/services
```

The API reference is [docs/api/](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/README.md), one page per package.
