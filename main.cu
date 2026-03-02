#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <cuda_runtime.h>

struct Location {
    int x;
    int z;
};

__device__ bool is_slime_chunk(int64_t world_seed, int x_chunk, int z_chunk) {
    uint64_t slime_seed = world_seed + 
                         ((uint64_t)x_chunk * x_chunk * 0x4C1906) + 
                         ((uint64_t)x_chunk * 0x5AC0DB) + 
                         ((uint64_t)z_chunk * z_chunk * 0x4307A7) + 
                         ((uint64_t)z_chunk * 0x5F24F);

    uint64_t internal_state = (slime_seed ^ 0x5E434E432ULL) & 0xFFFFFFFFFFFFULL;
    uint64_t advanced_state = (internal_state * 0x5DEECE66DULL + 0xBULL) & 0xFFFFFFFFFFFFULL;

    return ((advanced_state >> 17) % 10) == 0;
}

__global__ void find_seeds_kernel(int64_t start_seed, int64_t max_seeds, Location* locs, int loc_count) {
    int64_t seed = start_seed + blockIdx.x * blockDim.x + threadIdx.x;
    
    if (seed >= max_seeds) return;

    for (int i = 0; i < loc_count; i++) {
        bool all_match = true;
        
        for (int dx = -2; dx <= 2; dx++) {
            for (int dz = -2; dz <= 2; dz++) {
                if (!is_slime_chunk(seed, locs[i].x + dx, locs[i].z + dz)) {
                    all_match = false;
                    break;
                }
            }
            if (!all_match) break;
        }

        if (all_match) {
            printf("Found seed: %lld at (%d, %d)\n", (long long)seed, locs[i].x, locs[i].z);
        }
    }
}

int main() {
    [cite_start]// Extracted from likely_locations.txt [cite: 1]
    Location host_locations[] = {
        {94064, 1164393}, {-1005031, 1164393}, {449815, 1164393}, 
        {1228102, 1164393}, {-385824, 1164393}, {-98126, 1164393}
    };
    int loc_count = sizeof(host_locations) / sizeof(Location);

    Location* device_locations;
    cudaMalloc(&device_locations, sizeof(host_locations));
    cudaMemcpy(device_locations, host_locations, sizeof(host_locations), cudaMemcpyHostToDevice);

    int64_t total_seeds = 1000000;
    int threads_per_block = 256;
    int blocks_per_grid = (total_seeds + threads_per_block - 1) / threads_per_block;

    find_seeds_kernel<<<blocks_per_grid, threads_per_block>>>(0, total_seeds, device_locations, loc_count);

    cudaDeviceSynchronize();
    cudaFree(device_locations);

    return 0;
}