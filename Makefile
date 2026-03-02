CC = gcc
CFLAGS = -Wall -Wextra -O3
for-python: slimechunkss.c
	$(CC) $(CFLAGS) -shared -o slimechunks.so -fPIC slimechunks.c
clean:
	rm -f slimechunks.so
.PHONY: clean