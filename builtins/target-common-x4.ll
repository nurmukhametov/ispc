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

