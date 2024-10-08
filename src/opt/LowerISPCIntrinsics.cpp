/*
  Copyright (c) 2024, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#include "LowerISPCIntrinsics.h"

#include <llvm/IR/IRBuilder.h>
#include <llvm/Transforms/Utils/Local.h>

#include <numeric>

namespace ispc {

static llvm::Constant *lGetSequentialMask(llvm::IRBuilder<> &builder, unsigned N) {
    std::vector<unsigned> indices(N);
    std::iota(indices.begin(), indices.end(), 0);
    return llvm::ConstantDataVector::get(builder.getContext(), indices);
}

static unsigned lGetVecNumElements(llvm::Value *V) {
    auto *vecType = llvm::dyn_cast<llvm::VectorType>(V->getType());
    Assert(vecType);
    return vecType->getElementCount().getKnownMinValue();
}

static llvm::Value *lLowerConcatIntrinsic(llvm::CallInst *CI) {
    llvm::IRBuilder<> builder(CI);
    llvm::Value *V0 = CI->getArgOperand(0);
    llvm::Value *V1 = CI->getArgOperand(1);

    auto N = lGetVecNumElements(V0);
    return builder.CreateShuffleVector(V0, V1, lGetSequentialMask(builder, 2 * N));
}

static llvm::Value *lLowerExtractIntrinsic(llvm::CallInst *CI) {
    llvm::IRBuilder<> builder(CI);
    auto numArgs = CI->getNumOperands() - 1;

    if (numArgs == 2) {
        llvm::Value *V = CI->getArgOperand(0);
        llvm::Value *I = CI->getArgOperand(1);

        return builder.CreateExtractElement(V, I);
    }
    if (numArgs == 3) {
        llvm::Value *V0 = CI->getArgOperand(0);
        llvm::Value *V1 = CI->getArgOperand(1);
        llvm::Value *I = CI->getArgOperand(2);

        auto N = lGetVecNumElements(V0);
        llvm::Value *V = builder.CreateShuffleVector(V0, V1, lGetSequentialMask(builder, 2 * N));

        return builder.CreateExtractElement(V, I);
    }
    return nullptr;
}

static llvm::Value *lLowerInserIntrinsic(llvm::CallInst *CI) {
    llvm::IRBuilder<> builder(CI);

    llvm::Value *V = CI->getArgOperand(0);
    llvm::Value *I = CI->getArgOperand(1);
    llvm::Value *E = CI->getArgOperand(2);

    return builder.CreateInsertElement(V, E, I);
}

static bool lRunOnBasicBlock(llvm::BasicBlock &BB) {
    // TODO: add lit tests
    for (llvm::BasicBlock::iterator iter = BB.begin(), e = BB.end(); iter != e;) {
        if (llvm::CallInst *CI = llvm::dyn_cast<llvm::CallInst>(&*(iter++))) {
            llvm::Function *Callee = CI->getCalledFunction();
            if (Callee) {
                llvm::Value *D = nullptr;
                if (Callee->getName().startswith("llvm.ispc.concat.")) {
                    D = lLowerConcatIntrinsic(CI);
                } else if (Callee->getName().startswith("llvm.ispc.extract.")) {
                    D = lLowerExtractIntrinsic(CI);
                } else if (Callee->getName().startswith("llvm.ispc.insert.")) {
                    D = lLowerInserIntrinsic(CI);
                }

                if (D) {
                    CI->replaceAllUsesWith(D);
                    CI->eraseFromParent();
                }
            }
        }
    }
    return false;
}

llvm::PreservedAnalyses LowerISPCIntrinsicsPass::run(llvm::Function &F, llvm::FunctionAnalysisManager &FAM) {
    llvm::TimeTraceScope FuncScope("LowerISPCIntrinsicsPass::run", F.getName());
    bool modified = false;
    for (llvm::BasicBlock &BB : F) {
        modified |= lRunOnBasicBlock(BB);
    }

    if (modified) {
        llvm::PreservedAnalyses PA;
        PA.preserveSet<llvm::CFGAnalyses>();
        return PA;
    } else {
        return llvm::PreservedAnalyses::all();
    }
}

} // namespace ispc
