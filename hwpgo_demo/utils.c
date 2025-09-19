#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "utils.h"

void generate_extreme_bias_data(int *data, int size) {
    srand(12345);  // Fixed seed for reproducible results
    
    for (int i = 0; i < size; i++) {
        int rand_val = rand();
        
        // Create extreme bias: 99.9% hot, 0.09% cold, 0.01% very cold
        if (i < size * 0.999) {
            // 99.9% - hot path values (0 to 998999)
            data[i] = rand_val % 999000;
        } else if (i < size * 0.9999) {
            // 0.09% - cold path values (999000 to 999899)  
            data[i] = 999000 + (rand_val % 900);
        } else {
            // 0.01% - very cold path values (999900+)
            data[i] = 999900 + (rand_val % 100);
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

void shuffle_preserve_bias(int *data, int size, int seed) {
    srand(seed + 42);
    
    // Light shuffle that maintains the bias distribution
    // Only shuffle within segments to preserve hot/cold ratios
    int segment_size = size / 100;
    
    for (int segment = 0; segment < 100; segment++) {
        int start = segment * segment_size;
        int end = (segment == 99) ? size : start + segment_size;
        
        // Shuffle within this segment only
        for (int i = end - 1; i > start; i--) {
            int j = start + (rand() % (i - start + 1));
            int temp = data[i];
            data[i] = data[j];
            data[j] = temp;
        }
    }
}

void analyze_extreme_bias_patterns(int *data, int size) {
    int hot_count = 0;
    int cold_count = 0; 
    int very_cold_count = 0;
    int total_transitions = 0;
    int hot_to_cold_transitions = 0;
    
    // Analyze distribution and transition patterns
    for (int i = 0; i < size; i++) {
        if (data[i] < 999000) {
            hot_count++;
        } else if (data[i] < 999900) {
            cold_count++;
        } else {
            very_cold_count++;
        }
        
        // Count hot->cold transitions (expensive for branch predictor)
        if (i > 0) {
            total_transitions++;
            bool prev_hot = (data[i-1] < 999000);
            bool curr_hot = (data[i] < 999000);
            if (prev_hot && !curr_hot) {
                hot_to_cold_transitions++;
            }
        }
    }
    
    printf("=== EXECUTION PATTERN ANALYSIS ===\n");
    printf("Data distribution:\n");
    printf("- Hot path (99.9%% expected):  %7d (%.3f%%) - FREQUENT\n", 
           hot_count, 100.0 * hot_count / size);
    printf("- Cold path (0.09%% expected): %7d (%.3f%%) - RARE\n", 
           cold_count, 100.0 * cold_count / size);
    printf("- Very cold (0.01%% expected): %7d (%.3f%%) - VERY RARE\n", 
           very_cold_count, 100.0 * very_cold_count / size);
    
    printf("\nBranch prediction challenges:\n");
    printf("- Total transitions: %d\n", total_transitions);
    printf("- Hot->Cold transitions: %d (%.3f%%)\n", 
           hot_to_cold_transitions, 100.0 * hot_to_cold_transitions / total_transitions);
    
    printf("\nExpected HWPGO optimizations:\n");
    printf("1. Basic block layout: Hot path kept together, cold moved away\n");
    printf("2. Function inlining: hot_function() likely inlined in hot path\n");
    printf("3. Indirect call prediction: hot_target_a preferred over cold_target\n");
    printf("4. Branch prediction hints: 99.9%% bias enables aggressive optimization\n");
    printf("5. Code size reduction: Cold functions moved to separate sections\n");
    
    printf("\nWhy this shows HWPGO benefits:\n");
    printf("- Without profile: Compiler assumes 50/50 branch probability\n");
    printf("- With HWPGO: Compiler knows 99.9%% bias, optimizes accordingly\n");
    printf("- Result: Better instruction cache usage, fewer branch mispredicts\n");
}

// Legacy functions for compatibility
void generate_biased_data(int *data, int size) {
    generate_extreme_bias_data(data, size);
}

void shuffle_array(int *data, int size, int seed) {
    shuffle_preserve_bias(data, size, seed);
}

void analyze_branch_patterns(int *data, int size) {
    analyze_extreme_bias_patterns(data, size);
}