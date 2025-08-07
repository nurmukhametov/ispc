#ifndef BLOCK_SIZE
#define BLOCK_SIZE 1024
#endif

#ifndef UNROLL_FACTOR
#define UNROLL_FACTOR 4
#endif

export void dot_product(uniform float a[], uniform float b[], uniform float result[],
                       uniform int n) {

  print("BLOCK_SIZE: % UNROLL_FACTOR: %\n", BLOCK_SIZE, UNROLL_FACTOR);
    
}
