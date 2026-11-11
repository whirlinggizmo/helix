# Builds the game natively: every .c here, against raylib 5.5's desktop library (OpenGL 3.3), into native/wardens. It reads assets/
# (and shaders/) from this directory, its working directory when run.
CFLAGS = -O2 -std=c99 -D_GNU_SOURCE -Wall -DPLATFORM_DESKTOP

native/wardens: $(wildcard *.c) $(wildcard *.h)
	mkdir -p native
	$(CC) $(CFLAGS) -I include $(wildcard *.c) lib/libraylib.a -lGL -lm -lpthread -ldl -lrt -lX11 -o $@
