# helix.scene

[Back to the index](README.md)

## Pointer

*class* in `src/helix/scene/Pointer.hx`

The pointer over stages: which node it's over, and what it pressed and clicked, asked of it, never told to the nodes (DECISIONS 61). The stages it looks at are added in draw order, each with the camera it's drawn through; update() picks them topmost (last added) first, once a frame after input is polled, so a HUD drawn over the world takes the pointer first. A press on a 2D node captures the pointer: until it's released, the stages under it see nothing (isCaptured, for an app's own use of the pointer too). Edges (isPressed, isClicked) last the frame they happen in. Nodes are compared by identity: a 3D stage's are Nodes, a 2D stage's Node2Ds.

```haxe
function new(input:IInput)
function addStage2D(stage:Stage2D, camera:Camera2D):Void
function addStage3D(stage:Stage3D, camera:Camera3D):Void
function remove(stage:Any):Void
function update():Void
function getHovered():Null<Any>
function isHovered(node:Any):Bool
function isPressed(node:Any):Bool
function isDown(node:Any):Bool
function isClicked(node:Any):Bool
function getHeld():Null<Any>
function isCaptured():Bool
function getHit3D():Null<PickHit>
```

- `new`: The pointer of input.
- `addStage2D`: Looks at stage through camera, above the stages added before it.
- `addStage3D`: Looks at stage through camera, above the stages added before it.
- `remove`: Stops looking at stage (2D or 3D); what it held lets go.
- `update`: Once a frame, after input is polled and before the stages' nodes are read: picks under the pointer, topmost stage first, and works out the frame's press and click.
- `getHovered`: The node under the pointer, topmost stage first, or null.
- `isHovered`: Whether node is under the pointer.
- `isPressed`: Whether the pointer went down on node this frame.
- `isDown`: Whether node is held: the pointer went down on it and hasn't come up, wherever it is now (a drag).
- `isClicked`: Whether node was clicked this frame: the pointer came up over the node it went down on.
- `getHeld`: The node held (isDown), or null.
- `isCaptured`: Whether a press on a 2D stage holds the pointer: the stages under it, and the app's own world controls, should leave it be.
- `getHit3D`: The last hit in a 3D stage (its point, normal, distance), when the hovered node is a 3D stage's; null otherwise.
