// RUN: %{ispc} --target=host --nowrap --nostdlib --gen-stdlib --debug-phase=2:2 %s --no-discard-value-names -o t.o | FileCheck %s

// CHECK: declare void @foo___un_3C_uni_3E_({{.*}} nocapture, {{.*}}
void foo(noescape uniform int *uniform ptr);

// CHECK: declare ptr @boo___un_3C_uni_3E_({{.*}} nocapture, {{.*}}
uniform int8 *uniform boo(noescape uniform int32 *uniform x);

// CHECK: declare void @arr___un_3C_uni_3E_({{.*}} nocapture, {{.*}}
void arr(noescape uniform int x[]);

// CHECK: declare void @"struct____{{.*}}"({{.*}} nocapture, {{.*}}
typedef struct {
    int x;
} my_struct;
void struct_(noescape uniform my_struct *uniform y);
