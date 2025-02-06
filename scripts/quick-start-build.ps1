# Copyright (c) 2025, Intel Corporation
#
# SPDX-License-Identifier: BSD-3-Clause
# This script builds ISPC using a pre-built LLVM release from the ispc.dependencies repository.
# It has one optional argument, which is the LLVM version to use (default is 18).

param(
    [string]$LLVMVersion = "18"
)

# Initialize environment variables with defaults
$env:LLVM_HOME = if ($env:LLVM_HOME) { $env:LLVM_HOME } else { Get-Location }
$NPROC = [int](Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# Get script and root directories
$SCRIPTS_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ISPC_ROOT = Resolve-Path (Join-Path $SCRIPTS_DIR "..")
$env:ISPC_HOME = if ($env:ISPC_HOME) { $env:ISPC_HOME } else { $ISPC_ROOT }
$BUILD_DIR = Join-Path $env:ISPC_HOME "build-$LLVMVersion"
$LLVM_DIR = Join-Path $env:LLVM_HOME "llvm-$LLVMVersion"

Write-Host "LLVM_HOME: $env:LLVM_HOME"
Write-Host "ISPC_HOME: $env:ISPC_HOME"

Set-Location $env:LLVM_HOME

if (Test-Path $LLVM_DIR) {
    Write-Host "$LLVM_DIR already exists"
}
else {
    # Detect OS and architecture
    $OS = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "macos" } elseif ($IsLinux) { "ubuntu22.04" } else { throw "Unsupported OS" }
    $ARCH = if ([System.Environment]::Is64BitOperatingSystem) {
        $proc = Get-CimInstance Win32_Processor
        if ($proc.Architecture -eq 9) { "aarch64" } else { "" }
    } else { throw "Unsupported architecture" }

    # If on macOS and ARM, set ARCH to empty string as per original script
    if ($IsMacOS -and $ARCH -eq "aarch64") { $ARCH = "" }

    # Fetch GitHub releases
    $Headers = @{
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $ReleasesJson = Invoke-RestMethod -Uri "https://api.github.com/repos/ispc/ispc.dependencies/releases" -Headers $Headers
    
    # Find matching release
    $MatchingRelease = $ReleasesJson | 
        Where-Object { $_.tag_name -match "^llvm-$LLVMVersion\." } | 
        Select-Object -First 1
    
    if (-not $MatchingRelease) {
        throw "No matching release found for llvm-$LLVMVersion.*"
    }
    
    $Version = $MatchingRelease.tag_name -replace "^llvm-",""
    $Version = $Version.Split("-")[0]
    Write-Host "Found release: $($MatchingRelease.tag_name)"
    
    # Find matching asset
    $AssetPattern = "llvm-$LLVMVersion.*-$OS$ARCH-Release.*Asserts-.*\.tar\.xz"
    $Asset = $MatchingRelease.assets | 
        Where-Object { $_.name -match $AssetPattern -and $_.name -notmatch "lto" } |
        Select-Object -First 1
    
    if (-not $Asset) {
        throw "No matching assets found for release $($MatchingRelease.tag_name) and pattern $AssetPattern"
    }
    
    Write-Host "Asset Name: $($Asset.name)"
    Write-Host "Download URL: $($Asset.browser_download_url)"
    
    # Download and extract the asset
    $OutFile = Join-Path $env:LLVM_HOME $Asset.name
    if (Test-Path $OutFile) {
        Remove-Item $OutFile -Force
    }
    
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $OutFile
    Write-Host "Extracting $($Asset.name)"
    
    # Use 7zip if available, otherwise try tar
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        7z x $OutFile
        7z x ($OutFile -replace '\.xz$','')
    }
    else {
        tar xf $OutFile
    }
    
    Move-Item "bin-$Version" $LLVM_DIR
}

if (-not (Test-Path $BUILD_DIR)) {
    $env:PATH = "$LLVM_DIR\bin;$env:PATH"
    cmake -B $BUILD_DIR $ISPC_ROOT -DISPC_SLIM_BINARY=ON
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CMake failed, cleaning up build directory $BUILD_DIR"
        Remove-Item $BUILD_DIR -Recurse -Force
        exit 1
    }
}
else {
    Write-Host "$BUILD_DIR already exists"
}

cmake --build $BUILD_DIR -j $NPROC

Write-Host "Run ispc --support-matrix"
& "$BUILD_DIR\bin\ispc" --support-matrix

Write-Host "Run check-all"
cmake --build $BUILD_DIR --target check-all
