# Notes

## Compile errors, in order
1. `Main.hx:18-31`: `cast {...}: Not supported from an object to Color` / `VirtualButtonOptions` (10 places: colors, swatches, two buttons). Removed `cast`; the object literals are written in braces where the type is expected.

## Warnings logged
None. The run logged only INFO lines.

## Other fix
- The first screenshot showed the default virtual sticks (left and right hints) beside the two buttons. The task asks for two buttons only, so `EnableVirtualGamepad` now gets `left: {enabled: false}, right: {enabled: false}`.

## Guesses
- Assumed `{enabled: false}` is the way to switch a stick off (taken from the docs' `right: {enabled: false}` example).
- Assumed the "middle of the panel" for the swatch row means vertically centered in the panel.
- I did not test the button presses (OK quits, II toggles the outline). Only the `--frames=60` run and the screenshot were checked.
