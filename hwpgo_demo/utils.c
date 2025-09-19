#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "utils.h"

void generate_biased_data(int *data, int size) {
    srand(42);
    
    for (int i = 0; i < size; i++) {
        int rand_val = rand();
        
        if (i < size * 0.7) {
            data[i] = 600000 + (rand_val % 300000);
        } else if (i < size * 0.9) {
            data[i] = 200000 + (rand_val % 200000);
        } else {
            data[i] = rand_val % 100000;
        }
    }
}

void shuffle_array(int *data, int size, int seed) {
    srand(seed + 1000);
    
    for (int i = size - 1; i > 0; i--) {
        int j = rand() % (i + 1);
        int temp = data[i];
        data[i] = data[j];
        data[j] = temp;
    }
}

void analyze_branch_patterns(int *data, int size) {
    int high_values = 0;
    int medium_values = 0;
    int low_values = 0;
    int very_high_values = 0;
    int ultra_high_values = 0;
    
    for (int i = 0; i < size; i++) {
        if (data[i] > 900000) {
            ultra_high_values++;
            very_high_values++;
            high_values++;
        } else if (data[i] > 750000) {
            very_high_values++;
            high_values++;
        } else if (data[i] > 500000) {
            high_values++;
        } else if (data[i] > 100000) {
            medium_values++;
        } else {
            low_values++;
        }
    }
    
    printf("\nBranch Pattern Analysis:\n");
    printf("- High values (>500k):      %7d (%.1f%%) - HOT PATH\n", 
           high_values, 100.0 * high_values / size);
    printf("- Very high (>750k):        %7d (%.1f%%) - nested branch\n", 
           very_high_values, 100.0 * very_high_values / size);
    printf("- Ultra high (>900k):       %7d (%.1f%%) - deep nested\n", 
           ultra_high_values, 100.0 * ultra_high_values / size);
    printf("- Medium values (100-500k): %7d (%.1f%%) - cold path\n", 
           medium_values, 100.0 * medium_values / size);
    printf("- Low values (<100k):       %7d (%.1f%%) - cold path\n", 
           low_values, 100.0 * low_values / size);
    
    printf("\nExpected HWPGO benefits:\n");
    printf("- Main branch (>500k) is taken %.1f%% of the time\n", 
           100.0 * high_values / size);
    printf("- HWPGO should optimize for this hot path\n");
    printf("- Branch predictor training from real execution patterns\n");
}