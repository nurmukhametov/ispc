// RUN: %{ispc} --pic -O2 --target=avx2-i32x8 %s -o %t.o
// RUN: %{cc} %t.o -o %t.bin
// RUN: %t.bin | FileCheck %s

// REQUIRES: X86_ENABLED

// CHECK: [1,1,1,1,1,1,1,1]
// CHECK-NEXT: [0,0,0,0,0,0,0,0]

enum Color {
  Red = 0,
  Green = 1,
  Blue = 2,
};

struct Point {
  Color c;
};

Point foo(uniform Point points[]) {
  return points[1];
}

extern "C" uniform int main() {
    uniform Point r = { Red };
    uniform Point g = { Green };
    uniform Point b = { Blue };
    uniform Point ps[] = { r, g, b };
    Point p = foo(ps);
    print("%\n", (int32)p.c);

    uniform Color u = Red;
    Color v = u;
    print("%\n", (int32)v);
    return 0;
}
