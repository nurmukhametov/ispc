/*
  Copyright (c) 2023, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#pragma once

#include "ISPCPass.h"

namespace ispc {

// LazyLinkTargetBuiltins

class LazyLinkTargetBuiltins : public llvm::PassInfoMixin<LazyLinkTargetBuiltins> {
  public:
    explicit LazyLinkTargetBuiltins(){};

    static llvm::StringRef getPassName() { return "Lazy Link Target Builtins Library"; }
    llvm::PreservedAnalyses run(llvm::Function &F, llvm::FunctionAnalysisManager &FAM);

  private:
    bool process(llvm::BasicBlock &BB);
};

} // namespace ispc

