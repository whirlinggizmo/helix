// raylib 5.5's ExportFontAsCode, printed for tools/raylib_parity.py: the header it writes, a line at a time as its bytes (parity.h's str),
// for the default font, a TrueType font (engines/raylib/examples/text's JetBrains Mono) at two sizes, and a font read from an image (RGBA, which
// it warns of and writes as it is).
#include "raylib.h"
#include "parity.h"
#include <stdio.h>
#include <string.h>

static void exported(const char *name, Font font, const char *fileName) {
    printf("%s exported %d\n", name, ExportFontAsCode(font, fileName) ? 1 : 0);
    char *text = LoadFileText(fileName);
    int lineCount = 0, byteCount = text == NULL ? 0 : (int)strlen(text);
    for (char *at = text; at != NULL && *at != '\0';) {
        char *end = strchr(at, '\n');
        if (end != NULL) *end = '\0';
        str(name, at);
        lineCount++;
        at = end == NULL ? NULL : end + 1;
    }
    printf("%s lines %d bytes %d\n", name, lineCount, byteCount);
    UnloadFileText(text);
}

int main(void) {
    parity_open();
    exported("default", GetFontDefault(), "font_default.h");
    exported("ttf", LoadFontEx("font.ttf", 20, NULL, 0), "jet_brains_mono.h");
    exported("large", LoadFontEx("font.ttf", 48, (int[]){ 65, 66, 103, 64, 0x2014 }, 5), "large.h");
    Image sheet = GenImageColor(40, 22, MAGENTA);
    ImageDrawRectangle(&sheet, 2, 2, 5, 8, WHITE);
    ImageDrawRectangle(&sheet, 9, 2, 3, 8, (Color){ 200, 100, 50, 255 });
    ImageDrawRectangle(&sheet, 14, 2, 6, 8, (Color){ 10, 20, 30, 128 });
    ImageDrawRectangle(&sheet, 2, 12, 4, 8, BLACK);
    exported("image", LoadFontFromImage(sheet, MAGENTA, 32), "image_font.h");
    parity_close();
    return 0;
}
