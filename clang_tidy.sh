#!/bin/bash

set -e

BUILD_FODLER=${1:-"build"}

if [ ! -d "$BUILD_FODLER" ]; then
  echo "Build folder '$BUILD_FODLER' does not exist."
  exit 1
fi

if [ ! -f "$BUILD_FODLER/compile_commands.json" ]; then
  echo "compile_commands.json not found in '$BUILD_FODLER'."
  exit 1
fi

FILES=$(ls                                  \
    src/*.{cpp,h}                           \
    src/opt/*.{cpp,h}                       \
    *.cpp                                   \
    builtins/*{cpp,hpp,c}                   \
    common/*.h                              \
)

# Run clang-tidy with the compilation database from the given build folder in parallel
NUM_CORES=$(nproc)
echo $FILES | xargs -n 1 | xargs -I {} -P $NUM_CORES clang-tidy -p "$BUILD_FODLER" "{}" --warnings-as-errors='*'
