#ifndef UTILS_H
#define UTILS_H

#include <stdbool.h>

// Silent versions for pure benchmarking (no printf during timing)
void generate_training_data_silent(int *data, int size);
void generate_random_data_silent(int *data, int size);
void shuffle_training_data_silent(int *data, int size, int seed);

// Regular versions for analysis/debugging
void generate_training_data(int *data, int size);
void generate_random_data(int *data, int size);
void shuffle_training_data(int *data, int size, int seed);
void analyze_training_patterns(int *data, int size);

// Legacy functions for compatibility
void generate_extreme_bias_data(int *data, int size);
void shuffle_preserve_bias(int *data, int size, int seed);
void analyze_extreme_bias_patterns(int *data, int size);
void generate_biased_data(int *data, int size);
void shuffle_array(int *data, int size, int seed);
void analyze_branch_patterns(int *data, int size);

#endif