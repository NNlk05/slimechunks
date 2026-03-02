#include <stdint.h>
#include <stdbool.h>

bool is_slime_chunk(int64_t world_seed, int x_chunk, int z_chunk) {
    uint64_t slime_seed = world_seed + 
                         ((uint64_t)x_chunk * x_chunk * 0x4C1906) + 
                         ((uint64_t)x_chunk * 0x5AC0DB) + 
                         ((uint64_t)z_chunk * z_chunk * 0x4307A7) + 
                         ((uint64_t)z_chunk * 0x5F24F);

    uint64_t internal_state = (slime_seed ^ 0x5E434E432ULL) & 0xFFFFFFFFFFFFULL;
    
    uint64_t advanced_state = (internal_state * 0x5DEECE66DULL + 0xBULL) & 0xFFFFFFFFFFFFULL;

    return ((advanced_state >> 17) % 10) == 0;
}