#!/bin/bash
# Test the boolean bug with different ISPC versions

set -e
cd "$(dirname "$0")"

echo "=== Testing ISPC Boolean Bug Across Versions ==="

ISPC_V126="/home/oleshka/workspace/ispc-v1.26.0-linux/bin/ispc"
ISPC_V127="/home/oleshka/workspace/ispc-v1.27.0-linux/bin/ispc"

# Check if both versions exist
if [ ! -f "$ISPC_V126" ]; then
    echo "ERROR: ISPC v1.26.0 not found at $ISPC_V126"
    exit 1
fi

if [ ! -f "$ISPC_V127" ]; then
    echo "ERROR: ISPC v1.27.0 not found at $ISPC_V127"
    exit 1
fi

echo "Found both ISPC versions:"
echo "v1.26.0: $ISPC_V126"
echo "v1.27.0: $ISPC_V127"
echo ""

# Function to test with a specific ISPC version
test_with_ispc() {
    local ispc_bin="$1"
    local version="$2"
    
    echo "=== Testing with ISPC $version ==="
    
    # Clean previous builds
    rm -f ispc_exact_repro_ispc_stubs.h ispc_exact_repro.o ispc_exact_repro_test
    
    # Check ISPC version
    echo "ISPC version info:"
    "$ispc_bin" --version
    echo ""
    
    # Compile with this ISPC version
    echo "Compiling ISPC code with $version..."
    "$ispc_bin" --target=avx2-i32x8 \
         --pic \
         -h ispc_exact_repro_ispc_stubs.h \
         -o ispc_exact_repro.o \
         ispc_exact_repro.ispc
    
    # Compile C++
    echo "Compiling C++ code..."
    g++ -O2 -I. \
        -o ispc_exact_repro_test \
        ispc_exact_repro.cpp \
        ispc_exact_repro.o
    
    echo "Running test with ISPC $version:"
    echo "----------------------------------------"
    ./ispc_exact_repro_test | head -15
    echo "----------------------------------------"
    echo ""
}

# Test with v1.26.0
test_with_ispc "$ISPC_V126" "v1.26.0"

# Test with v1.27.0  
test_with_ispc "$ISPC_V127" "v1.27.0"

echo "=== Comparison Complete ==="
echo "If v1.26.0 shows 'Raw ISPC result: 1' and v1.27.0 shows 'Raw ISPC result: 255',"
echo "then this confirms the bug was introduced in ISPC v1.27.0."
