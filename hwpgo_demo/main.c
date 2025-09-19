#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include "utils.h"

#define ARRAY_SIZE 50000000
#define ITERATIONS 20

// Extremely predictable hot function (99.9% taken)
static int __attribute__((noinline)) hot_function(int x) {
    // Complex computation that benefits from being inlined in hot path
    return x * 17 + 42 * x - 13 + (x >> 2) + (x << 1);
}

// Rarely called cold function (0.1% taken)  
static int __attribute__((noinline)) cold_function(int x) {
    // Complex computation that should NOT be inlined
    volatile int temp = 0;
    for (int i = 0; i < 100; i++) {
        temp += x * i + i * i;
    }
    return temp + x;
}

// Very cold function (virtually never called)
static int __attribute__((noinline)) very_cold_function(int x) {
    volatile int temp = 0;
    for (int i = 0; i < 1000; i++) {
        temp += x * i * i + i * i * i;
    }
    return temp;
}

// Another hot function for call target prediction
static int __attribute__((noinline)) hot_target_a(int x) {
    return x + 100;
}

static int __attribute__((noinline)) hot_target_b(int x) {
    return x + 200;  
}

static int __attribute__((noinline)) cold_target(int x) {
    return x + 1000;
}

// Function pointer array to create indirect call challenges
typedef int (*func_ptr_t)(int);
static func_ptr_t function_table[3] = {hot_target_a, hot_target_b, cold_target};

static int process_data_with_extreme_bias(int *data, int size) {
    long long sum = 0;
    int hot_calls = 0, cold_calls = 0, very_cold_calls = 0;
    
    for (int i = 0; i < size; i++) {
        int value = data[i];
        
        // Extreme branch bias: 99.9% goes to hot path
        if (value < 999000) {  // 99.9% of values
            sum += hot_function(value);
            hot_calls++;
            
            // Nested predictable branch for basic block layout optimization
            if (value < 500000) {  // 50% of total, 100% predictable given outer condition
                sum += value * 2;
            } else {
                sum += value * 3;
            }
            
            // Indirect call with heavy bias (95% hot_target_a, 4% hot_target_b, 1% cold_target)
            int func_index;
            if (value % 100 < 95) {
                func_index = 0;  // hot_target_a - 95%
            } else if (value % 100 < 99) {
                func_index = 1;  // hot_target_b - 4% 
            } else {
                func_index = 2;  // cold_target - 1%
            }
            sum += function_table[func_index](value);
            
        } else if (value < 999900) {  // 0.09% of values
            sum += cold_function(value);
            cold_calls++;
        } else {  // 0.01% of values
            sum += very_cold_function(value);
            very_cold_calls++;
        }
        
        // Another highly biased branch that should be optimized
        if (i % 1000 < 995) {  // 99.5% taken
            sum += 1;
        } else {
            sum += 1000;  // Expensive cold path
        }
    }
    
    printf("Call distribution: hot=%d (%.2f%%), cold=%d (%.4f%%), very_cold=%d (%.4f%%)\n",
           hot_calls, 100.0 * hot_calls / size,
           cold_calls, 100.0 * cold_calls / size, 
           very_cold_calls, 100.0 * very_cold_calls / size);
    
    return (int)(sum % INT32_MAX);
}

// Simple baseline for comparison
static int process_data_simple(int *data, int size) {
    long long sum = 0;
    for (int i = 0; i < size; i++) {
        sum += data[i];
    }
    return (int)(sum % INT32_MAX);
}

int main() {
    printf("EXTREME HWPGO Demo: Highly Biased Execution Patterns\n");
    printf("====================================================\n");
    printf("Array size: %d elements, %d iterations\n\n", ARRAY_SIZE, ITERATIONS);
    
    int *data = malloc(ARRAY_SIZE * sizeof(int));
    if (!data) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    
    // Generate extremely biased data that creates predictable patterns
    generate_extreme_bias_data(data, ARRAY_SIZE);
    
    struct timespec start, end;
    
    printf("Running complex branching workload...\n");
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile int result1 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result1 += process_data_with_extreme_bias(data, ARRAY_SIZE);
        // Shuffle slightly to prevent cache effects but maintain bias
        if (i % 5 == 0) shuffle_preserve_bias(data, ARRAY_SIZE, i);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_complex = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("\nRunning simple baseline workload...\n");
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile int result2 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result2 += process_data_simple(data, ARRAY_SIZE);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed_simple = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("\n=== PERFORMANCE RESULTS ===\n");
    printf("Complex branching: %.4f seconds (result: %d)\n", elapsed_complex, result1);
    printf("Simple baseline:   %.4f seconds (result: %d)\n", elapsed_simple, result2);
    printf("Branch overhead:   %.2fx slower than baseline\n", elapsed_complex / elapsed_simple);
    printf("Expected HWPGO benefit: 15-30%% improvement on complex workload\n\n");
    
    analyze_extreme_bias_patterns(data, ARRAY_SIZE);
    
    free(data);
    return 0;
}