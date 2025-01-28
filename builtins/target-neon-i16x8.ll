;;
;; target-neon-16.ll
;;
;;  Copyright(c) 2013-2015 Google, Inc.
;;  Copyright(c) 2019-2025 Intel
;;
;;  SPDX-License-Identifier: BSD-3-Clause

define(`WIDTH',`8')
define(`MASK',`i16')
define(`ISA',`NEON')

include(`util.m4')

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

;; rsqrt/rcp

declare <4 x float> @NEON_PREFIX_RECPEQ.v4f32(<4 x float>) nounwind readnone
declare <4 x float> @NEON_PREFIX_RECPSQ.v4f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rcp_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  unary4to8(x0, float, @NEON_PREFIX_RECPEQ.v4f32, %d)
  binary4to8(x0_nr, float, @NEON_PREFIX_RECPSQ.v4f32, %d, %x0)
  %x1 = fmul <WIDTH x float> %x0, %x0_nr
  binary4to8(x1_nr, float, @NEON_PREFIX_RECPSQ.v4f32, %d, %x1)
  %x2 = fmul <WIDTH x float> %x1, %x1_nr
  ret <WIDTH x float> %x2
}

define <WIDTH x float> @__rcp_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  unary4to8(x0, float, @NEON_PREFIX_RECPEQ.v4f32, %d)
  ret <WIDTH x float> %x0
}

declare <4 x float> @NEON_PREFIX_RSQRTEQ.v4f32(<4 x float>) nounwind readnone
declare <4 x float> @NEON_PREFIX_RSQRTSQ.v4f32(<4 x float>, <4 x float>) nounwind readnone

define <WIDTH x float> @__rsqrt_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  unary4to8(x0, float, @NEON_PREFIX_RSQRTEQ.v4f32, %d)
  %x0_2 = fmul <WIDTH x float> %x0, %x0
  binary4to8(x0_nr, float, @NEON_PREFIX_RSQRTSQ.v4f32, %d, %x0_2)
  %x1 = fmul <WIDTH x float> %x0, %x0_nr
  %x1_2 = fmul <WIDTH x float> %x1, %x1
  binary4to8(x1_nr, float, @NEON_PREFIX_RSQRTSQ.v4f32, %d, %x1_2)
  %x2 = fmul <WIDTH x float> %x1, %x1_nr
  ret <WIDTH x float> %x2
}

define <WIDTH x float> @__rsqrt_fast_varying_float(<WIDTH x float> %d) nounwind readnone alwaysinline {
  unary4to8(x0, float, @NEON_PREFIX_RSQRTEQ.v4f32, %d)
  ret <WIDTH x float> %x0
}

define float @__rsqrt_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <8 x float> undef, float %0, i32 0
  %vr = call <8 x float> @__rsqrt_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define float @__rsqrt_fast_uniform_float(float) nounwind readnone alwaysinline {
  %vs = insertelement <8 x float> undef, float %0, i32 0
  %vr = call <8 x float> @__rsqrt_fast_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <8 x i32> <i32 0, i32 undef, i32 undef, i32 undef,
                      i32 undef, i32 undef, i32 undef, i32 undef>
  %vr = call <8 x float> @__rcp_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
  ret float %r
}

define float @__rcp_fast_uniform_float(float) nounwind readnone alwaysinline {
  %v1 = bitcast float %0 to <1 x float>
  %vs = shufflevector <1 x float> %v1, <1 x float> undef,
          <8 x i32> <i32 0, i32 undef, i32 undef, i32 undef,
                      i32 undef, i32 undef, i32 undef, i32 undef>
  %vr = call <8 x float> @__rcp_fast_varying_float(<8 x float> %vs)
  %r = extractelement <8 x float> %vr, i32 0
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

define <8 x float> @__half_to_float_varying(<8 x i16> %v) nounwind readnone alwaysinline {
  unary4to8conv(r, i16, float, @NEON_PREFIX.vcvthf2fp, %v)
  ret <8 x float> %r
}

define <8 x i16> @__float_to_half_varying(<8 x float> %v) nounwind readnone alwaysinline {
  unary4to8conv(r, float, i16, @NEON_PREFIX.vcvtfp2hf, %v)
  ret <8 x i16> %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dot product

declare <4 x i32> @NEON_PREFIX_UDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <8 x i32> @__dot4add_u8u8packed(<8 x i32> %a, <8 x i32> %b, <8 x i32> %acc) nounwind readnone alwaysinline {
  v8tov4(i32, %a, %a0, %a1)
  v8tov4(i32, %b, %b0, %b1)
  v8tov4(i32, %acc, %acc0, %acc1)
  %a0_cast = bitcast <4 x i32> %a0 to <16 x i8>
  %b0_cast = bitcast <4 x i32> %b0 to <16 x i8>
  %a1_cast = bitcast <4 x i32> %a1 to <16 x i8>
  %b1_cast = bitcast <4 x i32> %b1 to <16 x i8>
  %ret0 = call <4 x i32> @NEON_PREFIX_UDOT.v4i32.v16i8(<4 x i32> %acc0, <16 x i8> %a0_cast, <16 x i8> %b0_cast)
  %ret1 = call <4 x i32> @NEON_PREFIX_UDOT.v4i32.v16i8(<4 x i32> %acc1, <16 x i8> %a1_cast, <16 x i8> %b1_cast)
  v4tov8(i32, %ret0, %ret1, %ret)
  ret <8 x i32> %ret
}

declare <4 x i32> @NEON_PREFIX_SDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <8 x i32> @__dot4add_i8i8packed(<8 x i32> %a, <8 x i32> %b, <8 x i32> %acc) nounwind readnone alwaysinline {
  v8tov4(i32, %a, %a0, %a1)
  v8tov4(i32, %b, %b0, %b1)
  v8tov4(i32, %acc, %acc0, %acc1)
  %a0_cast = bitcast <4 x i32> %a0 to <16 x i8>
  %b0_cast = bitcast <4 x i32> %b0 to <16 x i8>
  %a1_cast = bitcast <4 x i32> %a1 to <16 x i8>
  %b1_cast = bitcast <4 x i32> %b1 to <16 x i8>
  %ret0 = call <4 x i32> @NEON_PREFIX_SDOT.v4i32.v16i8(<4 x i32> %acc0, <16 x i8> %a0_cast, <16 x i8> %b0_cast)
  %ret1 = call <4 x i32> @NEON_PREFIX_SDOT.v4i32.v16i8(<4 x i32> %acc1, <16 x i8> %a1_cast, <16 x i8> %b1_cast)
  v4tov8(i32, %ret0, %ret1, %ret)
  ret <8 x i32> %ret
}

declare <4 x i32> @NEON_PREFIX_USDOT.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>) nounwind readnone
define <8 x i32> @__dot4add_u8i8packed(<8 x i32> %a, <8 x i32> %b, <8 x i32> %acc) nounwind readnone alwaysinline {
  v8tov4(i32, %a, %a0, %a1)
  v8tov4(i32, %b, %b0, %b1)
  v8tov4(i32, %acc, %acc0, %acc1)
  %a0_cast = bitcast <4 x i32> %a0 to <16 x i8>
  %b0_cast = bitcast <4 x i32> %b0 to <16 x i8>
  %a1_cast = bitcast <4 x i32> %a1 to <16 x i8>
  %b1_cast = bitcast <4 x i32> %b1 to <16 x i8>
  %ret0 = call <4 x i32> @NEON_PREFIX_USDOT.v4i32.v16i8(<4 x i32> %acc0, <16 x i8> %a0_cast, <16 x i8> %b0_cast)
  %ret1 = call <4 x i32> @NEON_PREFIX_USDOT.v4i32.v16i8(<4 x i32> %acc1, <16 x i8> %a1_cast, <16 x i8> %b1_cast)
  v4tov8(i32, %ret0, %ret1, %ret)
  ret <8 x i32> %ret
}
