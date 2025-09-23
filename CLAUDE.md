# ISPC project

## ISPC Project Structure

ISPC (Intel SPMD Program Compiler) is a performance-oriented compiler for
vectorized parallel programming.

Key directories:

- **src/**: Core compiler source (C++ frontend, AST, codegen, optimizations)
- **stdlib/**: ISPC standard library (built-in functions, target-specific implementations)
- **builtins/**: Low-level target-specific LLVM bitcode implementations
- **tests/**: Comprehensive test suite with functional tests
- **examples/**: Sample programs demonstrating ISPC usage
- **benchmarks/**: Performance benchmarks organized by complexity
- **ispcrt/**: Runtime library for host-device interaction
- **docs/**: Documentation and design specifications
- **scripts/**: Build automation and testing utilities

The compiler translates ISPC programs (*.ispc) into vectorized machine code,
with extensive target support for x86 (SSE through AVX-512), ARM NEON, and
Intel GPU architectures.

## Build Instructions

Quick build:
```bash
python scripts/quick-start-build.py
```

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
NEVER leave trailing spaces in files - always strip them when editing.

# build project

In the directory build-llvm-20-assert, run ninja

# test

## lit-tests

In the directory build-llvm-20-assert, run ninja check-all

To test the specific test, run
TEST=/home/oleshka/workspace/ispc/tests/lit-tests/<TESTNAME> ninja check-one

## functional tests (func-tests)

In the root project directory, run:

PATH=`pwd`/build-llvm-20-assert/bin:$PATH ./scripts/run_tests.py --target=avx512icl-x16 -o O2
