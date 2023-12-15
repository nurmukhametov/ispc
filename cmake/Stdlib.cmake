#
#  Copyright (c) 2018-2024, Intel Corporation
#
#  SPDX-License-Identifier: BSD-3-Clause

#
# ispc Stdlib.cmake
#

if (WIN32)
    set(TARGET_OS_LIST_FOR_STDLIB "windows" "linux")
elseif (UNIX)
    set(TARGET_OS_LIST_FOR_STDLIB "linux")
endif()

function(create_stdlib_commands stdlibInitStr)
    foreach (ispc_target ${ISPC_TARGETS})
        foreach (bit 32 64)
            foreach (target_os ${TARGET_OS_LIST_FOR_STDLIB})
                # Neon targets constrains: neon-i8x16 and neon-i16x8 are implemented only for 32 bit ARM.
                if ("${bit}" STREQUAL "64" AND
                    (${ispc_target} STREQUAL "neon-i8x16" OR ${ispc_target} STREQUAL "neon-i16x8"))
                    continue()
                endif()

                string(REGEX MATCH "^(sse|avx)" isX86 ${ispc_target})
                if (isX86)
                    if (${bit} STREQUAL "64")
                        set(target_arch "x86_64")
                    else()
                        set(target_arch "x86")
                    endif()
                endif()

                string(REGEX MATCH "^(neon)" isArm ${ispc_target})
                if (isArm)
                    if (${bit} STREQUAL "64")
                        set(target_arch "aarch64")
                    else()
                        set(target_arch "arm")
                    endif()
                endif()

                # TODO! Xe and wasm
                # Xe targets are implemented only for 64 bit.
                string(REGEX MATCH "^xe" isXe "${ispc_target}")
                if ("${bit}" STREQUAL "32" AND isXe)
                    continue()
                endif()

                string(REPLACE "-" "_" ispc_target_u "${ispc_target}")
                set(filename stdlib-${ispc_target_u}_${target_arch}_${target_os}.bc)
                set(output ${BITCODE_FOLDER}/${filename})
                list(APPEND STDLIB_BC_FILES ${output})
                list(APPEND BITCODE_LIB_CONSTRUCTORS "BitcodeLib(\"${filename}\", ISPCTarget::${ispc_target_u}, TargetOS::${target_os}, Arch::${target_arch})")
                add_custom_command(
                    OUTPUT ${output}
                    COMMAND ${PROJECT_NAME} --nostdlib --gen-stdlib --target=${ispc_target} --arch=${target_arch} --target-os=${target_os} stdlib.ispc --emit-llvm -o ${output}
                    DEPENDS ${PROJECT_NAME} stdlib.ispc
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                )
            endforeach()
        endforeach()
    endforeach()

    add_custom_target(
        stdlib ALL
        DEPENDS ${STDLIB_BC_FILES}
    )

    set(tmpStdlibInitStr "")
    foreach(elem IN LISTS BITCODE_LIB_CONSTRUCTORS)
        set(tmpStdlibInitStr "${tmpStdlibInitStr}\n    ${elem}, ")
    endforeach()

    set(${stdlibInitStr} ${tmpStdlibInitStr} PARENT_SCOPE)
endfunction()
