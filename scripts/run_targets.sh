#!/bin/bash

#  Copyright (c) 2025, Intel Corporation
#
#  SPDX-License-Identifier: BSD-3-Clause

# Function to handle Ctrl+C (SIGINT)
cleanup() {
    echo "Terminating run_targets.sh script"
    exit 1
}

# Set the trap to call the cleanup function on SIGINT
trap cleanup SIGINT

TARGETS="$*"

echo "Target list: $TARGETS"
echo -n "ISPC is "
which ispc
ispc --version

if [ ! -z "${EXTRA_OPTS}" ]; then
    echo "EXTRA_OPTS: ${EXTRA_OPTS}"
fi

for OPT in O0 O1 O2; do
  for TARGET in ${TARGETS}; do
    echo -n "Run tests for $TARGET $OPT $EXTRA_OPTS "
    temp_file=$(mktemp)
    ./scripts/run_tests.py --target=$TARGET -o ${OPT} ${EXTRA_OPTS} 2>&1 > "$temp_file"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      echo "NEW FAILS:"
      grep "NEW" -A 1500 "$temp_file"
      PRINT_EXTRA_OPTS="-${EXTRA_OPTS// /_}"
      mv "$temp_file" "run-${TARGET}-${OPT}${PRINT_EXTRA_OPTS}.log"
    else
      echo "OK"
      rm "$temp_file"
    fi
  done
done
