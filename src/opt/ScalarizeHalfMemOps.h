/*
  Copyright (c) 2024, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

#pragma once

#include "ISPCPass.h"

namespace ispc {

// This pass scalarizes half-width memory operations (masked.load/store) into
// the sequence of scalar loads/stores. This is needed for generation better
// code in cases when only half-width of registers are used.
// masked.load and masked.store intrinsics are directly mapped to machine
// instructions with the specified full width of vector values being
// loaded/stored.
// The sequence of scalar loads/stores has chance to be codegened into shorter
// vector loads/stores by backend.

class ScalarizeHalfMemOpsPass : public llvm::PassInfoMixin<ScalarizeHalfMemOpsPass> {
  public:
    explicit ScalarizeHalfMemOpsPass() {}

    static llvm::StringRef getPassName() { return "Scalarize half-width mem ops"; }
    llvm::PreservedAnalyses run(llvm::Function &F, llvm::FunctionAnalysisManager &FAM);
};

} // namespace ispc
