// RUN: not %{ispc} --target=host --nowrap --nostdlib  %s -o t.o 2>&1 | FileCheck %s

#define ATTR __attribute__((address_space(1)))
#define ATTRN(N) __attribute__((address_space(N)))

// CHECK: Warning: Ignoring "address_space" attribute for function "func_1".
ATTR void *func_1();

// CHECK: Warning: Ignoring "address_space" attribute for function "func_2".
ATTR void func_2();

// It is not yet supported to have __attribute__ in struct declaration.
// CHECK: Error: syntax error, unexpected '__attribute__'
struct S {
  ATTR void *ptr_str;
};

// CHECK: Warning: "address_space" attribute is only allowed for pointer or reference types, "x".
ATTRN(1) uniform int x;

// CHECK: Error: "address_space" attribute 20 is out of scope of supported [0, 4], "ptr_2".
ATTRN(20) uniform int * uniform ptr_2;

void func() {
    // CHECK: Warning: "address_space" attribute is only allowed for pointer or reference types, "l1".
    ATTRN(1) uniform int l1;

    // CHECK: Error: "address_space" attribute 20 is out of scope of supported [0, 4], "lptr".
    ATTRN(20) uniform int * uniform lptr;
}

// CHECK: Warning: "address_space" attribute is only allowed for pointer or reference types, "p1".
// CHECK: Error: "address_space" attribute 20 is out of scope of supported [0, 4], "pptr1".
void decl1(ATTRN(1) uniform int p1, ATTRN(20) uniform int * uniform pptr1);

// CHECK: Warning: "address_space" attribute is only allowed for pointer or reference types, "p2".
// CHECK: Error: "address_space" attribute 20 is out of scope of supported [0, 4], "pptr2".
void def1(ATTRN(1) uniform int p2, ATTRN(20) uniform int * uniform pptr2) { }
