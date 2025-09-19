# HWPGO Demo

This demo shows performance improvements from Hardware-based Profile-Guided Optimization (HWPGO) in Clang.

## What it demonstrates

- **Biased branching patterns**: 70% of data takes the "hot path" through complex nested branches
- **Branch misprediction costs**: Shows overhead of unpredictable branches vs simple loops
- **HWPGO optimization**: Uses hardware performance counters to optimize for actual execution patterns

## Files

- `main.c` - Main program with branching-heavy algorithm
- `utils.c` - Data generation and analysis functions  
- `utils.h` - Header file
- `Makefile` - Build system with HWPGO support

## Requirements

- Clang with HWPGO support
- Linux `perf` tools
- `llvm-profgen` utility

## Quick Start

```bash
# Build and test both versions
make clean && make hwpgo && make test

# Performance comparison
make benchmark
```

## Step-by-step

```bash
# 1. Build baseline version (no PGO)
make baseline

# 2. Build instrumented version and collect hardware profile
make profile    # Creates perf.data and profile.prof

# 3. Build HWPGO-optimized version
make hwpgo

# 4. Compare performance
make test
```

## Expected Results

The HWPGO version should show:
- Better branch prediction (fewer mispredicts)
- Optimized code layout for hot paths
- 5-15% performance improvement on the complex branching workload

## How it works

1. **Data pattern**: 70% of values > 500k (hot path), 20% medium, 10% low
2. **Without HWPGO**: Compiler doesn't know which branches are hot
3. **With HWPGO**: Hardware counters show real branch frequencies
4. **Optimization**: Compiler optimizes for the 70% hot path case