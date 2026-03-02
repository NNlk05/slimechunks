import ctypes
import pathlib
import csv

lib_path = pathlib.Path(__file__).parent / 'slimechunks.so'
if not lib_path.exists():
    raise FileNotFoundError(f"Compiled library not found: {lib_path}, try running 'make for-python' to compile it.")

lib = ctypes.cdll.LoadLibrary(str(lib_path))

def is_slime_chunk(seed: int, x: int, z: int) -> bool:
    return bool(lib.is_slime_chunk(ctypes.c_long(seed), ctypes.c_int(x), ctypes.c_int(z)))

with open("likely_locations.txt", "r") as f:
    reader = csv.reader(f, delimiter=' ')
    most_likely_locations = []
    for row in reader:
        x, z = row[0].split('=')[1], row[1].split('=')[1]
        most_likely_locations.append((int(x), int(z)))

def main(is_slime_chunk, most_likely_locations):
    for seed in range(1000000):
        for x, z in most_likely_locations:
            if is_slime_chunk(seed, x, z):
                all_slime_chunks = True
                for dx in range(-2, 3):
                    for dz in range(-2, 3):
                        if not is_slime_chunk(seed, x + dx, z + dz):
                            all_slime_chunks = False
                            break
                    if not all_slime_chunks:
                        break
                if all_slime_chunks:
                    print(f"Found seed: {seed} with slime chunk at ({x}, {z}) and surrounding 5x5 area.")
                    break
        else:
            continue
        break
if __name__ == "__main__":
    main(is_slime_chunk, most_likely_locations)