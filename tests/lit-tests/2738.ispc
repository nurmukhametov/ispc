// RUN: %{ispc} --target=avx2-i32x4 --nostdlib --nowrap --emit-llvm-text -o - %s 2>&1 | FileCheck %s

// CHECK-LABEL: @foo___
// CHECK-NEXT: allocas:
// CHECK-NEXT: ret <4 x i32> <i32 1, i32 2, i32 3, i32 4>

// ERROR-NOT: Error: Initializer for global variable "y" must be a constant.

static const int x = { 0, 1, 2, 3 };
static const int y = x + 1;
int foo() {
    return y;
}
