/*
  Copyright (c) 2024, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#include "bitcode_lib.h"

using namespace ispc;

// TODO! more ifdefs

#define  START_NAME(NAME) _binary_builtins_ ## NAME ## _bc_start
#define    END_NAME(NAME) _binary_builtins_ ## NAME ## _bc_end
#define LENGTH_NAME(NAME) _binary_builtins_ ## NAME ## _bc_length
#define    LIB_NAME(NAME) NAME ## _lib

#define DISPATCH_LIB(NAME, OS) \
  extern "C" { extern const char START_NAME(NAME), END_NAME(NAME); } \
  size_t LENGTH_NAME(NAME) = & END_NAME(NAME) - & START_NAME(NAME); \
  static BitcodeLib LIB_NAME(NAME)( & START_NAME(NAME), LENGTH_NAME(NAME), OS);

#define CPP_LIB(NAME, OS, ARCH) \
  extern "C" { extern const char START_NAME(NAME), END_NAME(NAME); } \
  size_t LENGTH_NAME(NAME) = & END_NAME(NAME) - & START_NAME(NAME); \
  static BitcodeLib LIB_NAME(NAME)( & START_NAME(NAME), LENGTH_NAME(NAME), OS, ARCH);

#define TARGET_LIB(NAME, TARGET, OS, ARCH) \
  extern "C" { extern const char START_NAME(NAME), END_NAME(NAME); } \
  size_t LENGTH_NAME(NAME) = & END_NAME(NAME) - & START_NAME(NAME); \
  static BitcodeLib LIB_NAME(NAME)( & START_NAME(NAME), LENGTH_NAME(NAME), TARGET, OS, ARCH);

#ifndef ISPC_LINUX_TARGET_OFF
CPP_LIB(cpp_32_linux_armv7, TargetOS::linux, Arch::arm)
CPP_LIB(cpp_64_linux_aarch64, TargetOS::linux, Arch::aarch64)
CPP_LIB(cpp_32_linux_i686, TargetOS::linux, Arch::x86)
CPP_LIB(cpp_64_linux_x86_64, TargetOS::linux, Arch::x86_64)
#endif // ISPC_LINUX_TARGET_OFF

#ifndef ISPC_ANDROID_TARGET_OFF
CPP_LIB(cpp_32_android_armv7, TargetOS::android, Arch::arm)
CPP_LIB(cpp_64_android_aarch64, TargetOS::android, Arch::aarch64)
CPP_LIB(cpp_32_android_i686, TargetOS::android, Arch::x86)
CPP_LIB(cpp_64_android_x86_64, TargetOS::android, Arch::x86_64)
#endif // ISPC_ANDROID_TARGET_OFF

#ifndef ISPC_FREEBSD_TARGET_OFF
CPP_LIB(cpp_32_freebsd_armv7, TargetOS::freebsd, Arch::arm)
CPP_LIB(cpp_64_freebsd_aarch64, TargetOS::freebsd, Arch::aarch64)
CPP_LIB(cpp_32_freebsd_i686, TargetOS::freebsd, Arch::x86)
CPP_LIB(cpp_64_freebsd_x86_64, TargetOS::freebsd, Arch::x86_64)
#endif // ISPC_FREEBSD_TARGET_OFF

#ifndef ISPC_WINDOWS_TARGET_OFF
CPP_LIB(cpp_64_windows_aarch64, TargetOS::windows, Arch::aarch64)
CPP_LIB(cpp_32_windows_i686, TargetOS::windows, Arch::x86)
CPP_LIB(cpp_64_windows_x86_64, TargetOS::windows, Arch::x86_64)
#endif // ISPC_WINDOWS_TARGET_OFF

#ifndef ISPC_MACOS_TARGET_OFF
CPP_LIB(cpp_64_macos_x86_64, TargetOS::macos, Arch::x86_64)
#endif // ISPC_MACOS_TARGET_OFF

#ifndef ISPC_IOS_TARGET_OFF
// TODO! ??
CPP_LIB(cpp_64_ios_arm64, TargetOS::ios, Arch::aarch64)
#endif // ISPC_IOS_TARGET_OFF

#ifndef ISPC_PS_TARGET_OFF
CPP_LIB(cpp_64_ps4_x86_64, TargetOS::ps4, Arch::x86_64)
#endif // ISPC_PS_TARGET_OFF

#ifdef ISPC_XE_ENABLED
#ifndef ISPC_LINUX_TARGET_OFF
CPP_LIB(cm_64_linux, TargetOS::linux, Arch::xe64);
#endif // ISPC_LINUX_TARGET_OFF
#ifndef ISPC_WINDOWS_TARGET_OFF
CPP_LIB(cm_64_windows, TargetOS::windows, Arch::xe64);
#endif // ISPC_WINDOWS_TARGET_OFF
#endif // ISPC_XE_ENABLED

#ifdef ISPC_WASM_ENABLED
CPP_LIB(cpp_32_web_wasm32, TargetOS::web, Arch::wasm32)
CPP_LIB(cpp_64_web_wasm64, TargetOS::web, Arch::wasm64)
#endif // ISPC_WASM_ENABLED

// TODO! other targets?

#ifndef ISPC_MACOS_TARGET_OFF
DISPATCH_LIB(dispatch_macos, TargetOS::macos)
#endif // ISPC_MACOS_TARGET_OFF

// #ifndef ISPC_LINUX_TARGET_OFF
// TODO! strangly enough this TargetOS has no sense and this dispatch lib is used on windows
DISPATCH_LIB(dispatch, TargetOS::linux)
// #endif // ISPC_LINUX_TARGET_OFF

#ifdef ISPC_X86_ENABLED

// TODO! introduce macro ISPC_UNIX_TARGET that is used for all OSes that actually use
#ifndef ISPC_LINUX_TARGET_OFF
TARGET_LIB(target_sse2_i32x4_32bit_unix, ISPCTarget::sse2_i32x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse2_i32x4_64bit_unix, ISPCTarget::sse2_i32x4, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_sse2_i32x8_32bit_unix, ISPCTarget::sse2_i32x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse2_i32x8_64bit_unix, ISPCTarget::sse2_i32x8, TargetOS::linux, Arch::x86_64)

TARGET_LIB(target_sse4_i8x16_32bit_unix, ISPCTarget::sse4_i8x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse4_i8x16_64bit_unix, ISPCTarget::sse4_i8x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_sse4_i16x8_32bit_unix, ISPCTarget::sse4_i16x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse4_i16x8_64bit_unix, ISPCTarget::sse4_i16x8, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_sse4_i32x4_32bit_unix, ISPCTarget::sse4_i32x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse4_i32x4_64bit_unix, ISPCTarget::sse4_i32x4, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_sse4_i32x8_32bit_unix, ISPCTarget::sse4_i32x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_sse4_i32x8_64bit_unix, ISPCTarget::sse4_i32x8, TargetOS::linux, Arch::x86_64)

TARGET_LIB(target_avx1_i32x8_32bit_unix, ISPCTarget::avx1_i32x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx1_i32x8_64bit_unix, ISPCTarget::avx1_i32x8, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx1_i32x16_32bit_unix, ISPCTarget::avx1_i32x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx1_i32x16_64bit_unix, ISPCTarget::avx1_i32x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx1_i64x4_32bit_unix, ISPCTarget::avx1_i64x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx1_i64x4_64bit_unix, ISPCTarget::avx1_i64x4, TargetOS::linux, Arch::x86_64)

TARGET_LIB(target_avx2_i8x32_32bit_unix, ISPCTarget::avx2_i8x32, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i8x32_64bit_unix, ISPCTarget::avx2_i8x32, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx2_i16x16_32bit_unix, ISPCTarget::avx2_i16x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i16x16_64bit_unix, ISPCTarget::avx2_i16x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx2_i32x4_32bit_unix, ISPCTarget::avx2_i32x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i32x4_64bit_unix, ISPCTarget::avx2_i32x4, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx2_i32x8_32bit_unix, ISPCTarget::avx2_i32x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i32x8_64bit_unix, ISPCTarget::avx2_i32x8, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx2_i32x16_32bit_unix, ISPCTarget::avx2_i32x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i32x16_64bit_unix, ISPCTarget::avx2_i32x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx2_i64x4_32bit_unix, ISPCTarget::avx2_i64x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx2_i64x4_64bit_unix, ISPCTarget::avx2_i64x4, TargetOS::linux, Arch::x86_64)

TARGET_LIB(target_avx512knl_x16_32bit_unix, ISPCTarget::avx512knl_x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512knl_x16_64bit_unix, ISPCTarget::avx512knl_x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512skx_x4_32bit_unix, ISPCTarget::avx512skx_x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512skx_x4_64bit_unix, ISPCTarget::avx512skx_x4, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512skx_x8_32bit_unix, ISPCTarget::avx512skx_x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512skx_x8_64bit_unix, ISPCTarget::avx512skx_x8, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512skx_x16_32bit_unix, ISPCTarget::avx512skx_x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512skx_x16_64bit_unix, ISPCTarget::avx512skx_x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512skx_x32_32bit_unix, ISPCTarget::avx512skx_x32, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512skx_x32_64bit_unix, ISPCTarget::avx512skx_x32, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512skx_x64_32bit_unix, ISPCTarget::avx512skx_x64, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512skx_x64_64bit_unix, ISPCTarget::avx512skx_x64, TargetOS::linux, Arch::x86_64)

#if ISPC_LLVM_VERSION >= ISPC_LLVM_14_0
TARGET_LIB(target_avx512spr_x4_32bit_unix, ISPCTarget::avx512spr_x4, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512spr_x4_64bit_unix, ISPCTarget::avx512spr_x4, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512spr_x8_32bit_unix, ISPCTarget::avx512spr_x8, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512spr_x8_64bit_unix, ISPCTarget::avx512spr_x8, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512spr_x16_32bit_unix, ISPCTarget::avx512spr_x16, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512spr_x16_64bit_unix, ISPCTarget::avx512spr_x16, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512spr_x32_32bit_unix, ISPCTarget::avx512spr_x32, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512spr_x32_64bit_unix, ISPCTarget::avx512spr_x32, TargetOS::linux, Arch::x86_64)
TARGET_LIB(target_avx512spr_x64_32bit_unix, ISPCTarget::avx512spr_x64, TargetOS::linux, Arch::x86)
TARGET_LIB(target_avx512spr_x64_64bit_unix, ISPCTarget::avx512spr_x64, TargetOS::linux, Arch::x86_64)
#endif // ISPC_LLVM_VERSION >= ISPC_LLVM_14_0
#endif // ISPC_LINUX_TARGET_OFF

#ifndef ISPC_WINDOWS_TARGET_OFF
TARGET_LIB(target_sse2_i32x4_32bit_windows, ISPCTarget::sse2_i32x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse2_i32x4_64bit_windows, ISPCTarget::sse2_i32x4, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_sse2_i32x8_32bit_windows, ISPCTarget::sse2_i32x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse2_i32x8_64bit_windows, ISPCTarget::sse2_i32x8, TargetOS::windows, Arch::x86_64)

TARGET_LIB(target_sse4_i8x16_32bit_windows, ISPCTarget::sse4_i8x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse4_i8x16_64bit_windows, ISPCTarget::sse4_i8x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_sse4_i16x8_32bit_windows, ISPCTarget::sse4_i16x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse4_i16x8_64bit_windows, ISPCTarget::sse4_i16x8, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_sse4_i32x4_32bit_windows, ISPCTarget::sse4_i32x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse4_i32x4_64bit_windows, ISPCTarget::sse4_i32x4, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_sse4_i32x8_32bit_windows, ISPCTarget::sse4_i32x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_sse4_i32x8_64bit_windows, ISPCTarget::sse4_i32x8, TargetOS::windows, Arch::x86_64)

TARGET_LIB(target_avx1_i32x8_32bit_windows, ISPCTarget::avx1_i32x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx1_i32x8_64bit_windows, ISPCTarget::avx1_i32x8, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx1_i32x16_32bit_windows, ISPCTarget::avx1_i32x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx1_i32x16_64bit_windows, ISPCTarget::avx1_i32x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx1_i64x4_32bit_windows, ISPCTarget::avx1_i64x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx1_i64x4_64bit_windows, ISPCTarget::avx1_i64x4, TargetOS::windows, Arch::x86_64)

TARGET_LIB(target_avx2_i8x32_32bit_windows, ISPCTarget::avx2_i8x32, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i8x32_64bit_windows, ISPCTarget::avx2_i8x32, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx2_i16x16_32bit_windows, ISPCTarget::avx2_i16x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i16x16_64bit_windows, ISPCTarget::avx2_i16x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx2_i32x4_32bit_windows, ISPCTarget::avx2_i32x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i32x4_64bit_windows, ISPCTarget::avx2_i32x4, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx2_i32x8_32bit_windows, ISPCTarget::avx2_i32x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i32x8_64bit_windows, ISPCTarget::avx2_i32x8, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx2_i32x16_32bit_windows, ISPCTarget::avx2_i32x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i32x16_64bit_windows, ISPCTarget::avx2_i32x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx2_i64x4_32bit_windows, ISPCTarget::avx2_i64x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx2_i64x4_64bit_windows, ISPCTarget::avx2_i64x4, TargetOS::windows, Arch::x86_64)

TARGET_LIB(target_avx512knl_x16_32bit_windows, ISPCTarget::avx512knl_x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512knl_x16_64bit_windows, ISPCTarget::avx512knl_x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512skx_x4_32bit_windows, ISPCTarget::avx512skx_x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512skx_x4_64bit_windows, ISPCTarget::avx512skx_x4, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512skx_x8_32bit_windows, ISPCTarget::avx512skx_x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512skx_x8_64bit_windows, ISPCTarget::avx512skx_x8, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512skx_x16_32bit_windows, ISPCTarget::avx512skx_x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512skx_x16_64bit_windows, ISPCTarget::avx512skx_x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512skx_x32_32bit_windows, ISPCTarget::avx512skx_x32, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512skx_x32_64bit_windows, ISPCTarget::avx512skx_x32, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512skx_x64_32bit_windows, ISPCTarget::avx512skx_x64, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512skx_x64_64bit_windows, ISPCTarget::avx512skx_x64, TargetOS::windows, Arch::x86_64)

#if ISPC_LLVM_VERSION >= ISPC_LLVM_14_0
TARGET_LIB(target_avx512spr_x4_32bit_windows, ISPCTarget::avx512spr_x4, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512spr_x4_64bit_windows, ISPCTarget::avx512spr_x4, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512spr_x8_32bit_windows, ISPCTarget::avx512spr_x8, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512spr_x8_64bit_windows, ISPCTarget::avx512spr_x8, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512spr_x16_32bit_windows, ISPCTarget::avx512spr_x16, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512spr_x16_64bit_windows, ISPCTarget::avx512spr_x16, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512spr_x32_32bit_windows, ISPCTarget::avx512spr_x32, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512spr_x32_64bit_windows, ISPCTarget::avx512spr_x32, TargetOS::windows, Arch::x86_64)
TARGET_LIB(target_avx512spr_x64_32bit_windows, ISPCTarget::avx512spr_x64, TargetOS::windows, Arch::x86)
TARGET_LIB(target_avx512spr_x64_64bit_windows, ISPCTarget::avx512spr_x64, TargetOS::windows, Arch::x86_64)
#endif // ISPC_LLVM_VERSION >= ISPC_LLVM_14_0
#endif // ISPC_WINDOWS_TARGET_OFF

#endif // ISPC_X86_ENABLED

#ifdef ISPC_ARM_ENABLED

#ifndef ISPC_LINUX_TARGET_OFF
TARGET_LIB(target_neon_i8x16_32bit_unix, ISPCTarget::neon_i8x16, TargetOS::linux, Arch::arm)
TARGET_LIB(target_neon_i16x8_32bit_unix, ISPCTarget::neon_i16x8, TargetOS::linux, Arch::arm)
TARGET_LIB(target_neon_i32x4_32bit_unix, ISPCTarget::neon_i32x4, TargetOS::linux, Arch::arm)
TARGET_LIB(target_neon_i32x4_64bit_unix, ISPCTarget::neon_i32x4, TargetOS::linux, Arch::aarch64)
TARGET_LIB(target_neon_i32x8_32bit_unix, ISPCTarget::neon_i32x8, TargetOS::linux, Arch::arm)
TARGET_LIB(target_neon_i32x8_64bit_unix, ISPCTarget::neon_i32x8, TargetOS::linux, Arch::aarch64)
#endif // ISPC_LINUX_TARGET_OFF

#ifndef ISPC_WINDOWS_TARGET_OFF
TARGET_LIB(target_neon_i8x16_32bit_windows, ISPCTarget::neon_i8x16, TargetOS::windows, Arch::arm)
TARGET_LIB(target_neon_i16x8_32bit_windows, ISPCTarget::neon_i16x8, TargetOS::windows, Arch::arm)
TARGET_LIB(target_neon_i32x4_32bit_windows, ISPCTarget::neon_i32x4, TargetOS::windows, Arch::arm)
TARGET_LIB(target_neon_i32x4_64bit_windows, ISPCTarget::neon_i32x4, TargetOS::windows, Arch::aarch64)
TARGET_LIB(target_neon_i32x8_32bit_windows, ISPCTarget::neon_i32x8, TargetOS::windows, Arch::arm)
TARGET_LIB(target_neon_i32x8_64bit_windows, ISPCTarget::neon_i32x8, TargetOS::windows, Arch::aarch64)
#endif // ISPC_WINDOWS_TARGET_OFF

#endif // ISPC_ARM_ENABLED

#ifdef ISPC_XE_ENABLED

#ifndef ISPC_LINUX_TARGET_OFF
TARGET_LIB(target_gen9_x8_32bit_unix, ISPCTarget::gen9_x8, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_gen9_x8_64bit_unix, ISPCTarget::gen9_x8, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_gen9_x16_32bit_unix, ISPCTarget::gen9_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_gen9_x16_64bit_unix, ISPCTarget::gen9_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xelpg_x8_64bit_unix, ISPCTarget::xelpg_x8, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xelpg_x16_64bit_unix, ISPCTarget::xelpg_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xelp_x8_64bit_unix, ISPCTarget::xelp_x8, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xelp_x16_64bit_unix, ISPCTarget::xelp_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xehpg_x8_64bit_unix, ISPCTarget::xehpg_x8, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xehpg_x16_64bit_unix, ISPCTarget::xehpg_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xehpc_x16_64bit_unix, ISPCTarget::xehpc_x16, TargetOS::linux, Arch::xe64)
TARGET_LIB(target_xehpc_x32_64bit_unix, ISPCTarget::xehpc_x32, TargetOS::linux, Arch::xe64)
#endif // ISPC_LINUX_TARGET_OFF

#ifndef ISPC_WINDOWS_TARGET_OFF
TARGET_LIB(target_gen9_x8_32bit_windows, ISPCTarget::gen9_x8, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_gen9_x8_64bit_windows, ISPCTarget::gen9_x8, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_gen9_x16_32bit_windows, ISPCTarget::gen9_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_gen9_x16_64bit_windows, ISPCTarget::gen9_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xelpg_x8_64bit_windows, ISPCTarget::xelpg_x8, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xelpg_x16_64bit_windows, ISPCTarget::xelpg_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xelp_x8_64bit_windows, ISPCTarget::xelp_x8, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xelp_x16_64bit_windows, ISPCTarget::xelp_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xehpg_x8_64bit_windows, ISPCTarget::xehpg_x8, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xehpg_x16_64bit_windows, ISPCTarget::xehpg_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xehpc_x16_64bit_windows, ISPCTarget::xehpc_x16, TargetOS::windows, Arch::xe64)
TARGET_LIB(target_xehpc_x32_64bit_windows, ISPCTarget::xehpc_x32, TargetOS::windows, Arch::xe64)
#endif // ISPC_WINDOWS_TARGET_OFF

#endif // ISPC_XE_ENABLED

#ifdef ISPC_WASM_ENABLED
TARGET_LIB(target_wasm_i32x4_32bit_web, ISPCTarget::wasm_i32x4, TargetOS::web, Arch::wasm32)
TARGET_LIB(target_wasm_i32x4_64bit_web, ISPCTarget::wasm_i32x4, TargetOS::web, Arch::wasm64)
#endif // ISPC_WASM_ENABLED

// TODO! wasm
// TODO! windows
// TODO! macOS
