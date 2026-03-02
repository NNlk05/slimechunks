from main import is_slime_chunk
from argparse import ArgumentParser

def print_map(seed, width, height, corner_coords):
    start_x, start_z = corner_coords
    for z in range(start_z, start_z + height):
        row_display = ""
        for x in range(start_x, start_x + width):
            if is_slime_chunk(seed, x, z):
                row_display += "S "
            else:
                row_display += ". "
        print(row_display)

if __name__ == "__main__":
    parser = ArgumentParser()
    
    parser.add_argument("-s", "--seed", type=int, help="The seed to map")
    parser.add_argument("-w", "-x", "--width", type=int, default=10, help="Width in chunks")
    parser.add_argument("-H", "-z", "--height", type=int, default=10, help="Height in chunks")
    parser.add_argument("-c", "--corner", nargs=2, type=int, default=(0, 0), help="Top-left chunk coordinates")
    
    args = parser.parse_args()
    
    if args.seed is not None:
        print_map(args.seed, args.width, args.height, args.corner)