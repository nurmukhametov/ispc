/*
  Copyright (c) 2019-2023, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

/** @file bitcode_lib.h
    @brief a header to host BitcodeLib - a wrapper for single bitcode library.
*/

#pragma once

#include "target_enums.h"

#include <llvm/IR/Module.h>
#include "llvm/Support/MemoryBuffer.h"

namespace ispc {

class BitcodeLib {
  public:
    enum class BitcodeLibType { Dispatch, Builtins_c, ISPC_target, Dispatch_BC, Builtins_c_BC, ISPC_target_BC };

  private:
    // Type of library
    BitcodeLibType m_type;

    // The code and its size
    const unsigned char *m_lib;
    const size_t m_size;

    // Identification of the library: OS, Arch, ISPCTarget
    const TargetOS m_os;
    const Arch m_arch;
    const ISPCTarget m_target;

    const std::string m_bc_filename;

  public:
    // Dispatch constructor
    BitcodeLib(const unsigned char lib[], int size, TargetOS os);
    // Builtins-c constructor
    BitcodeLib(const unsigned char lib[], int size, TargetOS os, Arch arch);
    // ISPC-target constructor
    BitcodeLib(const unsigned char lib[], int size, ISPCTarget target, TargetOS os, Arch arch);
    // ISPC-target constructor containing BC files.
    BitcodeLib(std::string &bc_filename, ISPCTarget target, TargetOS os, Arch arch);
    void print() const;

    BitcodeLibType getType() const;
    const unsigned char *getLib() const;
    size_t getSize() const;
    TargetOS getOS() const;
    Arch getArch() const;
    ISPCTarget getISPCTarget() const;
    llvm::Module *getLLVMModule() const;
};

} // namespace ispc
