/*
  Copyright (c) 2023, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#include "LazyLinkTargetBuiltins.h"

namespace ispc {

bool LazyLinkTargetBuiltins::process(llvm::BasicBlock &BB) {
    bool added = false;

    for (llvm::Instruction &II : BB) {
        if (llvm::isa<llvm::CallInst>(&II)) {
            llvm::CallInst *call = llvm::dyn_cast<llvm::CallInst>(&II);
            const char *funcName = call->getCalledFunction()->getName().data();
            // llvm::errs() << "  call to " << funcName << "\n";
            if (!m->InsertAndGetFunction(funcName)) {
                llvm::errs() << "LazyLinkTargetBuiltins ERROR: no function " << funcName << "\n";
            }
        }
    }

    return added;
}

llvm::PreservedAnalyses LazyLinkTargetBuiltins::run(llvm::Function &F, llvm::FunctionAnalysisManager &FAM) {

    llvm::TimeTraceScope FuncScope("LazyLinkTargetBuiltins::run", F.getName());
    bool addedAny = false;
    for (llvm::BasicBlock &BB : F) {
        // llvm::errs() << "Traverse: " << F.getName() << "\n";
        addedAny |= process(BB);
    }
    // if (!addedAny) {
    //     // No changes, all analyses are preserved.
    //     return llvm::PreservedAnalyses::all();
    // }

    // TODO! recalculate only Call graph
    return llvm::PreservedAnalyses::none();
}

} // namespace ispc
