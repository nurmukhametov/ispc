;;  copyright (c) 2016-2024, intel corporation
;;
;;  SPDX-License-Identifier: BSD-3-Clause

define(`WIDTH',`4')
define(`ISA',`AVX512SKX')
define(`MASK',`i1')

define(`PTR_OP_ARGS',
    `$1 , $1 *'
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; stdlib_core
;;
;; This macro defines a bunch of helper routines that depend on the
;; target's vector width

define(`stdlib_core', `

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

')

stdlib_core()

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

