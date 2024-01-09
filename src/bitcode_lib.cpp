/*
  Copyright (c) 2019-2023, Intel Corporation

  SPDX-License-Identifier: BSD-3-Clause
*/

/** @file bitcode_lib.cpp
    @brief BitcodeLib represents single bitcode library file (either dispatch,
           Builtiins-c, or ISPCTarget).
*/

#include "bitcode_lib.h"
#include "target_registry.h"
#include "ispc.h"

#include <llvm/Bitcode/BitcodeReader.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Path.h>

using namespace ispc;

// Dispatch constructor
BitcodeLib::BitcodeLib(const unsigned char lib[], int size, TargetOS os)
    : m_type(BitcodeLibType::Dispatch), m_lib(lib), m_size(size), m_os(os), m_arch(Arch::none),
      m_target(ISPCTarget::none) {
    TargetLibRegistry::RegisterTarget(this);
}
// Builtins-c constructor
BitcodeLib::BitcodeLib(const unsigned char lib[], int size, TargetOS os, Arch arch)
    : m_type(BitcodeLibType::Builtins_c), m_lib(lib), m_size(size), m_os(os), m_arch(arch), m_target(ISPCTarget::none) {
    TargetLibRegistry::RegisterTarget(this);
}
// ISPC-target constructor
BitcodeLib::BitcodeLib(const unsigned char lib[], int size, ISPCTarget target, TargetOS os, Arch arch)
    : m_type(BitcodeLibType::ISPC_target), m_lib(lib), m_size(size), m_os(os), m_arch(arch), m_target(target) {
    TargetLibRegistry::RegisterTarget(this);
}
// ISPC-target constructor containing BC files.
BitcodeLib::BitcodeLib(std::string &bc_filename, ISPCTarget target, TargetOS os, Arch arch)
    : m_type(BitcodeLibType::ISPC_target_BC), m_lib(nullptr), m_size(0), m_os(os), m_arch(arch), m_target(target), m_bc_filename(bc_filename) { }

// TODO: this is debug version: either remove or make it use friendly.
void BitcodeLib::print() const {
    std::string os = OSToString(m_os);
    switch (m_type) {
    case BitcodeLibType::Dispatch: {
        printf("Type: dispatch.    size: %zu, OS: %s\n", m_size, os.c_str());
        break;
    }
    case BitcodeLibType::Builtins_c: {
        std::string arch = ArchToString(m_arch);
        printf("Type: builtins-c.  size: %zu, OS: %s, arch: %s\n", m_size, os.c_str(), arch.c_str());
        break;
    }
    case BitcodeLibType::ISPC_target: {
        std::string target = ISPCTargetToString(m_target);
        std::string arch = ArchToString(m_arch);
        printf("Type: ispc-target. size: %zu, OS: %s, target: %s, arch(runtime) %s\n", m_size, os.c_str(),
               target.c_str(), arch.c_str());
        break;
    }
    case BitcodeLibType::ISPC_target_BC: {
        std::string target = ISPCTargetToString(m_target);
        std::string arch = ArchToString(m_arch);
        printf("Type: ispc-target-bc. OS: %s, target: %s, arch(runtime) %s, filename: %s\n", os.c_str(),
               target.c_str(), arch.c_str(), m_bc_filename.c_str());
        break;
    }
    }
}

BitcodeLib::BitcodeLibType BitcodeLib::getType() const { return m_type; }
const unsigned char *BitcodeLib::getLib() const { return m_lib; }
size_t BitcodeLib::getSize() const { return m_size; }
TargetOS BitcodeLib::getOS() const { return m_os; }
Arch BitcodeLib::getArch() const { return m_arch; }
ISPCTarget BitcodeLib::getISPCTarget() const { return m_target; }

llvm::Module *BitcodeLib::getLLVMModule() const {
    switch (m_type) {
    case BitcodeLibType::Dispatch:
    case BitcodeLibType::Builtins_c:
    case BitcodeLibType::ISPC_target: {
        llvm::StringRef sb = llvm::StringRef((const char *) m_lib, m_size);
        llvm::MemoryBufferRef bcBuf = llvm::MemoryBuffer::getMemBuffer(sb)->getMemBufferRef();

        llvm::Expected<std::unique_ptr<llvm::Module>> ModuleOrErr = llvm::parseBitcodeFile(bcBuf, *g->ctx);
        if (!ModuleOrErr) {
            fprintf(stderr, "ERROR parsing bc_filename %s\n", m_bc_filename.c_str());
        } else {
            llvm::Module *M = ModuleOrErr.get().release();
            return M;
        }
    }
    case BitcodeLibType::ISPC_target_BC: {
        llvm::SmallString<128> filePath(g->shareDirPath);
        llvm::sys::path::append(filePath, m_bc_filename);
        llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> bufferOrErr = llvm::MemoryBuffer::getFile(filePath.str());
        if (std::error_code EC = bufferOrErr.getError()) {
            fprintf(stderr, "ERROR reading bc_filename %s\n", m_bc_filename.c_str());
            fprintf(stderr, "%s\n", EC.message().c_str());
        }
        llvm::Expected<std::unique_ptr<llvm::Module>> ModuleOrErr =
                                            llvm::parseBitcodeFile(bufferOrErr->get()->getMemBufferRef(), *g->ctx);
        if (!ModuleOrErr) {
            fprintf(stderr, "ERROR parsing bc_filename %s\n", m_bc_filename.c_str());
        } else {
            llvm::Module *M = ModuleOrErr.get().release();
            // M->print(llvm::outs(), nullptr);
            return M;
        }
    }
    }
    return nullptr;
}
