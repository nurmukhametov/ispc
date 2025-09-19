#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "utils.h"

// SILENT versions - no printing during benchmark
void generate_training_data_silent(int *data, int size) {
    srand(12345);
    
    for (int i = 0; i < size; i++) {
        int rand_val = rand();
        
        if (i < size * 0.95) {
            data[i] = rand_val % 950000;
        } else if (i < size * 0.995) {
            data[i] = 950000 + (rand_val % 45000);
        } else {
            data[i] = 995000 + (rand_val % 5000);
        }
    }
    
    for (int i = size - 1; i > 0; i--) {
        int j = rand() % (i + 1);
        int temp = data[i];
        data[i] = data[j];
        data[j] = temp;
    }
}

void generate_random_data_silent(int *data, int size) {
    srand(54321);
    
    for (int i = 0; i < size; i++) {
        data[i] = rand();
    }
}

void shuffle_training_data_silent(int *data, int size, int seed) {
    srand(seed + 777);
    
    int segment_size = size / 50;
    
    for (int segment = 0; segment < 50; segment++) {
        int start = segment * segment_size;
        int end = (segment == 49) ? size : start + segment_size;
        
        for (int i = end - 1; i > start; i--) {
            int j = start + (rand() % (i - start + 1));
            int temp = data[i];
            data[i] = data[j];
            data[j] = temp;
        }
    }
}

// Legacy functions that still print (for debugging)
void generate_training_data(int *data, int size) {
    generate_training_data_silent(data, size);
}

void generate_random_data(int *data, int size) {
    generate_random_data_silent(data, size);
}

void shuffle_training_data(int *data, int size, int seed) {
    shuffle_training_data_silent(data, size, seed);
}

void analyze_training_patterns(int *data, int size) {
    int hot_count = 0;
    int cold_count = 0; 
    int very_cold_count = 0;
    int transitions = 0;
    
    for (int i = 0; i < size; i++) {
        if (data[i] < 950000) {
            hot_count++;
        } else if (data[i] < 995000) {
            cold_count++;
        } else {
            very_cold_count++;
        }
        
        if (i > 0) {
            bool prev_hot = (data[i-1] < 950000);
            bool curr_hot = (data[i] < 950000);
            if (prev_hot != curr_hot) {
                transitions++;
            }
        }
    }
    
    printf("\n=== TRAINING DATA ANALYSIS ===\n");
    printf("Distribution: Hot=%.2f%%, Cold=%.2f%%, Very Cold=%.2f%%\n",
           100.0 * hot_count / size, 100.0 * cold_count / size, 
           100.0 * very_cold_count / size);
    printf("Transitions: %d (%.3f%%)\n", transitions, 100.0 * transitions / size);
    printf("Expected HWPGO benefit: 10-25%% improvement\n");
}

// All other legacy functions redirect to silent versions
void generate_extreme_bias_data(int *data, int size) {
    generate_training_data_silent(data, size);
}

void shuffle_preserve_bias(int *data, int size, int seed) {
    shuffle_training_data_silent(data, size, seed);
}

void analyze_extreme_bias_patterns(int *data, int size) {
    analyze_training_patterns(data, size);
}

void generate_biased_data(int *data, int size) {
    generate_training_data_silent(data, size);
}

void shuffle_array(int *data, int size, int seed) {
    shuffle_training_data_silent(data, size, seed);
}

void analyze_branch_patterns(int *data, int size) {
    analyze_training_patterns(data, size);
}