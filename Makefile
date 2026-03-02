CC = gcc
CFLAGS = -Wall -Wextra -O3

NVCC = nvcc
NVCCFLAGS = -O3

all: slime_finder for-python

slime_finder: main.cu
	$(NVCC) $(NVCCFLAGS) -o slime_finder main.cu

for-python: slimechunks.c
	$(CC) $(CFLAGS) -shared -o slimechunks.so -fPIC slimechunks.c

clean:
	rm -f slimechunks.so slime_finder

.PHONY: clean