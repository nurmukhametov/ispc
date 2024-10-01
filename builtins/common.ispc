#define ISPC_INTERNAL_STDLIB_COMPILATION
#include "core.isph"
// 
// #include "builtins.isph"
// #include "stdlib.isph"
// #include "svml.isph"
// #include "target.isph"
#undef ISPC_INTERNAL_STDLIB_COMPILATION

// Macros for attributes
#define NOESCAPE __attribute__((noescape))
#define ADDRSPACE(N) __attribute__((address_space(N)))
#define READONLY __attribute__((memory("read")))
#define READNONE __attribute__((memory("none")))
#define UNMANGLED __attribute__((unmangled))
#define CDECL __attribute__((cdecl))
#define EXT __attribute__((unmangled)) __attribute__((cdecl)) unmasked
// all ISPC pointer arguments of functions are noalias so we don't need to
// support it until it changed.
// #define NOALIAS __attribute__((noalias))
#define NOALIAS

// Declared function to trap unsupported functions during compilation (linking) time.
// In sane cases, this function call should always be removed.
extern "C" void __not_supported();

// // EXT uniform bool __is_compile_time_constant_mask(UIntMaskType);
// // EXT uniform bool __is_compile_time_constant_uniform_int32(uniform int32);
// // EXT uniform bool __is_compile_time_constant_varying_int32(varying int32);
// 
// // trigonometric functions
// // __have_native_trigonometry
// EXT READNONE uniform double __acos_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __acos_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __acos_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __acos_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __acos_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __acos_varying_half(varying float16) { @llvm.trap(); }
// EXT READNONE uniform double __asin_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __asin_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __asin_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __asin_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __asin_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __asin_varying_half(varying float16) { @llvm.trap(); }
// EXT READNONE uniform double __atan2_uniform_double(uniform double, uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __atan2_uniform_float(uniform float, uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __atan2_uniform_half(uniform float16, uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __atan2_varying_double(varying double, varying double) { @llvm.trap(); }
// EXT READNONE varying float __atan2_varying_float(varying float, varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __atan2_varying_half(varying float16, varying float16) { @llvm.trap(); }
// EXT READNONE uniform double __atan_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __atan_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __atan_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __atan_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __atan_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __atan_varying_half(varying float16) { @llvm.trap(); }
// EXT READNONE uniform double __cos_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __cos_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __cos_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __cos_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __cos_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __cos_varying_half(varying float16) { @llvm.trap(); }
// EXT void __sincos_uniform_double(uniform double, uniform int8 *uniform, uniform int8 *uniform) {
//     @llvm.trap();
// }
// EXT void __sincos_uniform_float(uniform float, uniform int8 *uniform, uniform int8 *uniform) { @llvm.trap(); }
// EXT void __sincos_uniform_half(uniform float16, uniform int8 *uniform, uniform int8 *uniform) { @llvm.trap(); }
// EXT void __sincos_varying_double(varying double, uniform int8 *uniform, uniform int8 *uniform) {
//     @llvm.trap();
// }
// EXT void __sincos_varying_float(varying float, uniform int8 *uniform, uniform int8 *uniform) { @llvm.trap(); }
// EXT void __sincos_varying_half(varying float16, uniform int8 *uniform, uniform int8 *uniform) { @llvm.trap(); }
// EXT READNONE uniform double __sin_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __sin_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __sin_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __sin_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __sin_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __sin_varying_half(varying float16) { @llvm.trap(); }
// EXT READNONE uniform double __tan_uniform_double(uniform double) { @llvm.trap(); }
// EXT READNONE uniform float __tan_uniform_float(uniform float) { @llvm.trap(); }
// EXT READNONE uniform float16 __tan_uniform_half(uniform float16) { @llvm.trap(); }
// EXT READNONE varying double __tan_varying_double(varying double) { @llvm.trap(); }
// EXT READNONE varying float __tan_varying_float(varying float) { @llvm.trap(); }
// EXT READNONE varying float16 __tan_varying_half(varying float16) { @llvm.trap(); }
// 
// // saturating math functions
// // m_hasSaturatingArithmetic
// // EXT uniform int64 __abs_ui64(uniform int64) { @llvm.trap(); }
// // EXT varying int64 __abs_vi64(varying int64) { @llvm.trap(); }
// EXT uniform int8 __padds_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT uniform int16 __padds_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __padds_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __padds_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT varying int8 __padds_vi8(varying int8, varying int8) { @llvm.trap(); }
// EXT varying int16 __padds_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __padds_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __padds_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT uniform int16 __paddus_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __paddus_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __paddus_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT uniform int8 __paddus_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT varying int16 __paddus_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __paddus_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __paddus_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT varying int8 __paddus_vi8(varying int8, varying int8) { @llvm.trap(); }
// // EXT uniform int16 __pdivs_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// // EXT uniform int32 __pdivs_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// // EXT uniform int64 __pdivs_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// // EXT uniform int8 __pdivs_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// // EXT varying int16 __pdivs_vi16(varying int16, varying int16) { @llvm.trap(); }
// // EXT varying int32 __pdivs_vi32(varying int32, varying int32) { @llvm.trap(); }
// // EXT varying int64 __pdivs_vi64(varying int64, varying int64) { @llvm.trap(); }
// // EXT varying int8 __pdivs_vi8(varying int8, varying int8) { @llvm.trap(); }
// // EXT uniform int16 __pdivus_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// // EXT uniform int32 __pdivus_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// // EXT uniform int64 __pdivus_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// // EXT uniform int8 __pdivus_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// // EXT varying int16 __pdivus_vi16(varying int16, varying int16) { @llvm.trap(); }
// // EXT varying int32 __pdivus_vi32(varying int32, varying int32) { @llvm.trap(); }
// // EXT varying int64 __pdivus_vi64(varying int64, varying int64) { @llvm.trap(); }
// // EXT varying int8 __pdivus_vi8(varying int8, varying int8) { @llvm.trap(); }
// EXT uniform int16 __pmuls_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __pmuls_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __pmuls_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT uniform int8 __pmuls_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT varying int16 __pmuls_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __pmuls_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __pmuls_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT varying int8 __pmuls_vi8(varying int8, varying int8) { @llvm.trap(); }
// EXT uniform int16 __pmulus_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __pmulus_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __pmulus_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT uniform int8 __pmulus_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT varying int16 __pmulus_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __pmulus_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __pmulus_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT varying int8 __pmulus_vi8(varying int8, varying int8) { @llvm.trap(); }
// EXT uniform int16 __psubs_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __psubs_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __psubs_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT uniform int8 __psubs_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT varying int16 __psubs_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __psubs_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __psubs_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT varying int8 __psubs_vi8(varying int8, varying int8) { @llvm.trap(); }
// EXT uniform int16 __psubus_ui16(uniform int16, uniform int16) { @llvm.trap(); }
// EXT uniform int32 __psubus_ui32(uniform int32, uniform int32) { @llvm.trap(); }
// EXT uniform int64 __psubus_ui64(uniform int64, uniform int64) { @llvm.trap(); }
// EXT uniform int8 __psubus_ui8(uniform int8, uniform int8) { @llvm.trap(); }
// EXT varying int16 __psubus_vi16(varying int16, varying int16) { @llvm.trap(); }
// EXT varying int32 __psubus_vi32(varying int32, varying int32) { @llvm.trap(); }
// EXT varying int64 __psubus_vi64(varying int64, varying int64) { @llvm.trap(); }
// EXT varying int8 __psubus_vi8(varying int8, varying int8) { @llvm.trap(); }

// rounding floats and doubles
EXT READNONE uniform double __ceil_uniform_double(uniform double x) { return @llvm.ceil(x); }
EXT READNONE uniform float __ceil_uniform_float(uniform float x) { return @llvm.ceil(x); }
EXT READNONE varying double __ceil_varying_double(varying double x) { return @llvm.ceil(x); }
EXT READNONE varying float __ceil_varying_float(varying float x) { return @llvm.ceil(x); }
EXT READNONE uniform double __floor_uniform_double(uniform double x) { return @llvm.floor(x); }
EXT READNONE uniform float __floor_uniform_float(uniform float x) { return @llvm.floor(x); }
EXT READNONE varying double __floor_varying_double(varying double x) { return @llvm.floor(x); }
EXT READNONE varying float __floor_varying_float(varying float x) { return @llvm.floor(x); }
EXT READNONE uniform double __round_uniform_double(uniform double x) { return @llvm.roundeven(x); }
EXT READNONE uniform float __round_uniform_float(uniform float x) { return @llvm.roundeven(x); }
EXT READNONE varying double __round_varying_double(varying double x) { return @llvm.roundeven(x); }
EXT READNONE varying float __round_varying_float(varying float x) { return @llvm.roundeven(x); }

// rcp
EXT READNONE uniform float __rcp_fast_uniform_float(uniform float x) { return 1 / x; }
EXT READNONE varying float __rcp_fast_varying_float(varying float x) { return 1 / x; }
EXT READNONE uniform float __rcp_uniform_float(uniform float x) { return 1 / x; }
EXT READNONE varying float __rcp_varying_float(varying float x) { return 1 / x; }

// EXT READNONE varying float __rsqrt_fast_varying_float(varying float x) { return 1 / @llvm.sqrt(x); }
// EXT READNONE uniform float __rsqrt_fast_uniform_float(uniform float x) { return 1 / @llvm.sqrt(x); }
// EXT READNONE varying float __rsqrt_varying_float(varying float x) { return 1 / @llvm.sqrt(x);}
// EXT READNONE uniform float __rsqrt_uniform_float(uniform float x) { return 1 / @llvm.sqrt(x); }

// sqrt for floats and doubles
EXT READNONE uniform double __sqrt_uniform_double(uniform double x) { return @llvm.sqrt(x); }
EXT READNONE uniform float __sqrt_uniform_float(uniform float x) { return @llvm.sqrt(x); }
EXT READNONE varying double __sqrt_varying_double(varying double x) { return @llvm.sqrt(x); }
EXT READNONE varying float __sqrt_varying_float(varying float x) { return @llvm.sqrt(x); }

// Implements uniform and varying trunc() for float and double types.
EXT READNONE uniform double __trunc_uniform_double(uniform double x) { return @llvm.trunc(x); }
EXT READNONE uniform float __trunc_uniform_float(uniform float x) { return @llvm.trunc(x); }
EXT READNONE varying double __trunc_varying_double(varying double x) { return @llvm.trunc(x); }
EXT READNONE varying float __trunc_varying_float(varying float x) { return @llvm.trunc(x); }

// transcendental float math functions
// __have_native_transcendentals
EXT READNONE uniform double __exp_uniform_double(uniform double) { __not_supported(); }
EXT READNONE uniform float __exp_uniform_float(uniform float) { __not_supported(); }
EXT READNONE varying double __exp_varying_double(varying double) { __not_supported(); }
EXT READNONE varying float __exp_varying_float(varying float) { __not_supported(); }
EXT READNONE uniform double __log_uniform_double(uniform double) { __not_supported(); }
EXT READNONE uniform float __log_uniform_float(uniform float) { __not_supported(); }
EXT READNONE varying double __log_varying_double(varying double) { __not_supported(); }
EXT READNONE varying float __log_varying_float(varying float) { __not_supported(); }
EXT READNONE uniform double __pow_uniform_double(uniform double, uniform double) { __not_supported(); }
EXT READNONE uniform float __pow_uniform_float(uniform float, uniform float) { __not_supported(); }
EXT READNONE varying double __pow_varying_double(varying double, varying double) { __not_supported(); }
EXT READNONE varying float __pow_varying_float(varying float, varying float) { __not_supported(); }

// __have_native_rcpd
EXT READNONE uniform double __rcp_fast_uniform_double(uniform double) { __not_supported(); }
EXT READNONE uniform double __rcp_uniform_double(uniform double) { __not_supported(); }
EXT READNONE varying double __rcp_fast_varying_double(varying double) { __not_supported(); }
EXT READNONE varying double __rcp_varying_double(varying double) { __not_supported(); }

// __have_native_half_full_support
EXT READNONE uniform float16 __rcp_uniform_half(uniform float16) { __not_supported(); }
EXT READNONE varying float16 __rcp_varying_half(varying float16) { __not_supported(); }
EXT READNONE uniform float16 __rsqrt_uniform_half(uniform float16) { __not_supported(); }
EXT READNONE varying float16 __rsqrt_varying_half(varying float16) { __not_supported(); }

// __have_native_rsqrtd
EXT READNONE uniform double __rsqrt_fast_uniform_double(uniform double) { __not_supported(); }
EXT READNONE varying double __rsqrt_fast_varying_double(varying double) { __not_supported(); }
EXT READNONE uniform double __rsqrt_uniform_double(uniform double)      { __not_supported(); }
EXT READNONE varying double __rsqrt_varying_double(varying double)      { __not_supported(); }

// dot product
// __have_dot_product_vnni
EXT READNONE varying int32 __dot2add_i16packed_sat(varying uint32, varying uint32, varying int32) { __not_supported(); }
EXT READNONE varying int32 __dot2add_i16packed(varying uint32, varying uint32, varying int32) { __not_supported(); }
EXT READNONE varying int32 __dot4add_u8i8packed_sat(varying uint32, varying uint32, varying int32) {
    __not_supported();
}
EXT READNONE varying int32 __dot4add_u8i8packed(varying uint32, varying uint32, varying int32) { __not_supported(); }

// half conversion routines TODO: change to __not_supported call
// __have_native_half_converts
EXT uniform int16 __float_to_half_uniform(uniform float x) { return x; }
EXT varying int16 __float_to_half_varying(varying float x) { return x; }
EXT uniform float __half_to_float_uniform(uniform int16 x) { return x; }
EXT varying float __half_to_float_varying(varying int16 x) { return x; }

// EXT void __prefetch_read_sized_uniform_1(uniform int8 *uniform, uniform int8) { @llvm.trap(); }
// EXT void __prefetch_read_sized_uniform_2(uniform int8 *uniform, uniform int8) { @llvm.trap(); }
// EXT void __prefetch_read_sized_uniform_3(uniform int8 *uniform, uniform int8) { @llvm.trap(); }
// EXT void __prefetch_read_sized_uniform_nt(uniform int8 *uniform, uniform int8) { @llvm.trap(); }
// EXT void __prefetch_read_sized_varying_1(varying int64, uniform int8, UIntMaskType) { @llvm.trap(); }
// EXT void __prefetch_read_sized_varying_2(varying int64, uniform int8, UIntMaskType) { @llvm.trap(); }
// EXT void __prefetch_read_sized_varying_3(varying int64, uniform int8, UIntMaskType) { @llvm.trap(); }
// EXT void __prefetch_read_sized_varying_nt(varying int64, uniform int8, UIntMaskType) { @llvm.trap(); }
// 
// // EXT void __memcpy32(uniform int8 *uniform dst, uniform int8 *uniform src, uniform int32 len) {
// //     @llvm.memcpy(dst, src, len, false);
// // }
// // EXT void __memcpy64(uniform int8 *uniform dst, uniform int8 *uniform src, uniform int64 len) {
// //     @llvm.memcpy(dst, src, len, false);
// // }
// // EXT void __memmove32(uniform int8 *uniform dst, uniform int8 *uniform src, uniform int32 len) {
// //     @llvm.memmove(dst, src, len, false);
// // }
// // EXT void __memmove64(uniform int8 *uniform dst, uniform int8 *uniform src, uniform int64 len) {
// //     @llvm.memmove(dst, src, len, false);
// // }
// // EXT void __memset32(uniform int8 *uniform dst, uniform int8 val, uniform int32 len) {
// //     @llvm.memset(dst, val, len, false);
// // }
// // EXT void __memset64(uniform int8 *uniform dst, uniform int8 val, uniform int64 len) {
// //     @llvm.memset(dst, val, len, false);
// // }
// // 
// // EXT uniform int32 puts(uniform int8 *uniform str);
// // EXT void abort();
// // EXT void __do_assume_uniform(uniform bool test) { @llvm.assume(test); }
// // 
// // EXT void __do_assert_uniform(uniform int8 *uniform str, uniform bool test, UIntMaskType) {
// //     if (!test) {
// //         puts(str);
// //         abort();
// //     }
// // }
// // EXT void __do_assert_varying(uniform int8 *uniform str, UIntMaskType test, UIntMaskType mask) {
// //     if (__any((test ^ 1) & mask)) {
// //         puts(str);
// //         abort();
// //     }
// // }
// 
// // read hw clock
// // Fix: generation of llvm.intrinsic here
// // EXT uniform int64 __clock() {
// //     uniform int64 c = @llvm.readcyclecounter();
// //     return c;
// // }

// stdlib transcendental functions
// These functions provide entrypoints that call out to the libm
// implementations of the transcendental functions
EXT READNONE uniform float sinf(uniform float);
EXT READNONE uniform float cosf(uniform float);
EXT void sincosf(uniform float, uniform float *uniform, uniform float *uniform);
EXT READNONE uniform float asinf(uniform float);
EXT READNONE uniform float acosf(uniform float);
EXT READNONE uniform float tanf(uniform float);
EXT READNONE uniform float atanf(uniform float);
EXT READNONE uniform float atan2f(uniform float, uniform float);
EXT READNONE uniform float expf(uniform float);
EXT READNONE uniform float logf(uniform float);
EXT READNONE uniform float powf(uniform float, uniform float);

EXT READNONE uniform float __stdlib_sinf(uniform float x) { return sinf(x); }
EXT READNONE uniform float __stdlib_cosf(uniform float x) { return cosf(x); }
EXT void __stdlib_sincosf(uniform float x, uniform float *uniform sin_v, uniform float *uniform cos_v) {
    sincosf(x, sin_v, cos_v);
}
EXT READNONE uniform float __stdlib_asinf(uniform float x) { return asinf(x); }
EXT READNONE uniform float __stdlib_acosf(uniform float x) { return acosf(x); }
EXT READNONE uniform float __stdlib_tanf(uniform float x) { return tanf(x); }
EXT READNONE uniform float __stdlib_atanf(uniform float x) { return atanf(x); }
EXT READNONE uniform float __stdlib_atan2f(uniform float x, uniform float y) { return atan2f(x, y); }
EXT READNONE uniform float __stdlib_logf(uniform float x) { return logf(x); }
EXT READNONE uniform float __stdlib_expf(uniform float x) { return expf(x); }
EXT READNONE uniform float __stdlib_powf(uniform float x, uniform float y) { return powf(x, y); }

EXT READNONE uniform double sin(uniform double);
EXT READNONE uniform double cos(uniform double);
EXT void sincos(uniform double, uniform double *uniform, uniform double *uniform);
EXT READNONE uniform double asin(uniform double);
EXT READNONE uniform double acos(uniform double);
EXT READNONE uniform double tan(uniform double);
EXT READNONE uniform double atan(uniform double);
EXT READNONE uniform double atan2(uniform double, uniform double);
EXT READNONE uniform double exp(uniform double);
EXT READNONE uniform double log(uniform double);
EXT READNONE uniform double pow(uniform double, uniform double);

EXT READNONE uniform double __stdlib_sin(uniform double x) { return sin(x); }
EXT READNONE uniform double __stdlib_cos(uniform double x) { return cos(x); }
EXT void __stdlib_sincos(uniform double x, uniform double *uniform sin_v, uniform double *uniform cos_v) {
    sincos(x, sin_v, cos_v);
}
EXT READNONE uniform double __stdlib_asin(uniform double x) { return asin(x); }
EXT READNONE uniform double __stdlib_acos(uniform double x) { return acos(x); }
EXT READNONE uniform double __stdlib_tan(uniform double x) { return tan(x); }
EXT READNONE uniform double __stdlib_atan(uniform double x) { return atan(x); }
EXT READNONE uniform double __stdlib_atan2(uniform double x, uniform double y) { return atan2(x, y); }
EXT READNONE uniform double __stdlib_log(uniform double x) { return log(x); }
EXT READNONE uniform double __stdlib_exp(uniform double x) { return exp(x); }
EXT READNONE uniform double __stdlib_pow(uniform double x, uniform double y) { return pow(x, y); }

// // /* Define macros for token concatenation */
// // #define CONCAT(a, b) a##b
// // #define CONCAT3(a, b, c) a##b##c
// // 
// // /* Ensure macro arguments are expanded before concatenation */
// // #define EXPAND_AND_CONCAT(a, b) CONCAT(a, b)
// // #define EXPAND_AND_CONCAT3(a, b, c) CONCAT3(a, b, c)
// // 
// // #define LLVM_ROUNDEVEN_V_F16 EXPAND_AND_CONCAT3(@llvm.roundeven.v, TARGET_WIDTH, f16)
// // #define LLVM_FLOOR_V_F16 EXPAND_AND_CONCAT3(@llvm.floor.v, TARGET_WIDTH, f16)
// // #define LLVM_CEIL_V_F16 EXPAND_AND_CONCAT3(@llvm.ceil.v, TARGET_WIDTH, f16)
// // #define LLVM_TRUNC_V_F16 EXPAND_AND_CONCAT3(@llvm.trunc.v, TARGET_WIDTH, f16)
// // #define LLVM_LOG_V_F16 EXPAND_AND_CONCAT3(@llvm.log.v, TARGET_WIDTH, f16)
// // #define LLVM_EXP_V_F16 EXPAND_AND_CONCAT3(@llvm.exp.v, TARGET_WIDTH, f16)
// // #define LLVM_POW_V_F16 EXPAND_AND_CONCAT3(@llvm.pow.v, TARGET_WIDTH, f16)
// // #define LLVM_SQRT_V_F16 EXPAND_AND_CONCAT3(@llvm.sqrt.v, TARGET_WIDTH, f16)

EXT READNONE uniform float16 __round_uniform_half(uniform float16 x) { return @llvm.roundeven(x); }
EXT READNONE varying float16 __round_varying_half(varying float16 x) { return @llvm.roundeven(x); }
EXT READNONE uniform float16 __floor_uniform_half(uniform float16 x) { return @llvm.floor(x); }
EXT READNONE varying float16 __floor_varying_half(varying float16 x) { return @llvm.floor(x); }
EXT READNONE uniform float16 __ceil_uniform_half(uniform float16 x) { return @llvm.ceil(x); }
EXT READNONE varying float16 __ceil_varying_half(varying float16 x) { return @llvm.ceil(x); }
EXT READNONE uniform float16 __trunc_uniform_half(uniform float16 x) { return @llvm.trunc(x); }
EXT READNONE varying float16 __trunc_varying_half(varying float16 x) { return @llvm.trunc(x); }
EXT READNONE uniform float16 __log_uniform_half(uniform float16 x) { return @llvm.log(x); }
EXT READNONE varying float16 __log_varying_half(varying float16 x) { return @llvm.log(x); }
EXT READNONE uniform float16 __exp_uniform_half(uniform float16 x) { return @llvm.exp(x); }
EXT READNONE varying float16 __exp_varying_half(varying float16 x) { return @llvm.exp(x); }
EXT READNONE uniform float16 __pow_uniform_half(uniform float16 x, uniform float16 y) { return @llvm.pow(x, y); }
EXT READNONE varying float16 __pow_varying_half(varying float16 x, varying float16 y) { return @llvm.pow(x, y); }
EXT READNONE uniform float16 __sqrt_uniform_half(uniform float16 x) { return @llvm.sqrt(x); }
EXT READNONE varying float16 __sqrt_varying_half(varying float16 x) { return @llvm.sqrt(x); }

// EXT READNONE uniform float16 __min_uniform_half(uniform float16 x, uniform float16 y) { return x < y ? x : y; }
// EXT READNONE varying float16 __min_varying_half(varying float16 x, varying float16 y) { return x < y ? x : y; }
// EXT READNONE uniform float16 __max_uniform_half(uniform float16 x, uniform float16 y) { return x > y ? x : y; }
// EXT READNONE varying float16 __max_varying_half(varying float16 x, varying float16 y) { return x > y ? x : y; }
// 
// // #if TARGET_WIDTH == 2
// // #define ONE_INITIALIZER 1, 1
// // #elif TARGET_WIDTH == 4
// // #define ONE_INITIALIZER 1, 1, 1, 1
// // #elif TARGET_WIDTH == 8
// // #define ONE_INITIALIZER 1, 1, 1, 1, 1, 1, 1, 1
// // #elif TARGET_WIDTH == 16
// // #define ONE_INITIALIZER 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
// // #elif TARGET_WIDTH == 32
// // #define ONE_INITIALIZER 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
// // #elif TARGET_WIDTH == 64
// // #define ONE_INITIALIZER                                                                                                \
// //     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  \
// //         1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
// // #else
// // #error Unknown value of TARGET_WIDTH
// // #endif

// int8/int16 avg builtins
EXT varying uint8 __avg_up_uint8(varying uint8 a, varying uint8 b) { return ((uint16)a + (uint16)b + 1) >> 1; }
EXT varying int8 __avg_up_int8(varying int8 a, varying int8 b) { return ((int16)a + (int16)b + 1) / 2; }
EXT varying uint16 __avg_up_uint16(varying uint16 a, varying uint16 b) { return ((uint32)a + (uint32)b + 1) >> 1; }
EXT varying int16 __avg_up_int16(varying int16 a, varying int16 b) { return ((int32)a + (int32)b + 1) >> 1; }
EXT varying uint8 __avg_down_uint8(varying uint8 a, varying uint8 b) { return ((uint16)a + (uint16)b) >> 1; }
EXT varying int8 __avg_down_int8(varying int8 a, varying int8 b) { return ((int16)a + (int16)b) / 2; }
EXT varying uint16 __avg_down_uint16(varying uint16 a, varying uint16 b) { return ((uint32)a + (uint32)b) >> 1; }
EXT varying int16 __avg_down_int16(varying int16 a, varying int16 b) { return ((int32)a + (int32)b) / 2; }

// count trailing zeros
EXT READNONE uniform int32 __count_trailing_zeros_i32(uniform int32 x) { return @llvm.cttz(x, false); }
EXT READNONE uniform int64 __count_trailing_zeros_i64(uniform int64 x) { return @llvm.cttz(x, false); }
EXT READNONE uniform int32 __count_leading_zeros_i32(uniform int32 x) { return @llvm.ctlz(x, false); }
EXT READNONE uniform int64 __count_leading_zeros_i64(uniform int64 x) { return @llvm.ctlz(x, false); }

// population count
EXT uniform int32 __popcnt_int32(uniform int32 x) { return @llvm.ctpop(x); }
EXT uniform int64 __popcnt_int64(uniform int64 x) { return @llvm.ctpop(x); }

// // // vector ops
// // EXT uniform bool __extract_bool(IntMaskType vec, uniform int32 lane);
// // // {
// // //     IntMaskType mem = vec;
// // //     uniform bool *uniform ptr = (uniform bool *uniform) & mem;
// // //     return ptr[lane];
// // // }
// // EXT uniform int16 __extract_int16(varying int16 vec, uniform int32 lane);
// // // {
// // //     varying int16 mem = vec;
// // //     uniform int16 *uniform ptr = (uniform int16 *uniform)&mem;
// // //     return ptr[lane];
// // // }
// // EXT uniform int32 __extract_int32(varying int32 vec, uniform int32 lane);
// // // {
// // //     varying int32 mem = vec;
// // //     uniform int32 *uniform ptr = (uniform int32 *uniform)&mem;
// // //     return ptr[lane];
// // // }
// // EXT uniform int64 __extract_int64(varying int64 vec, uniform int32 lane);
// // // {
// // //     varying int64 mem = vec;
// // //     uniform int64 *uniform ptr = (uniform int64 *uniform)&mem;
// // //     return ptr[lane];
// // // }
// // EXT uniform int8 __extract_int8(varying int8 vec, uniform int32 lane);
// // // {
// // //     varying int8 mem = vec;
// // //     uniform int8 *uniform ptr = (uniform int8 *uniform)&mem;
// // //     return ptr[lane];
// // // }
// // EXT READNONE IntMaskType __insert_bool(IntMaskType vec, uniform int32 lane, uniform bool val);
// // EXT READNONE varying int16 __insert_int16(varying int16 vec, uniform int32 lane, uniform int16 val);
// // EXT READNONE varying int32 __insert_int32(varying int32 vec, uniform int32 lane, uniform int32 val);
// // EXT READNONE varying int64 __insert_int64(varying int64 vec, uniform int32 lane, uniform int64 val);
// // EXT READNONE varying int8 __insert_int8(varying int8 vec, uniform int32 lane, uniform int8 val);
// // 
// // // prefetching
// // EXT void __prefetch_read_uniform_1(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 0, 3, 1); }
// // EXT void __prefetch_read_uniform_2(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 0, 2, 1); }
// // EXT void __prefetch_read_uniform_3(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 0, 1, 1); }
// // EXT void __prefetch_read_uniform_nt(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 0, 0, 1); }
// // EXT void __prefetch_write_uniform_1(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 1, 3, 1); }
// // EXT void __prefetch_write_uniform_2(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 1, 2, 1); }
// // EXT void __prefetch_write_uniform_3(uniform int8 *uniform ptr) { @llvm.prefetch(ptr, 1, 1, 1); }
// // UNMANGLED CDECL void __prefetch_read_varying_1(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_read_uniform_1((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_read_varying_2(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_read_uniform_2((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_read_varying_3(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_read_uniform_3((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_read_varying_nt(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_read_uniform_nt((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_write_varying_1(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_write_uniform_1((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_write_varying_2(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_write_uniform_2((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_write_varying_3(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         __prefetch_write_uniform_3((uniform int8 * uniform) p_lane);
// //     }
// // }
// // UNMANGLED CDECL void __prefetch_write_varying_3_native(uniform int8 *uniform, uniform int32, varying int32) {
// //     @llvm.trap();
// // }
// 
// // EXT READNONE varying int8 __shuffle_i8(varying int8 v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform int8 lane = __extract_int8(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int8(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying int16 __shuffle_i16(varying int16 v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform int16 lane = __extract_int16(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int16(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying int32 __shuffle_i32(varying int32 v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform int32 lane = __extract_int32(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int32(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying int64 __shuffle_i64(varying int64 v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform int64 lane = __extract_int64(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int64(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying float16 __shuffle_half(varying float16 v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform float16 lane = __extract_int16(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int16(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying float __shuffle_float(varying float v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform float lane = __extract_int32(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int32(result, new_pos, lane);
// //     }
// //     return result;
// // }
// // EXT READNONE varying double __shuffle_double(varying double v, varying int32 perm) {
// //     varying double result = 0;
// //     for (uniform int32 i = 0; i < TARGET_WIDTH; i++) {
// //         uniform double lane = __extract_int64(v, i);
// //         uniform int32 new_pos = __extract_int32(perm, i);
// //         result = __insert_int64(result, new_pos, lane);
// //     }
// //     return result;
// // }
// 
// // EXT READNONE varying double __shuffle2_double(varying double, varying double, varying int32);
// // EXT READNONE varying float __shuffle2_float(varying float, varying float, varying int32);
// // EXT READNONE varying float16 __shuffle2_half(varying float16, varying float16, varying int32);
// // EXT READNONE varying int16 __shuffle2_i16(varying int16, varying int16, varying int32);
// // EXT READNONE varying int32 __shuffle2_i32(varying int32, varying int32, varying int32);
// // EXT READNONE varying int64 __shuffle2_i64(varying int64, varying int64, varying int32);
// // EXT READNONE varying int8 __shuffle2_i8(varying int8, varying int8, varying int32);
// 
// // #ifndef BUILD_OS
// // #error "BUILD_OS not defined"
// // #endif
// // 
// // #ifndef RUNTIME
// // #error "RUNTIME not defined"
// // #endif
// // 
// // EXT uniform int32 posix_memalign(uniform int8 *uniform *uniform, uniform int32, uniform int32);
// // EXT void free(uniform int8 *uniform);
// // 
// // // new/delete
// // #if BUILD_OS == UNIX && RUNTIME == 32
// // EXT uniform int8 *uniform __new_uniform_32rt(uniform int64 size) {
// //     uniform int8 *uniform ptr = 0;
// //     posix_memalign(&ptr, __memory_alignment, size);
// //     return ptr;
// // }
// // UNMANGLED CDECL varying int64 __new_varying32_32rt(varying int32 size) {
// //     varying int64 addr = 0;
// //     foreach_active(i) {
// //         uniform int64 s = __extract_int32(size, i);
// //         uniform int8 *uniform ptr = 0;
// //         posix_memalign(&ptr, __memory_alignment, s);
// //         addr = __insert_int64(addr, i, (uniform int64)ptr);
// //     }
// //     return addr;
// // }
// // EXT void __delete_uniform_32rt(uniform int8 *uniform ptr) { free(ptr); }
// // UNMANGLED CDECL void __delete_varying_32rt(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         free((uniform int8 *uniform) p_lane);
// //     }
// // }
// // #endif // BUILD_OS == UNIX && RUNTIME == 32
// // #if BUILD_OS == UNIX && RUNTIME == 64
// // EXT uniform int8 *uniform __new_uniform_64rt(uniform int64 size) {
// //     uniform int8 *uniform ptr = 0;
// //     posix_memalign(&ptr, __memory_alignment, size);
// //     return ptr;
// // }
// // UNMANGLED CDECL varying int64 __new_varying32_64rt(varying int32 size) {
// //     varying int64 addr = 0;
// //     foreach_active(i) {
// //         uniform int32 s = __extract_int32(size, i);
// //         uniform int8 *uniform ptr = 0;
// //         posix_memalign(&ptr, __memory_alignment, s);
// //         addr = __insert_int64(addr, i, (uniform int64)ptr);
// //     }
// //     return addr;
// // }
// // UNMANGLED CDECL varying int64 __new_varying64_64rt(varying int64 size) {
// //     varying int64 addr = 0;
// //     foreach_active(i) {
// //         uniform int64 s = __extract_int64(size, i);
// //         uniform int8 *uniform ptr = 0;
// //         posix_memalign(&ptr, __memory_alignment, s);
// //         addr = __insert_int64(addr, i, (uniform int64)ptr);
// //     }
// //     return addr;
// // }
// // EXT void __delete_uniform_64rt(uniform int8 *uniform ptr) { free(ptr); }
// // UNMANGLED CDECL void __delete_varying_64rt(varying int64 addr) {
// //     foreach_active(i) {
// //         uniform int64 p_lane = __extract_int64(addr, i);
// //         free((uniform int8 * uniform) p_lane);
// //     }
// // }
// // #endif // BUILD_OS == UNIX && RUNTIME == 64
// // 
// // // various bitcasts from one type to another
// // EXT inline READNONE uniform double __doublebits_uniform_int64(uniform int64);
// // EXT inline READNONE varying double __doublebits_varying_int64(varying int64);
// // EXT inline READNONE uniform float __floatbits_uniform_int32(uniform int32);
// // EXT inline READNONE varying float __floatbits_varying_int32(varying int32);
// // EXT inline READNONE uniform float16 __halfbits_uniform_int16(uniform int16);
// // EXT inline READNONE varying float16 __halfbits_varying_int16(varying int16);
// // EXT inline READNONE uniform int64 __intbits_uniform_double(uniform double);
// // EXT inline READNONE uniform int32 __intbits_uniform_float(uniform float);
// // EXT inline READNONE uniform int16 __intbits_uniform_half(uniform float16);
// // EXT inline READNONE varying int64 __intbits_varying_double(varying double);
// // EXT inline READNONE varying int32 __intbits_varying_float(varying float);
// // EXT inline READNONE varying int16 __intbits_varying_half(varying float16);
// // EXT uniform float __undef_uniform();
// // EXT varying float __undef_varying();
// // EXT varying int8 __masked_load_i8(uniform int8 *uniform, UIntMaskType);
// // EXT varying int16 __masked_load_i16(uniform int8 *uniform, UIntMaskType);
// // EXT varying int32 __masked_load_i32(uniform int8 *uniform, UIntMaskType);
// // EXT varying int64 __masked_load_i64(uniform int8 *uniform, UIntMaskType);
// // 
// // EXT varying float16 __masked_load_half(uniform int8 *uniform ptr, UIntMaskType mask) {
// //     return __halfbits_varying_int16(__masked_load_i16(ptr, mask));
// // }
// // EXT varying float __masked_load_float(uniform int8 *uniform ptr, UIntMaskType mask) {
// //     return __floatbits_varying_int32(__masked_load_i32(ptr, mask));
// // }
// // EXT varying double __masked_load_double(uniform int8 *uniform ptr, UIntMaskType mask) {
// //     return __doublebits_varying_int64(__masked_load_i64(ptr, mask));
// // }
// // UNMANGLED CDECL void __masked_store_i8(NOESCAPE varying int8 *uniform ptr, varying int8 val) {
// //     foreach_active(i) {
// //         uniform int8 *uniform ptr_lane = (uniform int8 * uniform) ptr;
// //         uniform int8 val_lane = __extract_int8(val, i);
// //         ptr_lane[i] = val_lane;
// //     }
// // }
// // UNMANGLED CDECL void __masked_store_i16(NOESCAPE varying int16 *uniform ptr, varying int16 val) {
// //     foreach_active(i) {
// //         uniform int16 *uniform ptr_lane = (uniform int16 * uniform) ptr;
// //         uniform int16 val_lane = __extract_int16(val, i);
// //         ptr_lane[i] = val_lane;
// //     }
// // }
// // UNMANGLED CDECL void __masked_store_i32(NOESCAPE varying int32 *uniform ptr, varying int32 val) {
// //     foreach_active(i) {
// //         uniform int32 *uniform ptr_lane = (uniform int32 * uniform) ptr;
// //         uniform int32 val_lane = __extract_int32(val, i);
// //         ptr_lane[i] = val_lane;
// //     }
// // }
// // UNMANGLED CDECL void __masked_store_i64(NOESCAPE varying int64 *uniform ptr, varying int64 val) {
// //     foreach_active(i) {
// //         uniform int64 *uniform ptr_lane = (uniform int64 * uniform) ptr;
// //         uniform int64 val_lane = __extract_int64(val, i);
// //         ptr_lane[i] = val_lane;
// //     }
// // }
// // EXT void __masked_store_half(NOESCAPE varying float16 *uniform ptr, varying float16 val, UIntMaskType mask) {
// //     __masked_store_i16((varying int16 * uniform) ptr, val, mask);
// // }
// // EXT void __masked_store_float(NOESCAPE varying float *uniform ptr, varying float val, UIntMaskType mask) {
// //     __masked_store_i32((varying int32 * uniform) ptr, val, mask);
// // }
// // EXT void __masked_store_double(NOESCAPE varying double *uniform ptr, varying double val, UIntMaskType mask) {
// //     __masked_store_i64((varying int64 * uniform) ptr, val, mask);
// // }
// // UNMANGLED CDECL void __masked_store_blend_i8(NOESCAPE varying int8 *uniform ptr, varying int8 val) { *ptr = val; }
// // UNMANGLED CDECL void __masked_store_blend_i16(NOESCAPE varying int16 *uniform ptr, varying int16 val) { *ptr = val; }
// // UNMANGLED CDECL void __masked_store_blend_i32(NOESCAPE varying int32 *uniform ptr, varying int32 val) { *ptr = val; }
// // UNMANGLED CDECL void __masked_store_blend_i64(NOESCAPE varying int64 *uniform ptr, varying int64 val) { *ptr = val; }
// // UNMANGLED CDECL void __masked_store_blend_half(NOESCAPE varying float16 *uniform ptr, varying float16 val) {
// //     *ptr = val;
// // }
// // UNMANGLED CDECL void __masked_store_blend_float(NOESCAPE varying float *uniform ptr, varying float val) { *ptr = val; }
// // UNMANGLED CDECL void __masked_store_blend_double(NOESCAPE varying double *uniform ptr, varying double val) {
// //     *ptr = val;
// // }

#undef NOESCAPE
#undef ADDRSPACE
#undef READONLY
#undef READNONE
#undef NOALIAS
#undef EXT
