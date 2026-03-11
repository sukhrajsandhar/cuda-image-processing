# Benchmark Results

## Test Environment
- **Image Size:** 4000x6000 (24 megapixels)
- **GPU:** NVIDIA RTX 5070 Ti
- **CPU:** AMD Ryzen 9 9950X3D 16-Core Processor
- **CUDA Version:** 13.2

## Results

| Filter          | CPU Time    | GPU Time  | Speedup  |
|-----------------|-------------|-----------|----------|
| Gaussian Blur   | 2695.92 ms  | 19.45 ms  | 138x     |
| Edge Detection  | 715.90 ms   | 16.60 ms  | 43x      |

## Notes
- CPU benchmarks run single-threaded
- GPU times measured using CUDA events (excludes memory transfer)
- All filters tested on the same 24MP input image