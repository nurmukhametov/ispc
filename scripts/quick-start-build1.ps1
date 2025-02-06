# Copyright (c) 2025, Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

# This script builds ISPC using a pre-built LLVM release from the ispc.dependencies repository.
# It has one optional argument, which is the LLVM version to use (default is 18).

param(
    [string]$LLVM_VERSION = "18"
)

$LLVM_HOME = if ($env:LLVM_HOME) { $env:LLVM_HOME } else { (Get-Location).Path }

# Detect number of processors
$NPROC = [System.Environment]::ProcessorCount

$SCRIPTS_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ISPC_ROOT = Resolve-Path "$SCRIPTS_DIR\.."
$ISPC_HOME = if ($env:ISPC_HOME) { $env:ISPC_HOME } else { $ISPC_ROOT }
$BUILD_DIR = "$ISPC_HOME\build-$LLVM_VERSION"
$LLVM_DIR = "$LLVM_HOME\llvm-$LLVM_VERSION"

Write-Output "LLVM_HOME: $LLVM_HOME"
Write-Output "ISPC_HOME: $ISPC_HOME"

Set-Location -Path $LLVM_HOME

if (Test-Path $LLVM_DIR) {
    Write-Output "$LLVM_DIR already exists"
} else {
    # Detect OS and architecture
    $OS = $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)
    $ARCH = $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)
    
    # Normalize OS names
    if ($OS -match "Linux") {
        $OS = "ubuntu22.04"
    } elseif ($OS -match "Darwin") {
        $OS = "macos"
    } else {
        Write-Output "Unsupported OS: $OS"
        exit 1
    }
    
    # Normalize architecture names
    if ($ARCH -eq "X64") {
        $ARCH = ""
    } elseif ($ARCH -eq "Arm64") {
        $ARCH = if ($OS -eq "macos") { "" } else { "aarch64" }
    } else {
        Write-Output "Unsupported architecture: $ARCH"
        exit 1
    }
    
    # Fetch GitHub releases JSON
    $RELEASES_JSON = Invoke-RestMethod -Uri "https://api.github.com/repos/ispc/ispc.dependencies/releases"
    
    # Extract matching release name
    $MATCHING_RELEASE = ($RELEASES_JSON | Where-Object { $_.tag_name -match "^llvm-$LLVM_VERSION\\." }).tag_name | Select-Object -First 1
    
    if (-not $MATCHING_RELEASE) {
        Write-Output "No matching release found for llvm-$LLVM_VERSION.*"
        exit 1
    }
    Write-Output "Found release: $MATCHING_RELEASE"
    
    # Fetch assets for the matching release
    $ASSETS_JSON = Invoke-RestMethod -Uri "https://api.github.com/repos/ispc/ispc.dependencies/releases/tags/$MATCHING_RELEASE"
    $ASSET_PATTERN = "llvm-$LLVM_VERSION.*-$OS$ARCH-Release.*Asserts-.*\.tar\.xz"
    
    # Extract asset name and URL matching the OS+ARCH pattern
    $ASSET = $ASSETS_JSON.assets | Where-Object { $_.name -match $ASSET_PATTERN -and $_.name -notmatch "lto" } | Select-Object -First 1
    
    if (-not $ASSET) {
        Write-Output "No matching assets found for release $MATCHING_RELEASE and pattern $ASSET_PATTERN"
        exit 1
    }
    Write-Output "Asset Name: $($ASSET.name)"
    Write-Output "Download URL: $($ASSET.browser_download_url)"
    
    # Download and extract the asset
    $ASSET_PATH = "$LLVM_HOME\$($ASSET.name)"
    if (Test-Path $ASSET_PATH) { Remove-Item $ASSET_PATH -Force }
    Invoke-WebRequest -Uri $ASSET.browser_download_url -OutFile $ASSET_PATH
    
    Write-Output "Extracting $($ASSET.name)"
    tar -xf $ASSET_PATH
    Rename-Item "bin-$LLVM_VERSION" $LLVM_DIR
}

# Build ISPC
if (-not (Test-Path $BUILD_DIR)) {
    $env:PATH = "$LLVM_DIR\bin;" + $env:PATH
    cmake -B $BUILD_DIR -S $ISPC_ROOT -DISPC_SLIM_BINARY=ON
    if ($LASTEXITCODE -ne 0) {
        Write-Output "CMake failed, cleaning up build directory $BUILD_DIR"
        Remove-Item -Recurse -Force $BUILD_DIR
        exit 1
    }
} else {
    Write-Output "$BUILD_DIR already exists"
}

cmake --build $BUILD_DIR --parallel $NPROC

Write-Output "Run ispc --support-matrix"
& "$BUILD_DIR\bin\ispc" --support-matrix

Write-Output "Run check-all"
cmake --build $BUILD_DIR --target check-all

