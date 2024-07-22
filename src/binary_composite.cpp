/*
  Copyright (c) 2024, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#include <stdio.h>

void printBinaryType() { printf("composite\n"); }

void initializeBinaryType(const char *) {
    // do nothing
}

extern const char stdlib_isph_cpp_header[];
const char *getStdlibHeader() {
    return stdlib_isph_cpp_header;
}

extern int stdlib_isph_cpp_length;
int getStdlibHeaderLength() {
    return stdlib_isph_cpp_length;
}
