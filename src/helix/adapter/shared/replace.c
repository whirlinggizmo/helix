#include "replace.h"
#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>

static wchar_t *wide(const char *s) {
    int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
    wchar_t *w = n > 0 ? malloc((size_t)n * sizeof(wchar_t)) : NULL;
    if (w && !MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n)) { free(w); w = NULL; }
    return w;
}

int helix_replace_file(const char *from, const char *to) {
    wchar_t *a = wide(from), *b = wide(to);
    int ok = a && b && MoveFileExW(a, b, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
    free(a); free(b);
    return ok;
}
#else
#include <stdio.h>

int helix_replace_file(const char *from, const char *to) { return rename(from, to) == 0; }
#endif
