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

SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)

# x86 targets
sse2_targets=("sse2-i32x4" "sse2-i32x8")
sse41_targets=("sse4.1-i8x16" "sse4.1-i16x8" "sse4.1-i32x4" "sse4.1-i32x8")
sse42_targets=("sse4.2-i8x16" "sse4.2-i16x8" "sse4.2-i32x4" "sse4.2-i32x8")
avx1_targets=("avx1-i32x4" "avx1-i32x8" "avx1-i32x16" "avx1-i64x4")
avx2_targets=("avx2-i8x32" "avx2-i16x16" "avx2-i32x4" "avx2-i32x8" "avx2-i32x16" "avx2-i64x4")
avx2vvni_targets=("avx2vnni-i32x4" "avx2vnni-i32x8" "avx2vnni-i32x16")
skx_targets=("avx512skx-x4" "avx512skx-x8" "avx512skx-x16" "avx512skx-x32" "avx512skx-x64")
icl_targets=("avx512icl-x4" "avx512icl-x8" "avx512icl-x16" "avx512icl-x32" "avx512icl-x64")
spr_targets=("avx512spr-x4" "avx512spr-x8" "avx512spr-x16" "avx512spr-x32" "avx512spr-x64")

# Create the X86_ISA_TARGETS associative array
declare -A X86_ISA_TARGETS
X86_ISA_TARGETS=(
        ["SSE2"]="${sse2_targets[*]}"
      ["SSE4.1"]="${sse2_targets[*]} ${sse41_targets[*]}"
      ["SSE4.2"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]}"
         ["AVX"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx_targets[*]}"
      ["AVX1.1"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx_targets[*]}"
        ["AVX2"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx2_targets[*]}"
    ["AVX2VNNI"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx2_targets[*]} ${avx2vnni_targets[*]}"
         ["SKX"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx2_targets[*]} ${avx2vnni_targets[*]} ${skx_targets[*]}"
         ["ICL"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx2_targets[*]} ${avx2vnni_targets[*]} ${skx_targets[*]} ${icl_targets[*]}"
         ["SPR"]="${sse2_targets[*]} ${sse41_targest[*]} ${sse42_targets[*]} ${avx2_targets[*]} ${avx2vnni_targets[*]} ${skx_targets[*]} ${icl_targets[*]} ${spr_targets[*]}"
)

ARM_TARGETS="neon-i8x16 neon-i8x32 neon-i16x8 neon-i16x16 neon-i32x4 neon-i32x8"

GENERIC_TARGERS="generic-i1x4 generic-i1x8 generic-i1x16 generic-i1x32 generic-i8x16 generic-i8x32 generic-i16x8 generic-i16x16 generic-i32x4 generic-i32x8 generic-i32x16 generic-i64x4"

run_targets_x86() {
    # Get native ISA
    CHECK_ISA_OUTPUT=$(check_isa)
    ISA=$(echo "${CHECK_ISA_OUTPUT#ISA: }" | sed 's/ (codename .*);$//')
    echo "Native ISA: $ISA"

    TARGETS=${X86_ISA_TARGETS[$ISA]}

    EXTRA_OPTS="--arch=x86_64" "$SCRIPTS_DIR/run_targets.sh" $GENERIC_TARGERS
    EXTRA_OPTS="--arch=x86" "$SCRIPTS_DIR/run_targets.sh" $GENERIC_TARGERS
    EXTRA_OPTS="--arch=x86_64" "$SCRIPTS_DIR/run_targets.sh" $TARGETS
    EXTRA_OPTS="--arch=x86" "$SCRIPTS_DIR/run_targets.sh" $TARGETS
}

run_targets_arm() {
    EXTRA_OPTS="--arch=aarch64" "$SCRIPTS_DIR/run_targets.sh" $GENERIC_TARGERS
    EXTRA_OPTS="--arch=aarch64" "$SCRIPTS_DIR/run_targets.sh" $ARM_TARGETS
}

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    echo "Native arch: x86_64"
    run_targets_x86
elif [[ "$ARCH" == "aarch64" ]]; then
    echo "Native arch: aarch64"
    run_targets_arm
else
    echo "Unknown architecture: $ARCH"
fi
