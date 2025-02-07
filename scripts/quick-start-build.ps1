# Copyright (c) 2025, Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

# This script builds ISPC using a pre-built LLVM release from the ispc.dependencies repository.
# It has one optional argument, which is the LLVM version to use (default is 18).

param(
    [string]$LLVM_VERSION = "18"
)

function llvm_asset {
    # Detect OS and architecture
    $OS = "win.*"
    $ARCH = ""

    # Fetch GitHub releases JSON and Extract matching release name
    try {
        $RELEASES = Invoke-RestMethod -Uri "https://api.github.com/repos/ispc/ispc.dependencies/releases"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Output "GitHub API rate limit exceeded"
            return 2
        } else {
            throw $_
        }
    }

    $MATCHING_RELEASE = $RELEASES | Where-Object { $_.tag_name -match "^llvm-$LLVM_VERSION\." } | Select-Object -First 1
    $MATCHING_RELEASE_TAG = $MATCHING_RELEASE.tag_name

    # Get specific version like 18.1, removing prefix llvm- and suffix
    $script:VERSION = $MATCHING_RELEASE_TAG -replace "^llvm-",""
    $script:VERSION = $VERSION -replace "-.*$",""

    if (-not $MATCHING_RELEASE_TAG) {
        Write-Output "No matching release found for llvm-$LLVM_VERSION.*"
        exit 1
    }
    Write-Output "Matching release found: $MATCHING_RELEASE_TAG"
    
    # Fetch assets for the matching release
    $ASSET_PATTERN = "llvm-$LLVM_VERSION.*-$OS$ARCH-Release.*Asserts-.*\.tar\.7z"
    try {
        $ASSETS_JSON = Invoke-RestMethod -Uri "https://api.github.com/repos/ispc/ispc.dependencies/releases/tags/$MATCHING_RELEASE_TAG"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            Write-Output "GitHub API rate limit exceeded"
            return 2
        } else {
            throw $_
        }
    }

    # Extract asset name and URL matching the OS+ARCH pattern
    $ASSET = $ASSETS_JSON.assets | Where-Object { $_.name -match "$ASSET_PATTERN" -and $_.name -notmatch "lto" } | Select-Object -First 1

    if (-not $ASSET) {
        Write-Output "No matching assets found for release $MATCHING_RELEASE_TAG and pattern $ASSET_PATTERN"
        exit 1
    }

    $script:ASSET_NAME = "$($ASSET.name)"
    $script:ASSET_URL = "$($ASSET.browser_download_url)"
}

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
    $output = llvm_asset
    if ($output -eq 2) {
        if ($env:ARCHIVE_URL) {
            $ASSET_NAME = Split-Path -Leaf $env:ARCHIVE_URL
            $ASSET_URL = $env:ARCHIVE_URL
            $match = [regex]::Match($ASSET_NAME, "($LLVM_VERSION\.[0-9]+)")
            if ($match.Success) {
                $VERSION = $match.Groups[1].Value
            } else {
                Write-Output "Version not found in $env:ARCHIVE_URL"
                exit 1
            }
        } else {
            Write-Error "Error: Failed to deduct and fetch LLVM archives from Github API.
            Please set ARCHIVE_URL environment variable to the direct download URL of the LLVM package.
            Example: `$env:ARCHIVE_URL='https://github.com/ispc/ispc.dependencies/releases/download/...'"
            exit 1
        }
    }

    Write-Output "Asset Name: $ASSET_NAME"
    Write-Output "Download URL: $ASSET_URL"
    
    # Download and extract the asset
    $ASSET_PATH = "$LLVM_HOME\$ASSET_NAME"
    if (Test-Path $ASSET_PATH) { Remove-Item $ASSET_PATH -Force }
    Start-BitsTransfer -Source $ASSET_URL -Destination $ASSET_PATH
    
    Write-Output "Extracting $($ASSET.name)"
    7z x -t7z $ASSET_PATH
    7z x -ttar llvm*tar
    Rename-Item "bin-$VERSION" $LLVM_DIR
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

cmake --build $BUILD_DIR --config RelWithDebInfo --parallel $NPROC

Write-Output "Run ispc --support-matrix"
& "$BUILD_DIR\bin\RelWithDebInfo\ispc" --support-matrix

Write-Output "Run check-all"
cmake --build $BUILD_DIR --config RelWithDebInfo --target check-all

