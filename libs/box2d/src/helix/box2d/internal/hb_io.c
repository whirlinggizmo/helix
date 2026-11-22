/* hb_io.h's buffers, strings and scratch memory, and their addresses for Haxe. */
#include "hb_io.h"

hb_buffer hb_call, hb_back;

#define HB_SLOTS 32
static void *scratch[HB_SLOTS];
static size_t scratch_size[HB_SLOTS];

void *hb_scratch(int slot, size_t bytes) {
	if (bytes > scratch_size[slot]) {
		scratch[slot] = realloc(scratch[slot], bytes);
		scratch_size[slot] = bytes;
	}
	return scratch[slot];
}

const uint8_t *hb_rbytes(hb_buffer *b, int32_t count, int slot) {
	uint8_t *bytes = (uint8_t *)hb_scratch(slot, (size_t)count + 1);
	memcpy(bytes, &b->words[b->position], (size_t)count);
	b->position += (count + 3) / 4;
	return bytes;
}

void hb_wbytes(hb_buffer *b, const uint8_t *bytes, int32_t count) {
	int32_t words = (count + 3) / 4;
	hb_reserve(b, b->position + words);
	if (words > 0)
		b->words[b->position + words - 1] = 0;
	memcpy(&b->words[b->position], bytes, (size_t)count);
	b->position += words;
}

const char *hb_rs(hb_buffer *b, int slot) {
	int32_t length = hb_ri(b);
	if (length < 0)
		return NULL;
	char *s = (char *)hb_rbytes(b, length, slot);
	s[length] = 0;
	return s;
}

void hb_ws(hb_buffer *b, const char *s) {
	if (s == NULL) {
		hb_wi(b, -1);
		return;
	}
	int32_t length = (int32_t)strlen(s);
	hb_wi(b, length);
	hb_wbytes(b, (const uint8_t *)s, length);
}

HB_API void *hb_call_words(void) {
	hb_reserve(&hb_call, 1024);
	return hb_call.words;
}

HB_API int32_t hb_call_capacity(void) { return hb_call.capacity; }

HB_API void hb_call_reserve(int32_t words) { hb_reserve(&hb_call, words); }

HB_API void *hb_back_words(void) {
	hb_reserve(&hb_back, 1024);
	return hb_back.words;
}

HB_API int32_t hb_back_capacity(void) { return hb_back.capacity; }

HB_API void hb_back_reserve(int32_t words) { hb_reserve(&hb_back, words); }
