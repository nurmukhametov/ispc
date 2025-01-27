;;
;; target-neon-32.ll
;;
;;  Copyright(c) 2012-2013 Matt Pharr
;;  Copyright(c) 2013, 2015 Google, Inc.
;;  Copyright(c) 2019-2025 Intel
;;
;;  SPDX-License-Identifier: BSD-3-Clause

define(`WIDTH',`4')
define(`MASK',`i32')
define(`ISA',`NEON')


define(`NEON_PREFIX',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon',
        RUNTIME, `32', `llvm.arm.neon')')

define(`NEON_PREFIX_UDOT',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.udot',
        RUNTIME, `32', `llvm.arm.neon.udot')')

define(`NEON_PREFIX_SDOT',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.sdot',
        RUNTIME, `32', `llvm.arm.neon.sdot')')

define(`NEON_PREFIX_USDOT',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.usdot',
        RUNTIME, `32', `llvm.arm.neon.usdot')')

define(`NEON_PREFIX_RECPEQ',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.frecpe',
        RUNTIME, `32', `llvm.arm.neon.vrecpe')')

define(`NEON_PREFIX_RECPSQ',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.frecps',
        RUNTIME, `32', `llvm.arm.neon.vrecps')')

define(`NEON_PREFIX_RSQRTEQ',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.frsqrte',
        RUNTIME, `32', `llvm.arm.neon.vrsqrte')')

define(`NEON_PREFIX_RSQRTSQ',
`ifelse(RUNTIME, `64', `llvm.aarch64.neon.frsqrts',
        RUNTIME, `32', `llvm.arm.neon.vrsqrts')')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; math

ifelse(RUNTIME, `32',
`
  declare void @llvm.arm.set.fpscr(i32) nounwind
  declare i32 @llvm.arm.get.fpscr() nounwind

  define void @__fastmath() nounwind alwaysinline {
    %x = call i32 @llvm.arm.get.fpscr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i32 %x, 50331648
    call void @llvm.arm.set.fpscr(i32 %y)
    ret void
  }

  define i32 @__set_ftz_daz_flags() nounwind alwaysinline {
    %x = call i32 @llvm.arm.get.fpscr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i32 %x, 50331648
    call void @llvm.arm.set.fpscr(i32 %y)
    ret i32 %x
  }

  define void @__restore_ftz_daz_flags(i32 %oldVal) nounwind alwaysinline {
    ; restore value to previously saved
    call void @llvm.arm.set.fpscr(i32 %oldVal)
    ret void
  }
',
  RUNTIME, `64',
`
  declare void @llvm.aarch64.set.fpcr(i64) nounwind
  declare i64 @llvm.aarch64.get.fpcr() nounwind

  define void @__fastmath() nounwind alwaysinline {
    %x = call i64 @llvm.aarch64.get.fpcr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i64 %x, 50331648
    call void @llvm.aarch64.set.fpcr(i64 %y)
    ret void
  }

  define i64 @__set_ftz_daz_flags() nounwind alwaysinline {
    %x = call i64 @llvm.aarch64.get.fpcr()
    ; Turn on FTZ (bit 24) and default NaN (bit 25)
    %y = or i64 %x, 50331648
    call void @llvm.aarch64.set.fpcr(i64 %y)
    ret i64 %x
  }

  define void @__restore_ftz_daz_flags(i64 %oldVal) nounwind alwaysinline {
    ; restore value to previously saved
    call void @llvm.aarch64.set.fpcr(i64 %oldVal)
    ret void
  }
')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rsqrt/rcp

declare <4 x float> @NEON_PREFIX_RECPEQ.v4f32(<4 x float>) nounwind readnone
declare <4 x float> @NEON_PREFIX_RECPSQ.v4f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rcp_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %x0 = call <4 x float> @NEON_PREFIX_RECPEQ.v4f32(<4 x float> %d)
  %x0_nr = call <4 x float> @NEON_PREFIX_RECPSQ.v4f32(<4 x float> %d, <4 x float> %x0)
  %x1 = fmul <4 x float> %x0, %x0_nr
  %x1_nr = call <4 x float> @NEON_PREFIX_RECPSQ.v4f32(<4 x float> %d, <4 x float> %x1)
  %x2 = fmul <4 x float> %x1, %x1_nr
  ret <4 x float> %x2
}

define <WIDTH x float> @__rcp_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %ret = call <4 x float> @NEON_PREFIX_RECPEQ.v4f32(<4 x float> %d)
  ret <4 x float> %ret
}

declare <4 x float> @NEON_PREFIX_RSQRTEQ.v4f32(<4 x float>) nounwind readnone
declare <4 x float> @NEON_PREFIX_RSQRTSQ.v4f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rsqrt_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %x0 = call <4 x float> @NEON_PREFIX_RSQRTEQ.v4f32(<4 x float> %d)
  %x0_2 = fmul <4 x float> %x0, %x0
  %x0_nr = call <4 x float> @NEON_PREFIX_RSQRTSQ.v4f32(<4 x float> %d, <4 x float> %x0_2)
  %x1 = fmul <4 x float> %x0, %x0_nr
  %x1_2 = fmul <4 x float> %x1, %x1
  %x1_nr = call <4 x float> @NEON_PREFIX_RSQRTSQ.v4f32(<4 x float> %d, <4 x float> %x1_2)
  %x2 = fmul <4 x float> %x1, %x1_nr
  ret <4 x float> %x2
}

define float @__rsqrt_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <4 x i32> <i32 0, i32 undef, i32 undef, i32 undef>
  %vr = call <4 x float> @__rsqrt_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define <WIDTH x float> @__rsqrt_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  %ret = call <4 x float> @NEON_PREFIX_RSQRTEQ.v4f32(<4 x float> %d)
  ret <4 x float> %ret
}

define float @__rsqrt_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <4 x float> undef, float %0, i32 0
  %vr = call <4 x float> @__rsqrt_fast_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <4 x i32> <i32 0, i32 undef, i32 undef, i32 undef>
  %vr = call <4 x float> @__rcp_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <4 x float> undef, float %0, i32 0
  %vr = call <4 x float> @__rcp_fast_varying_float(<4 x float> %vs)
  %r = extractelement <4 x float> %vr, i32 0
  ret float %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; half conversion routines

declare <4 x i16> @NEON_PREFIX.vcvtfp2hf(<4 x float>) nounwind readnone
declare <4 x float> @NEON_PREFIX.vcvthf2fp(<4 x i16>) nounwind readnone

define float @__half_to_float_uniform(i16 %v) nounwind readnone alwaysinline {
  %v1 = bitcast i16 %v to <1 x i16>
  %vec = shufflevector <1 x i16> %v1, <1 x i16> undef, 
           <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  %h = call <4 x float> @NEON_PREFIX.vcvthf2fp(<4 x i16> %vec)
  %r = extractelement <4 x float> %h, i32 0
  ret float %r
}

define i16 @__float_to_half_uniform(float %v) nounwind readnone alwaysinline {
  %v1 = bitcast float %v to <1 x float>
  %vec = shufflevector <1 x float> %v1, <1 x float> undef, 
           <4 x i32> <i32 0, i32 0, i32 0, i32 0>
  %h = call <4 x i16> @NEON_PREFIX.vcvtfp2hf(<4 x float> %vec)
  %r = extractelement <4 x i16> %h, i32 0
  ret i16 %r
}

define <4 x float> @__half_to_float_varying(<4 x i16> %v) nounwind readnone alwaysinline {
  %r = call <4 x float> @NEON_PREFIX.vcvthf2fp(<4 x i16> %v)
  ret <4 x float> %r
}

define <4 x i16> @__float_to_half_varying(<4 x float> %v) nounwind readnone alwaysinline {
  %r = call <4 x i16> @NEON_PREFIX.vcvtfp2hf(<4 x float> %v)
  ret <4 x i16> %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dot product

declare <4 x i32> @NEON_PREFIX_UDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <4 x i32> @__dot4add_u8u8packed(<4 x i32> %a, <4 x i32> %b, <4 x i32> %acc) nounwind readnone alwaysinline {
  %a_cast = bitcast <4 x i32> %a to <16 x i8>
  %b_cast = bitcast <4 x i32> %b to <16 x i8>
  %ret = call <4 x i32> @NEON_PREFIX_UDOT.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a_cast, <16 x i8> %b_cast)
  ret <4 x i32> %ret
}

declare <4 x i32> @NEON_PREFIX_SDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <4 x i32> @__dot4add_i8i8packed(<4 x i32> %a, <4 x i32> %b, <4 x i32> %acc) nounwind readnone alwaysinline {
  %a_cast = bitcast <4 x i32> %a to <16 x i8>
  %b_cast = bitcast <4 x i32> %b to <16 x i8>
  %ret = call <4 x i32> @NEON_PREFIX_SDOT.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a_cast, <16 x i8> %b_cast)
  ret <4 x i32> %ret
}

declare <4 x i32> @NEON_PREFIX_USDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <4 x i32> @__dot4add_u8i8packed(<4 x i32> %a, <4 x i32> %b, <4 x i32> %acc) nounwind readnone alwaysinline {
  %a_cast = bitcast <4 x i32> %a to <16 x i8>
  %b_cast = bitcast <4 x i32> %b to <16 x i8>
  %ret = call <4 x i32> @NEON_PREFIX_USDOT.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a_cast, <16 x i8> %b_cast)
  ret <4 x i32> %ret
}
