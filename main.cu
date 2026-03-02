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
                         ((uint64_t)z_chunk * 0x5F24F); [cite: 1, 2]

    uint64_t internal_state = (slime_seed ^ 0x5E434E432ULL) & 0xFFFFFFFFFFFFULL; [cite: 1, 2]
    uint64_t advanced_state = (internal_state * 0x5DEECE66DULL + 0xBULL) & 0xFFFFFFFFFFFFULL; [cite: 1, 2]

    return ((advanced_state >> 17) % 10) == 0; [cite: 1, 2]
}

__global__ void search_kernel(int64_t start_seed, int64_t batch_size, ChunkLocation* locs, int loc_count) {
    int64_t seed = start_seed + blockIdx.x * (int64_t)blockDim.x + threadIdx.x;
    if (seed >= start_seed + batch_size) return;

    for (int i = 0; i < loc_count; i++) {
        int match_count = 0;
        for (int dx = -2; dx <= 2; dx++) {
            for (int dz = -2; dz <= 2; dz++) {
                if (is_slime_chunk(seed, locs[i].x + dx, locs[i].z + dz)) {
                    match_count++;
                }
            }
        }
        
        // Reports if the area is very dense (20+/25) or a perfect 5x5 (25/25)
        if (match_count >= 20) {
            printf("Seed: %lld | Center: (%d, %d) | Matches: %d/25\n", 
                   (long long)seed, locs[i].x, locs[i].z, match_count);
        }
    }
}

int main() {
    std::vector<ChunkLocation> host_locs;
    const char* paths[] = {"likely_locations.txt", "slimechunks/likely_locations.txt"};
    std::ifstream file;

    for (const char* p : paths) {
        file.open(p);
        if (file.is_open()) break;
        file.clear();
    }

    if (!file.is_open()) {
        std::cerr << "Error: Could not find likely_locations.txt" << std::endl;
        return 1;
    }

    std::string line;
    while (std::getline(file, line)) {
        const char* x_ptr = strstr(line.c_str(), "x=");
        const char* z_ptr = strstr(line.c_str(), "z=");
        if (x_ptr && z_ptr) {
            ChunkLocation loc;
            sscanf(x_ptr, "x=%d", &loc.x);
            sscanf(z_ptr, "z=%d", &loc.z);
            host_locs.push_back(loc); [cite: 1, 2]
        }
    }

    ChunkLocation* device_locs;
    cudaMalloc(&device_locs, host_locs.size() * sizeof(ChunkLocation));
    cudaMemcpy(device_locs, host_locs.data(), host_locs.size() * sizeof(ChunkLocation), cudaMemcpyHostToDevice);

    int64_t total_seeds = 1000000000; 
    int64_t batch_size = 100000000; 
    int threads = 256;
    int blocks = (batch_size + threads - 1) / threads;

    for (int64_t start = 0; start < total_seeds; start += batch_size) {
        std::cout << "Status: Searching seeds " << start << " to " << start + batch_size << "..." << std::endl;
        
        search_kernel<<<blocks, threads>>>(start, batch_size, device_locs, (int)host_locs.size());
        
        cudaError_t err = cudaDeviceSynchronize();
        if (err != cudaSuccess) {
            std::cerr << "CUDA Error: " << cudaGetErrorString(err) << std::endl;
            break;
        }
    }

    cudaFree(device_locs);
    return 0;
}