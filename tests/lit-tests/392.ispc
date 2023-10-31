// RUN: not %{ispc} --target=host --nowrap --nostdlib -O2 %s -o %t.o

// CHECK: Error: Global variable foo has undefined type

struct Foo foo;
