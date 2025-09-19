#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include "utils.h"

#define ARRAY_SIZE 10000000
#define ITERATIONS 50

// Based on research: branch misprediction causes 14-25 cycle penalty
// We need truly unpredictable patterns for the baseline case

// Function that's expensive when called (simulates cold cache miss)
static int __attribute__((noinline)) expensive_cold_function(int x) {
    volatile int result = 0;
    // Simulate memory-intensive work that would benefit from being avoided
    for (int i = 0; i < 50; i++) {
        result += x * i + i * i * i;
    }
    return result;
}

// Cheap hot function that should be inlined/optimized
static int __attribute__((noinline)) cheap_hot_function(int x) {
    return x + 42;
}

// Very expensive function that should almost never be called
static int __attribute__((noinline)) very_expensive_function(int x) {
    volatile int result = 0;
    for (int i = 0; i < 200; i++) {
        result += x * i * i + i * i * i;
    }
    return result;
}

// The key insight: create patterns that are predictable during profiling
// but appear random to the compiler without profile data
static long long process_biased_branches(int *data, int size, int mode) {
    long long sum = 0;
    int cold_calls = 0, hot_calls = 0, very_cold_calls = 0;
    
    for (int i = 0; i < size; i++) {
        int value = data[i];
        
        // Mode 0: Training pattern (highly predictable - 95% hot path)
        // Mode 1: Similar pattern for actual benchmark
        int threshold1 = (mode == 0) ? 950000 : 950000;  // 95% threshold
        int threshold2 = (mode == 0) ? 995000 : 995000;  // 99.5% threshold
        
        if (value < threshold1) {
            // 95% - hot path: cheap operation
            sum += cheap_hot_function(value);
            hot_calls++;
            
            // Nested branch that's also highly predictable
            if (value < 500000) {  // 50% of hot path
                sum += value >> 2;  // Cheap bit operation
            } else {
                sum += value >> 1;  // Slightly different cheap operation
            }
            
        } else if (value < threshold2) {
            // 4.5% - cold path: expensive operation
            sum += expensive_cold_function(value);
            cold_calls++;
            
        } else {
            // 0.5% - very cold path: very expensive
            sum += very_expensive_function(value);
            very_cold_calls++;
        }
        
        // Additional unpredictable branch based on position
        // This creates pattern that profile can optimize but baseline cannot
        if ((i % 100) < 92) {  // 92% predictable
            sum += 1;
        } else {
            sum += expensive_cold_function(i % 1000);  // Expensive cold path
        }
    }
    
    printf("Mode %d calls: hot=%d (%.1f%%), cold=%d (%.1f%%), very_cold=%d (%.1f%%)\n",
           mode, hot_calls, 100.0 * hot_calls / size,
           cold_calls, 100.0 * cold_calls / size,
           very_cold_calls, 100.0 * very_cold_calls / size);
    
    return sum;
}

// Create truly random branches that cause 50% misprediction
static long long process_random_branches(int *data, int size) {
    long long sum = 0;
    
    for (int i = 0; i < size; i++) {
        // Truly random pattern - should cause ~50% branch misprediction
        if (data[i] & 1) {  // Random bit - 50/50 chance
            sum += expensive_cold_function(data[i]);
        } else {
            sum += cheap_hot_function(data[i]);
        }
        
        // Another random branch
        if ((data[i] >> 1) & 1) {
            sum += data[i] * 3;
        } else {
            sum += data[i] * 2;
        }
    }
    
    return sum;
}

int main() {
    printf("HWPGO Branch Misprediction Benchmark\n");
    printf("====================================\n");
    printf("Array size: %d elements, %d iterations\n", ARRAY_SIZE, ITERATIONS);
    printf("Target: Show HWPGO benefits through branch prediction optimization\n\n");
    
    int *data = malloc(ARRAY_SIZE * sizeof(int));
    if (!data) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    
    // Generate data with extreme bias for profiling
    generate_training_data(data, ARRAY_SIZE);
    
    struct timespec start, end;
    
    // Test 1: Biased branches (should benefit from HWPGO)
    printf("=== Test 1: Highly Biased Branches (95%% hot path) ===\n");
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile long long result1 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result1 += process_biased_branches(data, ARRAY_SIZE, 0);
        // Light shuffle to maintain bias but prevent cache effects
        if (i % 10 == 0) shuffle_training_data(data, ARRAY_SIZE, i);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_biased = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    // Test 2: Random branches (high misprediction rate)
    printf("\n=== Test 2: Random Branches (50%% misprediction expected) ===\n");
    generate_random_data(data, ARRAY_SIZE);
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile long long result2 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result2 += process_random_branches(data, ARRAY_SIZE);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_random = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("\n=== PERFORMANCE RESULTS ===\n");
    printf("Biased branches:  %.4f seconds (result: %lld)\n", elapsed_biased, result1);
    printf("Random branches:  %.4f seconds (result: %lld)\n", elapsed_random, result2);
    printf("Random/Biased ratio: %.2fx\n", elapsed_random / elapsed_biased);
    
    printf("\n=== HWPGO EXPECTATIONS ===\n");
    printf("Without HWPGO: Compiler assumes branches are 50/50\n");
    printf("  - Suboptimal basic block layout\n");
    printf("  - Conservative inlining decisions\n");
    printf("  - No branch probability hints\n");
    printf("With HWPGO: Compiler knows 95%% bias from profile\n");
    printf("  - Hot path optimized for instruction cache\n");
    printf("  - Aggressive inlining of hot functions\n");
    printf("  - Cold code moved to separate sections\n");
    printf("  - Branch prediction hints inserted\n");
    printf("Expected improvement: 10-25%% on biased workload\n");
    
    printf("\nTo measure branch mispredictions:\n");
    printf("perf stat -e branch-misses,branches ./hwpgo_demo_baseline\n");
    printf("perf stat -e branch-misses,branches ./hwpgo_demo_hwpgo\n");
    
    analyze_training_patterns(data, ARRAY_SIZE);
    
    free(data);
    return 0;
}