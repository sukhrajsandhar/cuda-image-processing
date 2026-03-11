#include <stdio.h>

__global__ void helloGPU() {
    printf("Hello from GPU thread %d\n", threadIdx.x);
}

int main() {
    helloGPU<<<1, 10>>>();
    cudaDeviceSynchronize();
    return 0;
}