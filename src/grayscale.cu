#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include "stb_image.h"
#include "stb_image_write.h"

__global__ void grayscaleKernel(unsigned char* input, unsigned char* output, int width, int height, int channels) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        int idx = (y * width + x) * channels;
        unsigned char r = input[idx];
        unsigned char g = input[idx + 1];
        unsigned char b = input[idx + 2];
        unsigned char gray = (unsigned char)(0.299f * r + 0.587f * g + 0.114f * b);
        output[idx]     = gray;
        output[idx + 1] = gray;
        output[idx + 2] = gray;
    }
}

int main() {
    int width, height, channels;
    unsigned char* img = stbi_load("../images/input.jpg", &width, &height, &channels, 3);
    if (!img) { printf("Failed to load image!\n"); return 1; }
    printf("Image loaded: %dx%d, %d channels\n", width, height, channels);

    int size = width * height * 3;

    unsigned char *d_input, *d_output;
    cudaMalloc(&d_input, size);
    cudaMalloc(&d_output, size);

    cudaMemcpy(d_input, img, size, cudaMemcpyHostToDevice);

    dim3 blockSize(16, 16);
    dim3 gridSize((width + 15) / 16, (height + 15) / 16);
    grayscaleKernel<<<gridSize, blockSize>>>(d_input, d_output, width, height, 3);

    unsigned char* output = new unsigned char[size];
    cudaMemcpy(output, d_output, size, cudaMemcpyDeviceToHost);

    stbi_write_jpg("../images/output_grayscale.jpg", width, height, 3, output, 100);
    printf("Saved output_grayscale.jpg\n");

    cudaFree(d_input);
    cudaFree(d_output);
    stbi_image_free(img);
    delete[] output;

    return 0;
}
