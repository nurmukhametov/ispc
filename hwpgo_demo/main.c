#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include "utils.h"

#define ARRAY_SIZE 10000000
#define ITERATIONS 50

// Function that's expensive when called (simulates cold cache miss)
static int __attribute__((noinline)) expensive_cold_function(int x) {
    volatile int result = 0;
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

// PURE BENCHMARK FUNCTION - NO PRINTING
static long long process_biased_branches(int *data, int size) {
    long long sum = 0;
    
    for (int i = 0; i < size; i++) {
        int value = data[i];
        
        if (value < 950000) {
            // 95% - hot path: cheap operation
            sum += cheap_hot_function(value);
            
            // Nested branch that's also highly predictable
            if (value < 500000) {
                sum += value >> 2;
            } else {
                sum += value >> 1;
            }
            
        } else if (value < 995000) {
            // 4.5% - cold path: expensive operation
            sum += expensive_cold_function(value);
            
        } else {
            // 0.5% - very cold path: very expensive
            sum += very_expensive_function(value);
        }
        
        // Additional unpredictable branch based on position
        if ((i % 100) < 92) {
            sum += 1;
        } else {
            sum += expensive_cold_function(i % 1000);
        }
    }
    
    return sum;
}

// PURE BENCHMARK FUNCTION - NO PRINTING
static long long process_random_branches(int *data, int size) {
    long long sum = 0;
    
    for (int i = 0; i < size; i++) {
        // Truly random pattern - should cause ~50% branch misprediction
        if (data[i] & 1) {
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

int main(int argc, char *argv[]) {
    // Check for silent mode
    int silent = (argc > 1 && strcmp(argv[1], "-s") == 0);
    
    int *data = malloc(ARRAY_SIZE * sizeof(int));
    if (!data) {
        return 1;
    }
    
    // Generate data with extreme bias for profiling
    generate_training_data_silent(data, ARRAY_SIZE);
    
    struct timespec start, end;
    
    // Test 1: Biased branches (should benefit from HWPGO)
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile long long result1 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result1 += process_biased_branches(data, ARRAY_SIZE);
        // Light shuffle to maintain bias but prevent cache effects
        if (i % 10 == 0) shuffle_training_data_silent(data, ARRAY_SIZE, i);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_biased = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    // Test 2: Random branches (high misprediction rate)
    generate_random_data_silent(data, ARRAY_SIZE);
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile long long result2 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result2 += process_random_branches(data, ARRAY_SIZE);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_random = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    // Results (only print if not silent)
    if (!silent) {
        printf("HWPGO Branch Misprediction Benchmark\n");
        printf("====================================\n");
        printf("Array size: %d elements, %d iterations\n\n", ARRAY_SIZE, ITERATIONS);
        
        printf("=== PERFORMANCE RESULTS ===\n");
        printf("Biased branches:  %.4f seconds (result: %lld)\n", elapsed_biased, result1);
        printf("Random branches:  %.4f seconds (result: %lld)\n", elapsed_random, result2);
        printf("Random/Biased ratio: %.2fx\n", elapsed_random / elapsed_biased);
        
        printf("\nExpected HWPGO improvement: 10-25%% on biased workload\n");
        printf("To measure branch mispredictions:\n");
        printf("perf stat -e branch-misses,branches ./program\n");
    } else {
        // Silent mode: only essential results
        printf("%.4f %.4f %lld %lld\n", elapsed_biased, elapsed_random, result1, result2);
    }
    
    free(data);
    return 0;
}