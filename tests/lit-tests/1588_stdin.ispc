//; RUN: cat %s | %{ispc} - --target=host
//; TODO: cat %s | %{ispc} - --nocpp --target=host
//; nocpp is effectively useless after the core.isph introduction
//; RUN: cat %s | not %{ispc} - -g --nowrap --target=host 2>&1 | FileCheck %s -check-prefix=CHECK_ERROR

//; CHECK_ERROR: Error: Can't emit debugging information with no source file on disk.
int i;
