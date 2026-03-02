CC = gcc
CFLAGS = -Wall -Wextra -O3
for-python: slimechunks.c
	$(CC) $(CFLAGS) -shared -o slimechunk.so -fPIC slimechunk.c
clean:
	rm -f slimechunk.so
.PHONY: clean