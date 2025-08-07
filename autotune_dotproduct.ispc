#ifndef BLOCK_SIZE
#define BLOCK_SIZE 1024
#endif

#ifndef UNROLL_FACTOR
#define UNROLL_FACTOR 4
#endif

export void dot_product(uniform float a[], uniform float b[], uniform float result[],
                       uniform int n) {
    
    varying float partial_sum = 0.0f;
    
    for (uniform int i = 0; i < n; i += BLOCK_SIZE) {
        uniform int block_end = min(i + BLOCK_SIZE, n);
        
        for (uniform int j = i; j < block_end; j += programCount * UNROLL_FACTOR) {
            varying float sum[UNROLL_FACTOR];
            
            #pragma unroll
            for (uniform int u = 0; u < UNROLL_FACTOR; u++) {
                sum[u] = 0.0f;
            }
            
            #pragma unroll
            for (uniform int u = 0; u < UNROLL_FACTOR; u++) {
                varying int idx = j + programIndex + u * programCount;
                if (idx < block_end) {
                    sum[u] = a[idx] * b[idx];
                }
            }
            
            #pragma unroll
            for (uniform int u = 0; u < UNROLL_FACTOR; u++) {
                partial_sum += sum[u];
            }
        }
    }
    
    result[programIndex] = partial_sum;
}
