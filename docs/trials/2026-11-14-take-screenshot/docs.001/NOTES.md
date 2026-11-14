# Notes
## Compile errors
None.
## Warnings logged
None (only INFO lines).
## Guesses
- Texture and fonts load asynchronously (LoadTextureAsync / LoadFontExAsync, per docs), so draws are skipped until the callbacks fire.
- Two fonts loaded (64 and 24) rather than scaling one.
- Text spacing 2; prompt y=210 ("under the title"); blink = visible on even seconds of GetTime().
- Enter breaks the loop and then CloseWindow(), since CloseWindow does not end the program itself.
