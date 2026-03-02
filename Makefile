CC = gcc
CFLAGS = -Wall -Wextra -O3
for-python: slimechunk.c
	$(CC) $(CFLAGS) -shared -o slimechunk.so -fPIC slimechunk.c
.PHONY: clean