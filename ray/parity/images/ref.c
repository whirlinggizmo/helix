// raylib 5.5's animated images, printed for tools/ray_parity.py: each file LoadImageAnim reads (helix-formats' test GIFs, a PNG), and
// the bytes LoadImageAnimFromMemory decodes, as their frame count and, when it has frames, the image of them all, its height every
// frame's, byte for byte.
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

int main(void) {
    SetTraceLogLevel(LOG_NONE);
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
    return 0;
}
