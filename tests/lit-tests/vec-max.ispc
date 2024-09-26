// RUN: %{ispc} -O2 --target=avx512skx-x4 --emit-asm --x86-asm-syntax=intel %s -o - 2>&1 | FileCheck %s

// CHECK: vpmaxsd xmm0, xmm0, xmm1

uniform int<4> foo(uniform int<4> a, uniform int<4> b) {
    return max<uniform int, 4>(a, b);
}
