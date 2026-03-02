#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstring>
#include <stdint.h>
#include <cuda_runtime.h>

struct ChunkLocation {
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

__global__ void search_kernel(int64_t total_seeds, ChunkLocation* locs, int loc_count) {
    int64_t seed = blockIdx.x * (int64_t)blockDim.x + threadIdx.x;
    if (seed >= total_seeds) return;

    for (int i = 0; i < loc_count; i++) {
        bool match = true;
        for (int dx = -2; dx <= 2; dx++) {
            for (int dz = -2; dz <= 2; dz++) {
                if (!is_slime_chunk(seed, locs[i].x + dx, locs[i].z + dz)) {
                    match = false;
                    break;
                }
            }
            if (!match) break;
        }
        if (match) {
            printf("Found seed: %lld at (%d, %d)\n", (long long)seed, locs[i].x, locs[i].z);
        }
    }
}

int main() {
    std::vector<ChunkLocation> host_locs;
    std::ifstream file("likely_locations.txt");
    std::string line;

    if (!file.is_open()) {
        std::cerr << "Error: Could not open likely_locations.txt" << std::endl;
        return 1;
    }

    while (std::getline(file, line)) {
        if (line.empty()) continue;
        
        const char* x_ptr = strstr(line.c_str(), "x=");
        const char* z_ptr = strstr(line.c_str(), "z=");
        
        if (x_ptr && z_ptr) {
            ChunkLocation loc;
            if (sscanf(x_ptr, "x=%d", &loc.x) == 1 && sscanf(z_ptr, "z=%d", &loc.z) == 1) {
                host_locs.push_back(loc);
            }
        }
    }

    if (host_locs.empty()) {
        std::cerr << "Error: No valid locations parsed." << std::endl;
        return 1;
    }

    ChunkLocation* device_locs;
    cudaMalloc(&device_locs, host_locs.size() * sizeof(ChunkLocation));
    cudaMemcpy(device_locs, host_locs.data(), host_locs.size() * sizeof(ChunkLocation), cudaMemcpyHostToDevice);

    int64_t total_seeds = 1000000;
    int threads = 256;
    int blocks = (total_seeds + threads - 1) / threads;

    search_kernel<<<blocks, threads>>>(total_seeds, device_locs, (int)host_locs.size());

    cudaDeviceSynchronize();
    cudaFree(device_locs);
    return 0;
}