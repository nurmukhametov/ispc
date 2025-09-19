#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "utils.h"

void generate_training_data(int *data, int size) {
    srand(12345);  // Fixed seed for reproducible profiling
    
    for (int i = 0; i < size; i++) {
        int rand_val = rand();
        
        // Create 95/4.5/0.5 distribution for dramatic bias
        if (i < size * 0.95) {
            // 95% - hot path values (0 to 949999)
            data[i] = rand_val % 950000;
        } else if (i < size * 0.995) {
            // 4.5% - cold path values (950000 to 994999)  
            data[i] = 950000 + (rand_val % 45000);
        } else {
            // 0.5% - very cold path values (995000+)
            data[i] = 995000 + (rand_val % 5000);
        }
    }
    
    // Shuffle to distribute bias throughout array while preserving ratios
    for (int i = size - 1; i > 0; i--) {
        int j = rand() % (i + 1);
        int temp = data[i];
        data[i] = data[j];
        data[j] = temp;
    }
}

void generate_random_data(int *data, int size) {
    srand(54321);  // Different seed for random data
    
    for (int i = 0; i < size; i++) {
        data[i] = rand();  // Completely random values
    }
}

void shuffle_training_data(int *data, int size, int seed) {
    srand(seed + 777);
    
    // Light shuffle that maintains the bias distribution
    // Only shuffle within segments to preserve hot/cold ratios
    int segment_size = size / 50;  // 50 segments
    
    for (int segment = 0; segment < 50; segment++) {
        int start = segment * segment_size;
        int end = (segment == 49) ? size : start + segment_size;
        
        // Shuffle within this segment only
        for (int i = end - 1; i > start; i--) {
            int j = start + (rand() % (i - start + 1));
            int temp = data[i];
            data[i] = data[j];
            data[j] = temp;
        }
    }
}

void analyze_training_patterns(int *data, int size) {
    int hot_count = 0;
    int cold_count = 0; 
    int very_cold_count = 0;
    int transitions = 0;
    
    // Analyze distribution and transition patterns
    for (int i = 0; i < size; i++) {
        if (data[i] < 950000) {
            hot_count++;
        } else if (data[i] < 995000) {
            cold_count++;
        } else {
            very_cold_count++;
        }
        
        // Count transitions between hot and cold
        if (i > 0) {
            bool prev_hot = (data[i-1] < 950000);
            bool curr_hot = (data[i] < 950000);
            if (prev_hot != curr_hot) {
                transitions++;
            }
        }
    }
    
    printf("\n=== TRAINING DATA ANALYSIS ===\n");
    printf("Distribution (for profile training):\n");
    printf("- Hot path (95%% target):    %7d (%.2f%%) - VERY FREQUENT\n", 
           hot_count, 100.0 * hot_count / size);
    printf("- Cold path (4.5%% target):  %7d (%.2f%%) - RARE\n", 
           cold_count, 100.0 * cold_count / size);
    printf("- Very cold (0.5%% target):  %7d (%.2f%%) - VERY RARE\n", 
           very_cold_count, 100.0 * very_cold_count / size);
    
    printf("\nBranch characteristics:\n");
    printf("- Hot/Cold transitions: %d (%.3f%% of elements)\n", 
           transitions, 100.0 * transitions / size);
    printf("- Predictability: %.1f%% (excellent for branch predictor)\n",
           100.0 * hot_count / size);
    
    printf("\nWhy this should show HWPGO benefits:\n");
    printf("1. Extreme bias (95%%) gives profile clear optimization signal\n");
    printf("2. Without profile: compiler assumes balanced 50/50 branches\n");
    printf("3. With profile: compiler optimizes for 95%% hot path\n");
    printf("4. Branch prediction becomes much more accurate\n");
    printf("5. Hot functions get inlined, cold ones get moved away\n");
    printf("6. Instruction cache benefits from better layout\n");
    
    printf("\nBranch misprediction impact:\n");
    printf("- Cost: 14-25 CPU cycles per misprediction\n");
    printf("- Target: <1%% miss rate for optimal performance\n");
    printf("- HWPGO should dramatically improve miss rate on biased workload\n");
}

// Legacy compatibility functions
void generate_extreme_bias_data(int *data, int size) {
    generate_training_data(data, size);
}

void shuffle_preserve_bias(int *data, int size, int seed) {
    shuffle_training_data(data, size, seed);
}

void analyze_extreme_bias_patterns(int *data, int size) {
    analyze_training_patterns(data, size);
}

void generate_biased_data(int *data, int size) {
    generate_training_data(data, size);
}

void shuffle_array(int *data, int size, int seed) {
    shuffle_training_data(data, size, seed);
}

void analyze_branch_patterns(int *data, int size) {
    analyze_training_patterns(data, size);
}