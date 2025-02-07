#!/bin/bash

#  Copyright (c) 2025, Intel Corporation
#
#  SPDX-License-Identifier: BSD-3-Clause


# This script builds ISPC using a pre-built LLVM release from the ispc.dependencies repository.
# It has one optional argument, which is the LLVM version to use (default is 18).

LLVM_HOME="${LLVM_HOME:-$(pwd)}"
LLVM_VERSION="${1:-18}"
NPROC=$(command -v nproc >/dev/null && nproc || echo 8)
SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd)
ISPC_ROOT=$(realpath "$SCRIPTS_DIR/..")
ISPC_HOME="${ISPC_HOME:-$ISPC_ROOT}"
BUILD_DIR="$ISPC_HOME/build-$LLVM_VERSION"
LLVM_DIR="$LLVM_HOME/llvm-$LLVM_VERSION"

echo "LLVM_HOME: $LLVM_HOME"
echo "ISPC_HOME: $ISPC_HOME"

cd "$LLVM_HOME"

if [ -d "$LLVM_DIR" ]; then
    echo "$LLVM_DIR already exists"
else
    # Detect OS/architecture and normalize them to match the expected format in filenames.
    OS=$(uname -s)
    ARCH=$(uname -m)
    case "$OS" in
        Linux) OS="ubuntu22.04" ;;
        Darwin) OS="macos" ;;
        *) echo "Unsupported OS: $OS"; exit 1 ;;
    esac
    case "$ARCH" in
        x86_64) ARCH="" ;;
        aarch64) ARCH="aarch64" ;; # linux tarball contains aarch64 after $OS
        arm64) ARCH="" ;; # macOS specific, out tarballs doesn't contain arm in their names
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Fetch GitHub releases JSON
    RELEASES_JSON=$(curl -s "https://api.github.com/repos/ispc/ispc.dependencies/releases")
    
    # Extract matching release name
    MATCHING_RELEASE=$(echo "$RELEASES_JSON" | grep -o '"tag_name": *"llvm-[^"]*' | sed -E 's/"tag_name": *"//' | grep "^llvm-$LLVM_VERSION\." | head -n 1)
    
    # Remove "llvm-" and remove everything after the first "-"
    VERSION="${MATCHING_RELEASE#llvm-}"
    VERSION="${VERSION%%-*}"
    
    # Check if a matching release was found
    if [[ -z "$MATCHING_RELEASE" ]]; then
        echo "No matching release found for llvm-$LLVM_VERSION.*"
        exit 1
    fi
    echo "Found release: $MATCHING_RELEASE"
    
    # Fetch assets for the matching release
    ASSETS_JSON=$(curl -s "https://api.github.com/repos/ispc/ispc.dependencies/releases/tags/$MATCHING_RELEASE")
    ASSET_PATTERN="llvm-$LLVM_VERSION.*-$OS$ARCH-Release.*Asserts-.*\.tar\.xz"
    
    # Extract asset name and URL matching the OS+ARCH pattern
    ASSET_NAME=$(echo "$ASSETS_JSON" | grep -o '"name": *"llvm-[^"]*' | sed -E 's/"name": *"//' | grep -E "$ASSET_PATTERN" | grep -v "lto" | head -n 1)
    ASSET_URL=$(echo "$ASSETS_JSON" | grep -o '"browser_download_url": *"https://github.com/ispc/ispc.dependencies/releases/download/[^"]*' | sed -E 's/"browser_download_url": *"//' | grep -E "$ASSET_PATTERN" | grep -v "lto" | head -n 1)
    
    # Check if a matching asset was found
    if [[ -z "$ASSET_NAME" || -z "$ASSET_URL" ]]; then
        echo "No matching assets found for release $MATCHING_RELEASE and pattern $ASSET_PATTERN"
        exit 1
    fi
    echo "Asset Name: $ASSET_NAME"
    echo "Download URL: $ASSET_URL"

    if [ -f "$ASSET_NAME" ]; then
        rm "$ASSET_NAME"
    fi
    curl -L $ASSET_URL -o $ASSET_NAME
    echo "Extracting $ASSET_NAME"
    tar xf $ASSET_NAME
    mv bin-$VERSION "$LLVM_DIR"
fi

if [ ! -d "$BUILD_DIR" ]; then
    PATH="$LLVM_DIR/bin":$PATH cmake -B "$BUILD_DIR" "$ISPC_ROOT" -DISPC_SLIM_BINARY=ON
    if [ $? -ne 0 ]; then
        echo "CMake failed, cleaning up build directory $BUILD_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi
else
    echo "$BUILD_DIR already exists"
fi
cmake --build "$BUILD_DIR" -j $NPROC

echo "Run ispc --support-matrix"
"$BUILD_DIR/bin/ispc" --support-matrix

echo "Run check-all"
cmake --build "$BUILD_DIR" --target check-all
