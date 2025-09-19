#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include "utils.h"

#define ARRAY_SIZE 10000000
#define ITERATIONS 100

static int process_data_with_branches(int *data, int size) {
    int sum = 0;
    int hot_path_count = 0;
    
    for (int i = 0; i < size; i++) {
        if (data[i] > 500000) {
            sum += data[i] * 2;
            hot_path_count++;
            if (data[i] > 750000) {
                sum += data[i] / 4;
                if (data[i] > 900000) {
                    sum -= data[i] / 8;
                }
            }
        } else if (data[i] > 100000) {
            sum += data[i];
            if (data[i] % 2 == 0) {
                sum += 1000;
            }
        } else {
            sum += data[i] / 2;
        }
    }
    
    return sum;
}

static int process_data_simple(int *data, int size) {
    int sum = 0;
    for (int i = 0; i < size; i++) {
        sum += data[i];
    }
    return sum;
}

int main() {
    printf("HWPGO Demo: Branching Performance Test\n");
    printf("=====================================\n");
    
    int *data = malloc(ARRAY_SIZE * sizeof(int));
    if (!data) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    
    generate_biased_data(data, ARRAY_SIZE);
    
    struct timespec start, end;
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile int result1 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result1 += process_data_with_branches(data, ARRAY_SIZE);
        shuffle_array(data, ARRAY_SIZE, i);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    double elapsed_complex = (end.tv_sec - start.tv_sec) + 
                            (end.tv_nsec - start.tv_nsec) / 1e9;
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    volatile int result2 = 0;
    for (int i = 0; i < ITERATIONS; i++) {
        result2 += process_data_simple(data, ARRAY_SIZE);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    double elapsed_simple = (end.tv_sec - start.tv_sec) + 
                           (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("Complex branching: %.4f seconds (result: %d)\n", 
           elapsed_complex, result1);
    printf("Simple loop:       %.4f seconds (result: %d)\n", 
           elapsed_simple, result2);
    printf("Branch overhead:   %.2fx slower\n", 
           elapsed_complex / elapsed_simple);
    
    analyze_branch_patterns(data, ARRAY_SIZE);
    
    free(data);
    return 0;
}