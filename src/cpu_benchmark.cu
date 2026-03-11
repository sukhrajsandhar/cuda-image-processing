#define STB_IMAGE_IMPLEMENTATION
#include <stdio.h>
#include <math.h>
#include <chrono>
#include "stb_image.h"

void cpuBlur(unsigned char* input, unsigned char* output, int width, int height) {
    float blur[5][5] = {
        {1,  4,  6,  4,  1},
        {4, 16, 24, 16,  4},
        {6, 24, 36, 24,  6},
        {4, 16, 24, 16,  4},
        {1,  4,  6,  4,  1}
    };
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            float r = 0, g = 0, b = 0, weight = 0;
            for (int ky = -2; ky <= 2; ky++) {
                for (int kx = -2; kx <= 2; kx++) {
                    int px = min(max(x + kx, 0), width - 1);
                    int py = min(max(y + ky, 0), height - 1);
                    int idx = (py * width + px) * 3;
                    float w = blur[ky+2][kx+2];
                    r += input[idx] * w;
                    g += input[idx+1] * w;
                    b += input[idx+2] * w;
                    weight += w;
                }
            }
            int outIdx = (y * width + x) * 3;
            output[outIdx]     = (unsigned char)(r / weight);
            output[outIdx + 1] = (unsigned char)(g / weight);
            output[outIdx + 2] = (unsigned char)(b / weight);
        }
    }
}

void cpuEdge(unsigned char* input, unsigned char* output, int width, int height) {
    int sobelX[3][3] = {{-1,0,1},{-2,0,2},{-1,0,1}};
    int sobelY[3][3] = {{-1,-2,-1},{0,0,0},{1,2,1}};
    for (int y = 1; y < height-1; y++) {
        for (int x = 1; x < width-1; x++) {
            float gx = 0, gy = 0;
            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    int idx = ((y+ky) * width + (x+kx)) * 3;
                    float gray = 0.299f*input[idx] + 0.587f*input[idx+1] + 0.114f*input[idx+2];
                    gx += gray * sobelX[ky+1][kx+1];
                    gy += gray * sobelY[ky+1][kx+1];
                }
            }
            unsigned char edge = (unsigned char)min(sqrtf(gx*gx + gy*gy), 255.0f);
            int outIdx = (y * width + x) * 3;
            output[outIdx] = output[outIdx+1] = output[outIdx+2] = edge;
        }
    }
}

int main() {
    int width, height, channels;
    unsigned char* img = stbi_load("../images/input.jpg", &width, &height, &channels, 3);
    if (!img) { printf("Failed to load image!\n"); return 1; }
    printf("Image loaded: %dx%d\n", width, height);

    int size = width * height * 3;
    unsigned char* output = new unsigned char[size];

    auto start = std::chrono::high_resolution_clock::now();
    cpuBlur(img, output, width, height);
    auto end = std::chrono::high_resolution_clock::now();
    float blurMs = std::chrono::duration<float, std::milli>(end - start).count();
    printf("CPU Blur time:           %.2f ms\n", blurMs);

    start = std::chrono::high_resolution_clock::now();
    cpuEdge(img, output, width, height);
    end = std::chrono::high_resolution_clock::now();
    float edgeMs = std::chrono::duration<float, std::milli>(end - start).count();
    printf("CPU Edge Detection time: %.2f ms\n", edgeMs);

    delete[] output;
    return 0;
}