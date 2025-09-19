#ifndef UTILS_H
#define UTILS_H

#include <stdbool.h>

// New extreme bias functions for dramatic HWPGO demo
void generate_extreme_bias_data(int *data, int size);
void shuffle_preserve_bias(int *data, int size, int seed);
void analyze_extreme_bias_patterns(int *data, int size);

// Legacy functions for compatibility
void generate_biased_data(int *data, int size);
void shuffle_array(int *data, int size, int seed);
void analyze_branch_patterns(int *data, int size);

#endif