// RUN: %{ispc} --target=host --nowrap --nostdlib -O2 --emit-llvm-text %s -o %t.ll

enum Color {
  Red = 0,
  Green = 1,
  Blue = 2,
};

struct Point {
  Color c;
};

Point foo(uniform Point points[]) {
  return points[0];
}

