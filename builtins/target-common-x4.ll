;;  copyright (c) 2016-2024, intel corporation
;;
;;  SPDX-License-Identifier: BSD-3-Clause

declare i32 @llvm.ctlz.i32(i32)
declare i64 @llvm.ctlz.i64(i64)
declare i32 @llvm.cttz.i32(i32)
declare i64 @llvm.cttz.i64(i64)

declare i32 @llvm.ctpop.i32(i32) nounwind readnone
declare i64 @llvm.ctpop.i64(i64) nounwind readnone

define(`WIDTH',`4')
define(`ISA',`AVX512SKX')

;; start of included(`target-avx512-common-4.ll')

;; start of included(`target-avx512-utils.ll')
define(`MASK',`i1')
define(`HAVE_GATHER',`1')
define(`HAVE_SCATTER',`1')

;; start of included(`util.m4')
;; This file provides a variety of macros used to generate LLVM bitcode
;; parametrized in various ways.  Implementations of the standard library
;; builtins for various targets can use macros from this file to simplify
;; generating code for their implementations of those builtins.

;; argn allows to portably select greater than ninth argument without relying
;; on the GNU extension of multi-digit arguments.
define(`argn', `ifelse(`$1', 1, ``$2'', `argn(decr(`$1'), shift(shift($@)))')')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; It is a bit of a pain to compute this in m4 for 32 and 64-wide targets...
define(`ALL_ON_MASK',
`ifelse(WIDTH, `64', `-1',
        WIDTH, `32', `4294967295',
                     `eval((1<<WIDTH)-1)')')

define(`MASK_HIGH_BIT_ON',
`ifelse(WIDTH, `64', `-9223372036854775808',
        WIDTH, `32', `2147483648',
                     `eval(1<<(WIDTH-1))')')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define(`PTR_OP_ARGS',
    `$1 , $1 *'
)

define(`MdORi64',
  ``i64''
)

define(`MfORi32',
  ``i32''
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper functions for mangling overloaded LLVM intrinsics
define(`LLVM_OVERLOADED_TYPE',
`ifelse($1, `i1', `i1',
        $1, `i8', `i8',
        $1, `i16', `i16',
        $1, `half', `f16',
        $1, `i32', `i32',
        $1, `float', `f32',
        $1, `double', `f64',
        $1, `i64', `i64')')

define(`SIZEOF',
`ifelse($1, `i1', 1,
        $1, `i8', 1,
        $1, `i16', 2,
        $1, `half', 2,
        $1, `i32', 4,
        $1, `float', 4,
        $1, `double', 8,
        $1, `i64', 8)')

define(`CONCAT',`$1$2')
define(`TYPE_SUFFIX',`CONCAT(`v', CONCAT(WIDTH, LLVM_OVERLOADED_TYPE($1)))')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; forloop macro

divert(`-1')
# forloop(var, from, to, stmt) - improved version:
#   works even if VAR is not a strict macro name
#   performs sanity check that FROM is larger than TO
#   allows complex numerical expressions in TO and FROM
define(`forloop', `ifelse(eval(`($3) >= ($2)'), `1',
  `pushdef(`$1', eval(`$2'))_$0(`$1',
    eval(`$3'), `$4')popdef(`$1')')')
define(`_forloop',
  `$3`'ifelse(indir(`$1'), `$2', `',
    `define(`$1', incr(indir(`$1')))$0($@)')')
divert`'dnl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; stdlib_core
;;
;; This macro defines a bunch of helper routines that depend on the
;; target's vector width
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global_atomic_associative
;; More efficient implementation for atomics that are associative (e.g.,
;; add, and, ...).  If a basic implementation would do sometihng like:
;; result0 = atomic_op(ptr, val0)
;; result1 = atomic_op(ptr, val1)
;; ..
;; Then instead we can do:
;; tmp = (val0 op val1 op ...)
;; result0 = atomic_op(ptr, tmp)
;; result1 = (result0 op val0)
;; ..
;; And more efficiently compute the same result
;;
;; Takes five parameters:
;; $1: vector width of the target
;; $2: operation being performed (w.r.t. LLVM atomic intrinsic names)
;;     (add, sub...)
;; $3: return type of the LLVM atomic (e.g. i32)
;; $4: return type of the LLVM atomic type, in ispc naming paralance (e.g. int32)
;; $5: identity value for the operator (e.g. 0 for add, -1 for AND, ...)

define(`mask_converts', `
define internal <$1 x i8> @convertmask_i1_i8_$1(<$1 x i1>) {
  %r = sext <$1 x i1> %0 to <$1 x i8>
  ret <$1 x i8> %r
}
define internal <$1 x i16> @convertmask_i1_i16_$1(<$1 x i1>) {
  %r = sext <$1 x i1> %0 to <$1 x i16>
  ret <$1 x i16> %r
}
define internal <$1 x i32> @convertmask_i1_i32_$1(<$1 x i1>) {
  %r = sext <$1 x i1> %0 to <$1 x i32>
  ret <$1 x i32> %r
}
define internal <$1 x i64> @convertmask_i1_i64_$1(<$1 x i1>) {
  %r = sext <$1 x i1> %0 to <$1 x i64>
  ret <$1 x i64> %r
}

define internal <$1 x i8> @convertmask_i8_i8_$1(<$1 x i8>) {
  ret <$1 x i8> %0
}
define internal <$1 x i16> @convertmask_i8_i86_$1(<$1 x i8>) {
  %r = sext <$1 x i8> %0 to <$1 x i16>
  ret <$1 x i16> %r
}
define internal <$1 x i32> @convertmask_i8_i32_$1(<$1 x i8>) {
  %r = sext <$1 x i8> %0 to <$1 x i32>
  ret <$1 x i32> %r
}
define internal <$1 x i64> @convertmask_i8_i64_$1(<$1 x i8>) {
  %r = sext <$1 x i8> %0 to <$1 x i64>
  ret <$1 x i64> %r
}

define internal <$1 x i8> @convertmask_i16_i8_$1(<$1 x i16>) {
  %r = trunc <$1 x i16> %0 to <$1 x i8>
  ret <$1 x i8> %r
}
define internal <$1 x i16> @convertmask_i16_i16_$1(<$1 x i16>) {
  ret <$1 x i16> %0
}
define internal <$1 x i32> @convertmask_i16_i32_$1(<$1 x i16>) {
  %r = sext <$1 x i16> %0 to <$1 x i32>
  ret <$1 x i32> %r
}
define internal <$1 x i64> @convertmask_i16_i64_$1(<$1 x i16>) {
  %r = sext <$1 x i16> %0 to <$1 x i64>
  ret <$1 x i64> %r
}

define internal <$1 x i8> @convertmask_i32_i8_$1(<$1 x i32>) {
  %r = trunc <$1 x i32> %0 to <$1 x i8>
  ret <$1 x i8> %r
}
define internal <$1 x i16> @convertmask_i32_i16_$1(<$1 x i32>) {
  %r = trunc <$1 x i32> %0 to <$1 x i16>
  ret <$1 x i16> %r
}
define internal <$1 x i32> @convertmask_i32_i32_$1(<$1 x i32>) {
  ret <$1 x i32> %0
}
define internal <$1 x i64> @convertmask_i32_i64_$1(<$1 x i32>) {
  %r = sext <$1 x i32> %0 to <$1 x i64>
  ret <$1 x i64> %r
}

define internal <$1 x i8> @convertmask_i64_i8_$1(<$1 x i64>) {
  %r = trunc <$1 x i64> %0 to <$1 x i8>
  ret <$1 x i8> %r
}
define internal <$1 x i16> @convertmask_i64_i16_$1(<$1 x i64>) {
  %r = trunc <$1 x i64> %0 to <$1 x i16>
  ret <$1 x i16> %r
}
define internal <$1 x i32> @convertmask_i64_i32_$1(<$1 x i64>) {
  %r = trunc <$1 x i64> %0 to <$1 x i32>
  ret <$1 x i32> %r
}
define internal <$1 x i64> @convertmask_i64_i64_$1(<$1 x i64>) {
  ret <$1 x i64> %0
}
')

mask_converts(WIDTH)

define(`global_atomic_associative', `

define <$1 x $3> @__atomic_$2_$4_global(i8 * %ptr, <$1 x $3> %val,
                                        <$1 x MASK> %m) nounwind alwaysinline {
  %ptr_typed = bitcast i8* %ptr to $3*
  ; first, for any lanes where the mask is off, compute a vector where those lanes
  ; hold the identity value..

  ; for the bit tricks below, we need the mask to have the
  ; the same element size as the element type.
  %mask = call <$1 x $3> @convertmask_`'MASK`'_$3_$1(<$1 x MASK> %m)

  ; zero out any lanes that are off
  %valoff = and <$1 x $3> %val, %mask

  ; compute an identity vector that is zero in on lanes and has the identiy value
  ; in the off lanes
  %idv1 = bitcast $3 $5 to <1 x $3>
  %idvec = shufflevector <1 x $3> %idv1, <1 x $3> undef,
     <$1 x i32> < forloop(i, 1, eval($1-1), `i32 0, ') i32 0 >
  %notmask = xor <$1 x $3> %mask, < forloop(i, 1, eval($1-1), `$3 -1, ') $3 -1 >
  %idoff = and <$1 x $3> %idvec, %notmask

  ; and comptue the merged vector that holds the identity in the off lanes
  %valp = or <$1 x $3> %valoff, %idoff

  ; now compute the local reduction (val0 op val1 op ... )--initialize
  ; %eltvec so that the 0th element is the identity, the first is val0,
  ; the second is (val0 op val1), ..
  %red0 = extractelement <$1 x $3> %valp, i32 0
  %eltvec0 = insertelement <$1 x $3> undef, $3 $5, i32 0

  forloop(i, 1, eval($1-1), `
  %elt`'i = extractelement <$1 x $3> %valp, i32 i
  %red`'i = $2 $3 %red`'eval(i-1), %elt`'i
  %eltvec`'i = insertelement <$1 x $3> %eltvec`'eval(i-1), $3 %red`'eval(i-1), i32 i')

  ; make the atomic call, passing it the final reduced value
  %final0 = atomicrmw $2 $3 * %ptr_typed, $3 %red`'eval($1-1) seq_cst

  ; now go back and compute the values to be returned for each program
  ; instance--this just involves smearing the old value returned from the
  ; actual atomic call across the vector and applying the vector op to the
  ; %eltvec vector computed above..
  %finalv1 = bitcast $3 %final0 to <1 x $3>
  %final_base = shufflevector <1 x $3> %finalv1, <1 x $3> undef,
     <$1 x i32> < forloop(i, 1, eval($1-1), `i32 0, ') i32 0 >
  %r = $2 <$1 x $3> %final_base, %eltvec`'eval($1-1)

  ret <$1 x $3> %r
}
')

;; This is a basic atomic operation implementation for atomics that are associative
;; for float types.
;;
;; Takes four parameters:
;; $1: vector width of the target
;; $2: operation being performed (w.r.t. LLVM atomic intrinsic names)
;;     (fadd, fsub...)
;; $3: return type of the LLVM atomic (e.g. float)
;; $4: return type of the LLVM atomic type, in ispc naming paralance (e.g. float)

define(`global_atomic_associative_fp', `
define <$1 x $3> @__atomic_$2_$4_global(i8* %ptr, <$1 x $3> %val,
                                        <$1 x MASK> %m) nounwind alwaysinline {
  %ret_ptr = alloca <$1 x $3>
  per_lane($1, <$1 x MASK> %m, `
    %val_LANE_ID = extractelement <$1 x $3> %val, i32 LANE
    %res_LANE_ID = call $3 @__atomic_$2_uniform_$4_global(i8 * %ptr, $3 %val_LANE_ID)
    %store_ptr_LANE_ID = getelementptr PTR_OP_ARGS(`<$1 x $3>') %ret_ptr, i32 0, i32 LANE
    store $3 %res_LANE_ID, $3 * %store_ptr_LANE_ID
  ')
  %res = load PTR_OP_ARGS(`<$1 x $3> ')  %ret_ptr

  ret <$1 x $3> %res
}
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global_atomic_uniform
;; Defines the implementation of a function that handles the mapping from
;; an ispc atomic function to the underlying LLVM intrinsics.  This variant
;; just calls the atomic once, for the given uniform value
;;
;; Takes four parameters:
;; $1: vector width of the target
;; $2: operation being performed (w.r.t. LLVM atomic intrinsic names)
;;     (add, sub...)
;; $3: return type of the LLVM atomic (e.g. i32)
;; $4: return type of the LLVM atomic type, in ispc naming paralance (e.g. int32)

define(`global_atomic_uniform', `
declare $3 @__atomic_$2_uniform_$4_global(i8 * %ptr, $3 %val) nounwind alwaysinline
')

;; Similarly, macro to declare the function that implements the compare/exchange
;; atomic.  Takes three parameters:
;; $1: vector width of the target
;; $2: llvm type of the vector elements (e.g. i32)
;; $3: ispc type of the elements (e.g. int32)

define(`global_atomic_exchange', `

define <$1 x $2> @__atomic_compare_exchange_$3_global(i8* %ptr, <$1 x $2> %cmp,
                               <$1 x $2> %val, <$1 x MASK> %mask) nounwind alwaysinline {
  %rptr = alloca <$1 x $2>
  %rptr32 = bitcast <$1 x $2> * %rptr to $2 *
  %ptr_typed = bitcast i8* %ptr to $2*

  per_lane($1, <$1 x MASK> %mask, `
   %cmp_LANE_ID = extractelement <$1 x $2> %cmp, i32 LANE
   %val_LANE_ID = extractelement <$1 x $2> %val, i32 LANE
   %r_LANE_ID_t = cmpxchg $2 * %ptr_typed, $2 %cmp_LANE_ID, $2 %val_LANE_ID seq_cst seq_cst
   %r_LANE_ID = extractvalue { $2, i1 } %r_LANE_ID_t, 0
   %rp_LANE_ID = getelementptr PTR_OP_ARGS(`$2') %rptr32, i32 LANE
   store $2 %r_LANE_ID, $2 * %rp_LANE_ID')
   %r = load PTR_OP_ARGS(`<$1 x $2> ')  %rptr
   ret <$1 x $2> %r
}

define $2 @__atomic_compare_exchange_uniform_$3_global(i8* %ptr, $2 %cmp,
                                                       $2 %val) nounwind alwaysinline {
   %ptr_typed = bitcast i8* %ptr to $2*
   %r_t = cmpxchg $2 * %ptr_typed, $2 %cmp, $2 %val seq_cst seq_cst
   %r = extractvalue { $2, i1 } %r_t, 0
   ret $2 %r
}
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


define(`stdlib_core', `

@__fast_masked_vload = external global i32

declare i1 @__is_compile_time_constant_mask(<WIDTH x MASK> %mask)
declare i1 @__is_compile_time_constant_uniform_int32(i32)
declare i1 @__is_compile_time_constant_varying_int32(<WIDTH x i32>)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; read hw clock

declare i64 @llvm.readcyclecounter()

ifelse(HAS_CUSTOM_CLOCK, `1',`
',`
define i64 @__clock() nounwind {
  %r = call i64 @llvm.readcyclecounter()
  ret i64 %r
}
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; atomics and memory barriers

define void @__memory_barrier() nounwind readnone alwaysinline {
  ;; see http://llvm.org/bugs/show_bug.cgi?id=2829.  It seems like we
  ;; only get an MFENCE on x86 if "device" is true, but IMHO we should
  ;; in the case where the first 4 args are true but it is false.
  ;; So we just always set that to true...
  ;; LLVM.MEMORY.BARRIER was deprecated from version 3.0
  ;; Replacing it with relevant instruction
  fence seq_cst
  ret void
}

global_atomic_associative(WIDTH, add, i32, int32, 0)
global_atomic_associative(WIDTH, sub, i32, int32, 0)
global_atomic_associative(WIDTH, and, i32, int32, -1)
global_atomic_associative(WIDTH, or, i32, int32, 0)
global_atomic_associative(WIDTH, xor, i32, int32, 0)
global_atomic_uniform(WIDTH, add, i32, int32)
global_atomic_uniform(WIDTH, sub, i32, int32)
global_atomic_uniform(WIDTH, and, i32, int32)
global_atomic_uniform(WIDTH, or, i32, int32)
global_atomic_uniform(WIDTH, xor, i32, int32)
global_atomic_uniform(WIDTH, min, i32, int32)
global_atomic_uniform(WIDTH, max, i32, int32)
global_atomic_uniform(WIDTH, umin, i32, uint32)
global_atomic_uniform(WIDTH, umax, i32, uint32)

global_atomic_associative_fp(WIDTH, fadd, float, float)
global_atomic_associative_fp(WIDTH, fsub, float, float)
global_atomic_uniform(WIDTH, fadd, float, float)
global_atomic_uniform(WIDTH, fsub, float, float)
global_atomic_uniform(WIDTH, fmin, float, float)
global_atomic_uniform(WIDTH, fmax, float, float)

global_atomic_associative(WIDTH, add, i64, int64, 0)
global_atomic_associative(WIDTH, sub, i64, int64, 0)
global_atomic_associative(WIDTH, and, i64, int64, -1)
global_atomic_associative(WIDTH, or, i64, int64, 0)
global_atomic_associative(WIDTH, xor, i64, int64, 0)
global_atomic_uniform(WIDTH, add, i64, int64)
global_atomic_uniform(WIDTH, sub, i64, int64)
global_atomic_uniform(WIDTH, and, i64, int64)
global_atomic_uniform(WIDTH, or, i64, int64)
global_atomic_uniform(WIDTH, xor, i64, int64)
global_atomic_uniform(WIDTH, min, i64, int64)
global_atomic_uniform(WIDTH, max, i64, int64)
global_atomic_uniform(WIDTH, umin, i64, uint64)
global_atomic_uniform(WIDTH, umax, i64, uint64)

global_atomic_associative_fp(WIDTH, fadd, double, double)
global_atomic_associative_fp(WIDTH, fsub, double, double)
global_atomic_uniform(WIDTH, fadd, double, double)
global_atomic_uniform(WIDTH, fsub, double, double)
global_atomic_uniform(WIDTH, fmin, double, double)
global_atomic_uniform(WIDTH, fmax, double, double)

global_atomic_exchange(WIDTH, i32, int32)
global_atomic_exchange(WIDTH, i64, int64)

define <WIDTH x float> @__atomic_compare_exchange_float_global(i8 * %ptr,
                      <WIDTH x float> %cmp, <WIDTH x float> %val, <WIDTH x MASK> %mask) nounwind alwaysinline {
  %icmp = bitcast <WIDTH x float> %cmp to <WIDTH x i32>
  %ival = bitcast <WIDTH x float> %val to <WIDTH x i32>
  %iret = call <WIDTH x i32> @__atomic_compare_exchange_int32_global(i8 * %ptr, <WIDTH x i32> %icmp,
                                                                  <WIDTH x i32> %ival, <WIDTH x MASK> %mask)
  %ret = bitcast <WIDTH x i32> %iret to <WIDTH x float>
  ret <WIDTH x float> %ret
}

define <WIDTH x double> @__atomic_compare_exchange_double_global(i8 * %ptr,
                      <WIDTH x double> %cmp, <WIDTH x double> %val, <WIDTH x MASK> %mask) nounwind alwaysinline {
  %icmp = bitcast <WIDTH x double> %cmp to <WIDTH x i64>
  %ival = bitcast <WIDTH x double> %val to <WIDTH x i64>
  %iret = call <WIDTH x i64> @__atomic_compare_exchange_int64_global(i8 * %ptr, <WIDTH x i64> %icmp,
                                                                  <WIDTH x i64> %ival, <WIDTH x MASK> %mask)
  %ret = bitcast <WIDTH x i64> %iret to <WIDTH x double>
  ret <WIDTH x double> %ret
}

define float @__atomic_compare_exchange_uniform_float_global(i8 * %ptr, float %cmp,
                                                             float %val) nounwind alwaysinline {
  %icmp = bitcast float %cmp to i32
  %ival = bitcast float %val to i32
  %iret = call i32 @__atomic_compare_exchange_uniform_int32_global(i8 * %ptr, i32 %icmp,
                                                                   i32 %ival)
  %ret = bitcast i32 %iret to float
  ret float %ret
}

define double @__atomic_compare_exchange_uniform_double_global(i8 * %ptr, double %cmp,
                                                               double %val) nounwind alwaysinline {
  %icmp = bitcast double %cmp to i64
  %ival = bitcast double %val to i64
  %iret = call i64 @__atomic_compare_exchange_uniform_int64_global(i8 * %ptr, i64 %icmp, i64 %ival)
  %ret = bitcast i64 %iret to double
  ret double %ret
}

')

;; this is the function that target .ll files should call; it just takes the target
;; vector width as a parameter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; fast math, FTZ/DAZ functions
define(`fastMathFTZDAZ_x86', `
declare void @llvm.x86.sse.stmxcsr(i8 *) nounwind
declare void @llvm.x86.sse.ldmxcsr(i8 *) nounwind

define void @__fastmath() nounwind alwaysinline {
  %ptr = alloca i32
  %ptr8 = bitcast i32 * %ptr to i8 *
  call void @llvm.x86.sse.stmxcsr(i8 * %ptr8)
  %oldval = load PTR_OP_ARGS(`i32 ') %ptr

  ; turn on DAZ (64)/FTZ (32768) -> 32832
  %update = or i32 %oldval, 32832
  store i32 %update, i32 *%ptr
  call void @llvm.x86.sse.ldmxcsr(i8 * %ptr8)
  ret void
}

define i32 @__set_ftz_daz_flags() nounwind alwaysinline {
  %ptr = alloca i32
  %ptr8 = bitcast i32 * %ptr to i8 *
  call void @llvm.x86.sse.stmxcsr(i8 * %ptr8)
  %oldval = load PTR_OP_ARGS(`i32 ') %ptr

  ; turn on DAZ (64)/FTZ (32768) -> 32832
  %update = or i32 %oldval, 32832
  store i32 %update, i32 *%ptr
  call void @llvm.x86.sse.ldmxcsr(i8 * %ptr8)
  ret i32 %oldval
}

define void @__restore_ftz_daz_flags(i32 %oldVal) nounwind alwaysinline {
  ; restore value to previously saved
  %ptr = alloca i32
  %ptr8 = bitcast i32 * %ptr to i8 *
  store i32 %oldVal, i32 *%ptr
  call void @llvm.x86.sse.ldmxcsr(i8 * %ptr8)
  ret void
}
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; per_lane
;;
;; The scary macro below encapsulates the 'scalarization' idiom--i.e. we have
;; some operation that we'd like to perform only for the lanes where the
;; mask is on
;; $1: vector width of the target
;; $2: variable that holds the mask
;; $3: block of code to run for each lane that is on
;;       Inside this code, any instances of the text "LANE" are replaced
;;       with an i32 value that represents the current lane number

; num lanes, mask, code block to do per lane
define(`per_lane', `
  br label %pl_entry

pl_entry:
  %pl_mask = call i64 @__movmsk($2)
  %pl_mask_known = call i1 @__is_compile_time_constant_mask($2)
  br i1 %pl_mask_known, label %pl_known_mask, label %pl_unknown_mask

pl_known_mask:
  ;; the mask is known at compile time; see if it is something we can
  ;; handle more efficiently
  %pl_is_allon = icmp eq i64 %pl_mask, ALL_ON_MASK
  br i1 %pl_is_allon, label %pl_all_on, label %pl_unknown_mask

pl_all_on:
  ;; the mask is all on--just expand the code for each lane sequentially
  forloop(i, 0, eval($1-1),
          `patsubst(`$3', `LANE', i)')
  br label %pl_done

pl_unknown_mask:
  ;; we just run the general case, though we could
  ;; try to be smart and just emit the code based on what it actually is,
  ;; for example by emitting the code straight-line without a loop and doing
  ;; the lane tests explicitly, leaving later optimization passes to eliminate
  ;; the stuff that is definitely not needed.  Not clear if we will frequently
  ;; encounter a mask that is known at compile-time but is not either all on or
  ;; all off...
  br label %pl_loop

pl_loop:
  ;; Loop over each lane and see if we want to do the work for this lane
  %pl_lane = phi i32 [ 0, %pl_unknown_mask ], [ %pl_nextlane, %pl_loopend ]
  %pl_lanemask = phi i64 [ 1, %pl_unknown_mask ], [ %pl_nextlanemask, %pl_loopend ]

  ; is the current lane on?  if so, goto do work, otherwise to end of loop
  %pl_and = and i64 %pl_mask, %pl_lanemask
  %pl_doit = icmp eq i64 %pl_and, %pl_lanemask
  br i1 %pl_doit, label %pl_dolane, label %pl_loopend

pl_dolane:
  ;; If so, substitute in the code from the caller and replace the LANE
  ;; stuff with the current lane number
  patsubst(`patsubst(`$3', `LANE_ID', `_id')', `LANE', `%pl_lane')
  br label %pl_loopend

pl_loopend:
  %pl_nextlane = add i32 %pl_lane, 1
  %pl_nextlanemask = mul i64 %pl_lanemask, 2

  ; are we done yet?
  %pl_test = icmp ne i32 %pl_nextlane, $1
  br i1 %pl_test, label %pl_loop, label %pl_done

pl_done:
')

define(`rdrand_definition', `
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rdrand

declare {i16, i32} @llvm.x86.rdrand.16()
declare {i32, i32} @llvm.x86.rdrand.32()
declare {i64, i32} @llvm.x86.rdrand.64()

define i1 @__rdrand_i16(i8 * %ptr) {
  %ptr_typed = bitcast i8* %ptr to i16*
  %v = call {i16, i32} @llvm.x86.rdrand.16()
  %v0 = extractvalue {i16, i32} %v, 0
  %v1 = extractvalue {i16, i32} %v, 1
  store i16 %v0, i16 * %ptr_typed
  %good = icmp ne i32 %v1, 0
  ret i1 %good
}

define i1 @__rdrand_i32(i8 * %ptr) {
  %ptr_typed = bitcast i8* %ptr to i32*
  %v = call {i32, i32} @llvm.x86.rdrand.32()
  %v0 = extractvalue {i32, i32} %v, 0
  %v1 = extractvalue {i32, i32} %v, 1
  store i32 %v0, i32 * %ptr_typed
  %good = icmp ne i32 %v1, 0
  ret i1 %good
}

define i1 @__rdrand_i64(i8 * %ptr) {
  %ptr_typed = bitcast i8* %ptr to i64*
  %v = call {i64, i32} @llvm.x86.rdrand.64()
  %v0 = extractvalue {i64, i32} %v, 0
  %v1 = extractvalue {i64, i32} %v, 1
  store i64 %v0, i64 * %ptr_typed
  %good = icmp ne i32 %v1, 0
  ret i1 %good
}
')
;; end of included util.m4

stdlib_core()
rdrand_definition()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; fast math mode
fastMathFTZDAZ_x86()

;; end of included target-avx512-utils.ll

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; svml

include(`svml.m4')
svml(ISA)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stub for mask conversion.

define i64 @__cast_mask_to_i64 (<WIDTH x MASK> %mask) alwaysinline {
  %mask_iWIDTH = bitcast <WIDTH x i1> %mask to i`'WIDTH
  %mask_i64 = zext i`'WIDTH %mask_iWIDTH to i64
  ret i64 %mask_i64
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; reductions

declare i64 @__movmsk(<WIDTH x MASK> %mask) nounwind readnone alwaysinline
declare i1 @__any(<WIDTH x MASK> %mask) nounwind readnone alwaysinline
declare i1 @__all(<WIDTH x MASK> %mask) nounwind readnone alwaysinline
declare i1 @__none(<WIDTH x MASK> %mask) nounwind readnone alwaysinline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; unaligned loads/loads+broadcasts

declare void @__masked_store_blend_i8(<4 x i8>* nocapture, <4 x i8>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_i16(<4 x i16>* nocapture, <4 x i16>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_half(<4 x half>* nocapture, <4 x half>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_i32(<4 x i32>* nocapture, <4 x i32>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_float(<4 x float>* nocapture, <4 x float>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_i64(<4 x i64>* nocapture, <4 x i64>, <WIDTH x MASK>) nounwind alwaysinline
declare void @__masked_store_blend_double(<4 x double>* nocapture, <4 x double>, <WIDTH x MASK>) nounwind alwaysinline

;; Trigonometry
;; end of included target-avx512-common-4.ll
