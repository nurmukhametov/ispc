/*
  Copyright (c) 2024, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#include "ScalarizeHalfMemOps.h"

#include <llvm/IR/IRBuilder.h>

namespace ispc {

bool lIsSecondHalfAllFalse(llvm::Value *mask) {
    if (auto *CV = llvm::dyn_cast<llvm::ConstantVector>(mask)) {
        auto N = CV->getType()->getNumElements();
        for (auto i = N / 2; i < N; i++) {
            llvm::Constant *E = CV->getAggregateElement(i);
            if (!E || !llvm::isa<llvm::ConstantInt>(E) || !llvm::cast<llvm::ConstantInt>(E)->isZero()) {
                // found non-zero element
                return false;
            }
        }
        return true;
    }
    return false;
}

// This function replaces, e.g.,
//
// call void @llvm.masked.store.v8f32.p0(<8 x float> %value, ptr %ptr, i32 1,
//                          <8 x i1> <i1 true, i1 true, i1 true, i1 true, i1 false, i1 false, i1 false, i1 false>)
//
// with
//
//  %value.1 = extractelement <8 x float> %value, i64 0
//  %value.2 = extractelement <8 x float> %value, i64 1
//  %value.3 = extractelement <8 x float> %value, i64 2
//  %value.4 = extractelement <8 x float> %value, i64 3
//  %ptr.0 = getelementptr inbounds float, float* %ptr, i64 0
//  %ptr.1 = getelementptr inbounds float, float* %ptr, i64 1
//  %ptr.2 = getelementptr inbounds float, float* %ptr, i64 2
//  %ptr.3 = getelementptr inbounds float, float* %ptr, i64 3
//  store float %value.1, float* %ptr.0
//  store float %value.2, float* %ptr.1
//  store float %value.3, float* %ptr.2
//  store float %value.4, float* %ptr.3
//
void lScalarizeMaskedStore(llvm::IRBuilder<> &B, llvm::CallInst *CI) {
    llvm::Value *vec = CI->getOperand(0);
    llvm::Value *ptr = CI->getOperand(1);
    llvm::ConstantVector *CV = llvm::dyn_cast<llvm::ConstantVector>(CI->getOperand(3));
    assert(CV);

    auto *vecType = llvm::cast<llvm::VectorType>(vec->getType());
    unsigned N = vecType->getElementCount().getKnownMinValue();

    B.SetInsertPoint(CI);
    // TODO! name properly
    for (unsigned i = 0; i < N; i++) {
        if (CV->getAggregateElement(i)->isZeroValue()) {
            continue;
        }
        llvm::Value *value = B.CreateExtractElement(vec, i);
        std::vector<llvm::Value *> indices;
        indices.push_back(B.getInt64(i));
        llvm::Value *newPtr = B.CreateGEP(value->getType(), ptr, indices);
        llvm::Value *store = B.CreateStore(value, newPtr);
        LLVMCopyMetadata(store, CI);
    }

    CI->eraseFromParent();
}

// This function replaces, e.g.,
//
// %6 = call <8 x float> @llvm.masked.load.v8f32.p0(ptr %ptr, i32 1,
//      <8 x i1> <i1 true, i1 true, i1 true, i1 true, i1 false, i1 false, i1 false, i1 false>,
//      <8 x float> <float poison, float poison, float poison, float poison, float 0, float 0, float 0, float 0>)
//
// with
//
//  %ptr.0 = getelementptr inbounds float, float* %A, i64 0
//  %ptr.1 = getelementptr inbounds float, float* %A, i64 1
//  %ptr.2 = getelementptr inbounds float, float* %A, i64 2
//  %ptr.3 = getelementptr inbounds float, float* %A, i64 3
//  %v.0 = load float, float* %ptr.0, align 1
//  %v.1 = load float, float* %ptr.1, align 1
//  %v.2 = load float, float* %ptr.2, align 1
//  %v.3 = load float, float* %ptr.3, align 1
//  %vec_0 = insertelement <8 x float> <float poison, float poison, float poison, float poison, float 0, float 0, float 0, float 0>, float %v.0, i64 0
//  %vec_1 = insertelement <8 x float> %vec_0, float %v.1, i64 1
//  %vec_2 = insertelement <8 x float> %vec_1, float %v.2, i64 2
//  %vec_3 = insertelement <8 x float> %vec_2, float %v.3, i64 3
//
void lScalarizeMaskedLoad(llvm::IRBuilder<> &B, llvm::CallInst *CI) {
    llvm::Value *ptr = CI->getOperand(0);
    llvm::Value *passthrough = CI->getOperand(3);
    llvm::ConstantVector *CV = llvm::dyn_cast<llvm::ConstantVector>(CI->getOperand(2));
    assert(CV);

    B.SetInsertPoint(CI);

    auto *vecType = llvm::cast<llvm::VectorType>(passthrough->getType());
    unsigned N = vecType->getElementCount().getKnownMinValue();
    llvm::Type *elemType = vecType->getElementType();

    llvm::Value *replacement = passthrough;
    for (unsigned i = 0; i < N / 2; i++) {
        if (CV->getAggregateElement(i)->isZeroValue()) {
            continue;
        }
        std::vector<llvm::Value *> indices;
        indices.push_back(B.getInt64(i));
        llvm::Value *newPtr = B.CreateGEP(elemType, ptr, indices);
        llvm::Value *newElem = B.CreateLoad(elemType, newPtr);
        replacement = B.CreateInsertElement(replacement, newElem, i);
    }

    LLVMCopyMetadata(replacement, CI);
    CI->replaceAllUsesWith(replacement);
    CI->eraseFromParent();
}

llvm::PreservedAnalyses ScalarizeHalfMemOpsPass::run(llvm::Function &F, llvm::FunctionAnalysisManager &FAM) {
    // TODO! remove f
    if (F.empty()) {
      return llvm::PreservedAnalyses::all();
    }

    llvm::IRBuilder<> builder(F.getParent()->getContext());
    std::vector<llvm::CallInst *> storesToReplace;
    std::vector<llvm::CallInst *> loadsToReplace;
    for (auto &BB : F) {
        for (auto &I : BB) {
            auto *CI = llvm::dyn_cast<llvm::CallInst>(&I);
            if (!CI) {
                continue;
            }

            llvm::Function *CF = CI->getCalledFunction();
            if (!(CF && CF->isIntrinsic())) {
                continue;
            }


            if (CF->getIntrinsicID() == llvm::Intrinsic::masked_store) {
                llvm::Value *mask = CI->getOperand(3);
                if (lIsSecondHalfAllFalse(mask)) {
                    // TODO! sane debug output
                    // TODO! remarks
                    // printf("SHRINK masked.store %s\n", f->getName().str().c_str());
                    storesToReplace.push_back(CI);
                }
            }

            if (CF->getIntrinsicID() == llvm::Intrinsic::masked_load) {
                llvm::Value *mask = CI->getOperand(2);
                if (lIsSecondHalfAllFalse(mask)) {
                    // printf("SHRINK masked.load %s\n", f->getName().str().c_str());
                    loadsToReplace.push_back(CI);
                }
            }
        }
    }

    for (auto CI : storesToReplace) {
        lScalarizeMaskedStore(builder, CI);
    }

    for (auto CI : loadsToReplace) {
        lScalarizeMaskedLoad(builder, CI);
    }

    llvm::PreservedAnalyses PA;
    PA.preserveSet<llvm::CFGAnalyses>();
    return PA;
}

} // namespace ispc
