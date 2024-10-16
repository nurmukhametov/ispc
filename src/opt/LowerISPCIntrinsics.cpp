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

static llvm::Value *lLowerBitcastIntrinsic(llvm::CallInst *CI) {
    llvm::IRBuilder<> builder(CI);

    llvm::Value *V = CI->getArgOperand(0);
    llvm::Value *VT = CI->getArgOperand(1);

    return builder.CreateBitCast(V, VT->getType());
}

static llvm::MDNode *lNonTemporalMetadata(llvm::LLVMContext &ctx) {
    return llvm::MDNode::get(ctx,
                             llvm::ConstantAsMetadata::get(llvm::ConstantInt::get(llvm::Type::getInt32Ty(ctx), 1)));
}

static llvm::Value *lLowerStreamStoreIntrinsic(llvm::CallInst *CI) {
    // generate store with !nontemporal metadata attached
    llvm::IRBuilder<> builder(CI);

    llvm::Value *P = CI->getArgOperand(0);
    llvm::Value *V = CI->getArgOperand(1);

    llvm::StoreInst *SI = builder.CreateStore(V, P);
    SI->setMetadata("nontemporal", lNonTemporalMetadata(CI->getContext()));

    return SI;
}

static llvm::Value *lLowerStreamLoadIntrinsic(llvm::CallInst *CI) {
    // generate load with !nontemporal metadata attached
    llvm::IRBuilder<> builder(CI);

    llvm::Value *P = CI->getArgOperand(0);
    llvm::Type *T = CI->getArgOperand(1)->getType();

    llvm::LoadInst *LI = builder.CreateLoad(T, P);
    LI->setMetadata("nontemporal", lNonTemporalMetadata(CI->getContext()));

    return LI;
}

static llvm::Value *lLowerAtomicRMWIntrinsic(llvm::CallInst *CI) {
    // generate atomicrmw instruction with the first operand fetched from
    // instrinsic name suffix (that is placed before type overloading suffix)
    llvm::IRBuilder<> builder(CI);

    llvm::Value *P = CI->getArgOperand(0);
    llvm::Value *V = CI->getArgOperand(1);

    llvm::AtomicRMWInst::BinOp op = llvm::AtomicRMWInst::BinOp::BAD_BINOP;
    llvm::AtomicOrdering ordering = llvm::AtomicOrdering::NotAtomic;

    // llvm.ispc.atomicrmw.<op>.<memoryOrdering>.<type>
    std::string opName = CI->getCalledFunction()->getName().str();
    opName = opName.substr(0, opName.find_last_of('.'));
    std::string memoryOrdering = opName.substr(opName.find_last_of('.') + 1);
    opName = opName.substr(0, opName.find_last_of('.'));
    opName = opName.substr(opName.find_last_of('.') + 1);
    printf("opName: %s\n", opName.c_str());
    printf("memoryOrdering: %s\n", memoryOrdering.c_str());
    if (opName == "xchg") {
        op = llvm::AtomicRMWInst::BinOp::Xchg;
    } else if (opName == "add") {
        op = llvm::AtomicRMWInst::BinOp::Add;
    } else if (opName == "sub") {
        op = llvm::AtomicRMWInst::BinOp::Sub;
    } else if (opName == "and") {
        op = llvm::AtomicRMWInst::BinOp::And;
    } else if (opName == "nand") {
        op = llvm::AtomicRMWInst::BinOp::Nand;
    } else if (opName == "or") {
        op = llvm::AtomicRMWInst::BinOp::Or;
    } else if (opName == "xor") {
        op = llvm::AtomicRMWInst::BinOp::Xor;
    } else if (opName == "max") {
        op = llvm::AtomicRMWInst::BinOp::Max;
    } else if (opName == "min") {
        op = llvm::AtomicRMWInst::BinOp::Min;
    } else if (opName == "umax") {
        op = llvm::AtomicRMWInst::BinOp::UMax;
    } else if (opName == "umin") {
        op = llvm::AtomicRMWInst::BinOp::UMin;
    }
    Assert(op != llvm::AtomicRMWInst::BinOp::BAD_BINOP);

    if (memoryOrdering == "unordered") {
        ordering = llvm::AtomicOrdering::Unordered;
    } else if (memoryOrdering == "monotonic") {
        ordering = llvm::AtomicOrdering::Monotonic;
    } else if (memoryOrdering == "acquire") {
        ordering = llvm::AtomicOrdering::Acquire;
    } else if (memoryOrdering == "release") {
        ordering = llvm::AtomicOrdering::Release;
    } else if (memoryOrdering == "acq_rel") {
        ordering = llvm::AtomicOrdering::AcquireRelease;
    } else if (memoryOrdering == "seq_cst") {
        ordering = llvm::AtomicOrdering::SequentiallyConsistent;
    }
    Assert(ordering != llvm::AtomicOrdering::NotAtomic);

    return builder.CreateAtomicRMW(op, P, V, llvm::MaybeAlign(), ordering);
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
                } else if (Callee->getName().startswith("llvm.ispc.bitcast.")) {
                    D = lLowerBitcastIntrinsic(CI);
                } else if (Callee->getName().startswith("llvm.ispc.stream_store.")) {
                    D = lLowerStreamStoreIntrinsic(CI);
                } else if (Callee->getName().startswith("llvm.ispc.stream_load.")) {
                    D = lLowerStreamLoadIntrinsic(CI);
                } else if (Callee->getName().startswith("llvm.ispc.atomicrmw.")) {
                    D = lLowerAtomicRMWIntrinsic(CI);
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
