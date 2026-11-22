/* What helix-box2d's generated C (hb.c) stands on: the word buffer a call's structs, arrays and strings cross through, and the
   callback buffer a callback's pointer arguments cross through.

   A call's inputs are written from the buffer's first word by Haxe and read in order here before Box2D is called; its outputs are
   written in order from the first word after Box2D returns, and read by Haxe. Each word is a float or an int32. The buffer grows to
   what a call writes, which can move it, so Haxe reads its address again after each call. */
#ifndef HB_IO_H
#define HB_IO_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#define HB_API __attribute__((used, visibility("default")))
#define HB_IMPORT(name) __attribute__((import_module("env"), import_name(#name)))
#else
#define HB_API
#endif

typedef struct hb_buffer {
	uint32_t *words;
	int32_t capacity;
	int32_t position;
} hb_buffer;

extern hb_buffer hb_call, hb_back;

static inline void hb_reserve(hb_buffer *b, int32_t words) {
	if (words <= b->capacity)
		return;
	int32_t capacity = b->capacity < 1024 ? 1024 : b->capacity;
	while (capacity < words)
		capacity *= 2;
	b->words = (uint32_t *)realloc(b->words, (size_t)capacity * 4);
	b->capacity = capacity;
}

static inline void hb_begin(hb_buffer *b) { b->position = 0; }

static inline float hb_rf(hb_buffer *b) {
	float f;
	memcpy(&f, &b->words[b->position++], 4);
	return f;
}

static inline int32_t hb_ri(hb_buffer *b) { return (int32_t)b->words[b->position++]; }

static inline uint64_t hb_rl(hb_buffer *b) {
	uint64_t low = b->words[b->position++];
	uint64_t high = b->words[b->position++];
	return low | (high << 32);
}

static inline void hb_wf(hb_buffer *b, float f) {
	hb_reserve(b, b->position + 1);
	memcpy(&b->words[b->position++], &f, 4);
}

static inline void hb_wi(hb_buffer *b, int32_t i) {
	hb_reserve(b, b->position + 1);
	b->words[b->position++] = (uint32_t)i;
}

static inline void hb_wl(hb_buffer *b, uint64_t l) {
	hb_wi(b, (int32_t)(uint32_t)l);
	hb_wi(b, (int32_t)(uint32_t)(l >> 32));
}

/* A string: its length in bytes (-1 for none), then its bytes, four to a word. Read into scratch memory that lasts until the next
   read into the same slot. */
const char *hb_rs(hb_buffer *b, int slot);
void hb_ws(hb_buffer *b, const char *s);

/* Bytes: as a string's, with a length always 0 or more. */
const uint8_t *hb_rbytes(hb_buffer *b, int32_t count, int slot);
void hb_wbytes(hb_buffer *b, const uint8_t *bytes, int32_t count);

/* Memory for a call's arrays, kept per slot between calls. */
void *hb_scratch(int slot, size_t bytes);

#endif
