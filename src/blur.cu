#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include "stb_image.h"
#include "stb_image_write.h"

// Gaussian blur kernel (5x5)
__global__ void blurKernel(unsigned char* input, unsigned char* output, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float blur[5][5] = {
            {1,  4,  6,  4,  1},
            {4, 16, 24, 16,  4},
            {6, 24, 36, 24,  6},
            {4, 16, 24, 16,  4},
            {1,  4,  6,  4,  1}
        };

        float r = 0, g = 0, b = 0;
        float weight = 0;

        for (int ky = -2; ky <= 2; ky++) {
            for (int kx = -2; kx <= 2; kx++) {
                int px = min(max(x + kx, 0), width - 1);
                int py = min(max(y + ky, 0), height - 1);
                int idx = (py * width + px) * 3;
                float w = blur[ky + 2][kx + 2];
                r += input[idx]     * w;
                g += input[idx + 1] * w;
                b += input[idx + 2] * w;
                weight += w;
            }
        }

        int outIdx = (y * width + x) * 3;
        output[outIdx]     = (unsigned char)(r / weight);
        output[outIdx + 1] = (unsigned char)(g / weight);
        output[outIdx + 2] = (unsigned char)(b / weight);
    }
}

int main() {
    int width, height, channels;
    unsigned char* img = stbi_load("../images/input.jpg", &width, &height, &channels, 3);
    if (!img) { printf("Failed to load image!\n"); return 1; }
    printf("Image loaded: %dx%d\n", width, height);

    int size = width * height * 3;

    unsigned char *d_input, *d_output;
    cudaMalloc(&d_input, size);
    cudaMalloc(&d_output, size);
    cudaMemcpy(d_input, img, size, cudaMemcpyHostToDevice);

    // Timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    dim3 blockSize(16, 16);
    dim3 gridSize((width + 15) / 16, (height + 15) / 16);
    blurKernel<<<gridSize, blockSize>>>(d_input, d_output, width, height);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);
    printf("GPU Blur time: %.2f ms\n", ms);

    unsigned char* output = new unsigned char[size];
    cudaMemcpy(output, d_output, size, cudaMemcpyDeviceToHost);
    stbi_write_jpg("../images/output_blur.jpg", width, height, 3, output, 100);
    printf("Saved output_blur.jpg\n");

    cudaFree(d_input);
    cudaFree(d_output);
    stbi_image_free(img);
    delete[] output;

    return 0;
}