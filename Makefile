CC = gcc
CFLAGS = -Wall -Wextra -O3
for-python: slimechunks.c
	$(CC) $(CFLAGS) -shared -o slimechunks.so -fPIC slimechunks.c
clean:
	rm -f slimechunks.so
.PHONY: clean