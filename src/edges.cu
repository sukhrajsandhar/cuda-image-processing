#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include <math.h>
#include "stb_image.h"
#include "stb_image_write.h"

__global__ void edgeKernel(unsigned char* input, unsigned char* output, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= 1 && x < width - 1 && y >= 1 && y < height - 1) {

        int sobelX[3][3] = {{-1, 0, 1}, {-2, 0, 2}, {-1, 0, 1}};
        int sobelY[3][3] = {{-1,-2,-1}, { 0, 0, 0}, { 1, 2, 1}};

        float gx = 0, gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
            for (int kx = -1; kx <= 1; kx++) {
                int idx = ((y + ky) * width + (x + kx)) * 3;

                float gray = 0.299f * input[idx] + 
                             0.587f * input[idx+1] + 
                             0.114f * input[idx+2];
                gx += gray * sobelX[ky+1][kx+1];
                gy += gray * sobelY[ky+1][kx+1];
            }
        }

        unsigned char edge = (unsigned char)min(sqrtf(gx*gx + gy*gy), 255.0f);
        int outIdx = (y * width + x) * 3;
        output[outIdx]     = edge;
        output[outIdx + 1] = edge;
        output[outIdx + 2] = edge;
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

    cudaMemset(d_output, 0, size);
    cudaMemcpy(d_input, img, size, cudaMemcpyHostToDevice);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    dim3 blockSize(16, 16);
    dim3 gridSize((width + 15) / 16, (height + 15) / 16);
    edgeKernel<<<gridSize, blockSize>>>(d_input, d_output, width, height);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);
    printf("GPU Edge Detection time: %.2f ms\n", ms);

    unsigned char* output = new unsigned char[size];
    cudaMemcpy(output, d_output, size, cudaMemcpyDeviceToHost);
    stbi_write_jpg("../images/output_edges.jpg", width, height, 3, output, 100);
    printf("Saved output_edges.jpg\n");

    cudaFree(d_input);
    cudaFree(d_output);
    stbi_image_free(img);
    delete[] output;

    return 0;
}