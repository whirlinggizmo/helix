// raylib 5.5's GIF images, printed for tools/ray_parity.py: each file LoadImageAnim reads (helix-formats' test GIFs, a PNG), and the
// bytes LoadImageAnimFromMemory decodes, as their frame count and, when it has frames, the image of them all, its height every
// frame's, byte for byte; then the first frames LoadImage, LoadImageFromMemory and LoadTexture read, and a font LoadFont reads from a
// GIF.
#include "raylib.h"
#include "parity.h"
#include <stdio.h>

// An animation's frame count, then its frames as one image, one above the next.
static void anim(const char *name, Image im, int frames) {
    printf("%s frames %d\n", name, frames);
    if (frames == 0 || im.data == NULL) return;
    Image all = im;
    all.height *= frames;
    image(name, all);
}

static void file(const char *name, const char *fileName) {
    int frames = -1;
    Image im = LoadImageAnim(fileName, &frames);
    anim(name, im, im.data == NULL ? 0 : frames);
    UnloadImage(im);
}

static void memory(const char *name, const char *fileName, const char *fileType) {
    int size = 0, frames = -1;
    unsigned char *data = LoadFileData(fileName, &size);
    Image im = LoadImageAnimFromMemory(fileType, data, size, &frames);
    anim(name, im, im.data == NULL ? 0 : frames);
    UnloadImage(im);
    UnloadFileData(data);
}

// An image LoadImage reads: none when it has no data.
static void still(const char *name, const char *fileName) {
    Image im = LoadImage(fileName);
    if (im.data == NULL) printf("%s none\n", name);
    else image(name, im);
    UnloadImage(im);
}

// An image LoadImageFromMemory decodes: none when it has no data.
static void stillMemory(const char *name, const char *fileName, const char *fileType) {
    int size = 0;
    unsigned char *data = LoadFileData(fileName, &size);
    Image im = LoadImageFromMemory(fileType, data, size);
    if (im.data == NULL) printf("%s none\n", name);
    else image(name, im);
    UnloadImage(im);
    UnloadFileData(data);
}

// A texture LoadTexture makes: none (id 0), or its size, mipmaps and format, and its pixels read back.
static void texture(const char *name, const char *fileName) {
    Texture2D t = LoadTexture(fileName);
    if (t.id == 0) { printf("%s none\n", name); return; }
    printf("%s texture %d %d %d %d\n", name, t.width, t.height, t.mipmaps, t.format);
    Image im = LoadImageFromTexture(t);
    image(name, im);
    UnloadImage(im);
    UnloadTexture(t);
}

// A font LoadFont reads: its sizes, whether it is the default font, and each glyph's value, offsets, advance, rectangle and image.
static void font(const char *name, const char *fileName) {
    Font f = LoadFont(fileName);
    printf("%s font %d %d %d default %d texture %d %d\n", name, f.baseSize, f.glyphCount, f.glyphPadding,
           f.texture.id == GetFontDefault().texture.id, f.texture.width, f.texture.height);
    char key[64];
    for (int i = 0; i < f.glyphCount; i++) {
        GlyphInfo g = f.glyphs[i];
        Rectangle r = f.recs[i];
        printf("%s glyph %d %d %d %d %d rec %.9g %.9g %.9g %.9g\n", name, i, g.value, g.offsetX, g.offsetY, g.advanceX, r.x, r.y,
               r.width, r.height);
        sprintf(key, "%s glyph %d", name, i);
        image(key, g.image);
    }
    UnloadFont(f);
}

int main(void) {
    SetTraceLogLevel(LOG_NONE);
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(64, 64, "images");
    file("still", "still.gif");
    file("anim", "anim.gif");
    file("dispose", "dispose.gif");
    file("transparent", "transparent.gif");
    file("large", "large.gif");
    file("pil", "pil.gif");
    file("empty", "empty.gif");
    file("missing", "nothere.gif");
    file("png", "still.png");
    file("named", TextFormat("%s.gif", "dispose"));
    memory("memory", "transparent.gif", ".gif");
    memory("memoryupper", "anim.gif", ".GIF");
    memory("memorypng", "still.png", ".png");
    memory("memorytyped", "pil.gif", TextFormat(".%s", "gif"));
    still("first still", "still.gif");
    still("first anim", "anim.gif");
    still("first dispose", "dispose.gif");
    still("first transparent", "transparent.gif");
    still("first large", "large.gif");
    still("first pil", "pil.gif");
    still("first empty", "empty.gif");
    still("first missing", "nothere.gif");
    still("first named", TextFormat("%s.gif", "large"));
    still("first namedpng", TextFormat("%s.png", "still"));
    stillMemory("first memory", "transparent.gif", ".gif");
    stillMemory("first memoryupper", "anim.gif", ".GIF");
    stillMemory("first memorytyped", "dispose.gif", TextFormat(".%s", "gif"));
    stillMemory("first memorymixed", "dispose.gif", ".Gif");
    stillMemory("first memorypng", "still.png", TextFormat(".%s", "png"));
    texture("texture anim", "anim.gif");
    texture("texture large", "large.gif");
    texture("texture named", TextFormat("%s.gif", "pil"));
    texture("texture empty", "empty.gif");
    font("font gif", "font.gif");
    font("font named", TextFormat("%s.gif", "font"));
    CloseWindow();
    return 0;
}
