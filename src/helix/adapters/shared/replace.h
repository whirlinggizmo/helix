#ifndef HELIX_REPLACE_H
#define HELIX_REPLACE_H
#ifdef __cplusplus
extern "C" {
#endif
/* Renames the file at from (UTF-8) over to's, replacing it in one step where one is there: rename on POSIX, MoveFileExW with
   MOVEFILE_REPLACE_EXISTING on Windows, whose rename (and so hxcpp's FileSystem.rename) refuses an existing file. 1 when it did. */
int helix_replace_file(const char *from, const char *to);
#ifdef __cplusplus
}
#endif
#endif
