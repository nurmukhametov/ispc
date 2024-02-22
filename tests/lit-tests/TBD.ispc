// RUN: %{ispc} -DISPC -O2 --pic --target=avx2-i32x8 -h %t.h %s -o %t.o -g
// RUN: %{cc} -x c -c %s -o %t.c.o --include %t.h -gdwarf-4 -g3 -ggdb
// RUN: %{cc} %t.o %t.c.o -o %t.c.bin -g
// RUN: %t.c.bin | FileCheck %s

// REQUIRES: !MACOS_HOST && X86_ENABLED

// CHECK: 1 0

#ifdef ISPC
typedef struct { uniform int32<4> m128i_i32; } __m128i;
typedef struct { uniform double<2> m128d_f64; } __m128d;

#if DEBUG
typedef __m128i __m128i_unaligned;
typedef __m128d __m128d_unaligned;
#else
typedef struct { uniform int32 m128i_i32[4]; } __m128i_unaligned;
typedef struct { uniform double m128d_f64[2]; } __m128d_unaligned;
#endif

#define ISPC_MASK_BITS 32

#if (ISPC_MASK_BITS == 1)
#define IntMaskType bool
#define UIntMaskType bool
#elif (ISPC_MASK_BITS == 8)
#define IntMaskType int8
#define UIntMaskType unsigned int8
#elif (ISPC_MASK_BITS == 16)
#define IntMaskType int16
#define UIntMaskType unsigned int16
#elif (ISPC_MASK_BITS == 32)
#define IntMaskType int32
#define UIntMaskType unsigned int32
#elif (ISPC_MASK_BITS == 64)
#define IntMaskType int64
#define UIntMaskType unsigned int64
#else
#error Unknown value of ISPC_MASK_BITS
#endif

static inline uniform unsigned int64 packmask__(bool v) {
#if (ISPC_MASK_BITS == 1)
    return __movmsk(v & __mask);
#else
    // print("");
    // print("pack: % % %\n", __sext_varying_bool(v), (UIntMaskType)__sext_varying_bool(v), __mask);
    // print("pac2: % %\n", (UIntMaskType)__sext_varying_bool(v) & __mask, __movmsk((UIntMaskType)__sext_varying_bool(v) & __mask));
    return __movmsk((UIntMaskType)__sext_varying_bool(v) & __mask);
#endif
}

static inline unmasked uniform __m128d _mm_loadu_pd(uniform double const* uniform _Dp)
{
    const uniform __m128d_unaligned R = *((uniform __m128d_unaligned *uniform)&_Dp[0]);
    return *((uniform __m128d *uniform)&R);
}

static inline unmasked uniform int _mm_movemask_pd(uniform __m128d _A)
{
    varying double S0;
    *((uniform double<2> *uniform)&S0) = *((uniform double<2> *uniform)&_A);

    // unsigned int64 __signbits = signbits(S0);
    // bool bv = __signbits;
    // uniform int pmask = packmask__(bv);
    // print("% % % %\n", S0, __signbits, bv, pmask);
    // return pmask;
    return packmask__(signbits(S0));
}

export void mm_movemask_pd(uniform int Result[], const uniform double Source1[], const uniform int Iterations)
{
    for (uniform int k = 0; k < Iterations; k+=2)
    {
        const uniform __m128d S1 = _mm_loadu_pd(&Source1[k]);
        Result[k] = _mm_movemask_pd(S1);
    }
}

#else
#include <stdio.h>
const int N = 8;
int main(int argc, char **argv) {
    double a[N] = { -1, 0, };
    int res[N] = { 0, };
    mm_movemask_pd(res, a, 1);
    printf("%i %i\n", res[0], res[1]);
    return 0;
}
#endif
