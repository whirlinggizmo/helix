# Notes

## Compile errors (in order)
1. `Main.hx:18-26`: `cast {r:..}` to Color "Not supported from an object to Color" (8 places: background, panelColor, outline, five swatches). Removed `cast`; the braces are typed by the expected type.
2. `Main.hx:30-31`: same error for `cast {...}` to VirtualButtonOptions. Removed `cast`.

## Warnings logged
None (only INFO lines).
Visual issue: the default left/right virtual sticks were drawn. Disabled them with `left: {enabled: false}, right: {enabled: false}` since the task asks for only two buttons.

## Guesses
- Panel/swatch layout: panel at (190, 95); swatches vertically centered in the panel ("middle").
- Did not test the button presses by clicking; only the 60-frame screenshot was checked.
