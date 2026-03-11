# CUDA Image Processing Pipeline

A GPU-accelerated image processing pipeline built with CUDA C++, demonstrating 
massive performance gains over CPU implementations on real-world image data.

## Results

| Filter          | CPU Time    | GPU Time  | Speedup  |
|-----------------|-------------|-----------|----------|
| Gaussian Blur   | 2695.92 ms  | 19.45 ms  | **138x** |
| Edge Detection  | 715.90 ms   | 16.60 ms  | **43x**  |

> Tested on a 4000x6000 (24 megapixel) image
> CPU: AMD Ryzen 9 9950X3D | GPU: NVIDIA RTX 5070 Ti | CUDA 13.2

## Features

- **Grayscale conversion** — parallel RGB to grayscale using luminance weights
- **Gaussian blur** — 5x5 convolution kernel with weighted sampling
- **Edge detection** — Sobel operator detecting horizontal and vertical gradients
- **CPU vs GPU benchmarking** — CUDA event timing vs std::chrono

## How It Works

Each CUDA kernel assigns one GPU thread per pixel, allowing millions of pixels 
to be processed simultaneously. A 4000x6000 image spawns ~24 million threads 
running in parallel on the GPU.

## Project Structure
```
cuda-image-processing/
├── src/
│   ├── grayscale.cu       # Grayscale kernel
│   ├── blur.cu            # Gaussian blur kernel  
│   ├── edges.cu           # Edge detection kernel
│   └── cpu_benchmark.cu   # CPU baseline timing
├── images/
│   ├── input.jpg
│   ├── output_grayscale.jpg
│   ├── output_blur.jpg
│   └── output_edges.jpg
├── benchmarks/
│   └── results.md
└── README.md
```

## Requirements

- NVIDIA GPU (CUDA capable)
- CUDA Toolkit 12+
- Visual Studio Build Tools 2022

## Build & Run
```bash
cd src
nvcc grayscale.cu -o grayscale.exe && grayscale.exe
nvcc blur.cu -o blur.exe && blur.exe
nvcc edges.cu -o edges.exe && edges.exe
nvcc cpu_benchmark.cu -o cpu_benchmark.exe && cpu_benchmark.exe
```