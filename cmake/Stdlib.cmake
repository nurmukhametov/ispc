#
#  Copyright (c) 2018-2024, Intel Corporation
#
#  SPDX-License-Identifier: BSD-3-Clause

#
# ispc Stdlib.cmake
#

function (write_stdlib_bitcode_lib name target os bit)
    set(arch "error")
    if ("${target}" MATCHES "sse|avx")
        if ("${bit}" STREQUAL "32")
            set(arch "x86")
        elseif ("${bit}" STREQUAL "64")
            set(arch "x86_64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "neon")
        if ("${bit}" STREQUAL "32")
            set(arch "arm")
        elseif ("${bit}" STREQUAL "64")
            set(arch "aarch64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "wasm")
        if ("${bit}" STREQUAL "32")
            set(arch "wasm32")
        elseif ("${bit}" STREQUAL "64")
            set(arch "wasm64")
        else()
            set(arch "error")
        endif()
    elseif ("${target}" MATCHES "gen9|xe")
        set(arch "xe64")
    endif()
    if ("${arch}" STREQUAL "error")
        message(FATAL_ERROR "Incorrect target or bit passed to write_stdlib_bitcode_lib ${target} ${os} ${bit}")
    endif()

    if ("${os}" STREQUAL "unix")
        set(os "linux")
    endif()

    string(REPLACE "-" "_" target ${target})
    file(APPEND ${CMAKE_BINARY_DIR}/bitcode_libs_generated.cpp
      "static BitcodeLib ${name}(BitcodeLib::BitcodeLibType::Stdlib, \"${name}.bc\", ISPCTarget::${target}, TargetOS::${os}, Arch::${arch});\n")

    if ("${os}" STREQUAL "linux" AND APPLE AND NOT ISPC_LINUX_TARGET)
        set(os "macos")
    endif()

    set(canon_os ${os} PARENT_SCOPE)
    set(arch ${arch} PARENT_SCOPE)
endfunction()

function (stdlib_to_cpp ispc_name target bit os)
    set(name stdlib-${target}-${bit}bit-${os})
    string(REPLACE "-" "_" name "${name}")
    set(cpp ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${name}.cpp)
    set(bc ${BITCODE_FOLDER}/${name}.bc)

    # macOS target supports only x86_64 and aarch64
    if ("${os}" STREQUAL "unix" AND APPLE AND NOT ISPC_LINUX_TARGET AND "${bit}" STREQUAL "32")
        return()
    endif()

    # define canon_os and arch
    write_stdlib_bitcode_lib(${name} ${target} ${os} ${bit})

    add_custom_command(
        OUTPUT ${bc}
        COMMAND ${ispc_name} --nostdlib --gen-stdlib --target=${target} --arch=${arch} --target-os=${canon_os} stdlib.ispc --emit-llvm -o ${bc}
        DEPENDS ${ispc_name} ${STDLIB_ISPC_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    string(TOUPPER ${os} OS_UP)
    add_custom_command(
        OUTPUT ${cpp}
        COMMAND ${Python3_EXECUTABLE} bitcode2cpp.py ${bc} --type=stdlib --runtime=${bit} --os=${OS_UP} ${cpp}
        DEPENDS bitcode2cpp.py ${bc}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    set(tmp_list_bc ${STDLIB_BC_FILES})
    list(APPEND tmp_list_bc ${bc})
    set(STDLIB_BC_FILES ${tmp_list_bc} PARENT_SCOPE)

    set(tmp_list_cpp ${STDLIB_CPP_FILES})
    list(APPEND tmp_list_cpp ${cpp})
    set(STDLIB_CPP_FILES ${tmp_list_cpp} PARENT_SCOPE)
endfunction()

function (generate_stdlibs_1 ispc_name)
    list(APPEND os_list)
    if (ISPC_WINDOWS_TARGET)
        list(APPEND os_list "windows")
    endif()
    if (ISPC_UNIX_TARGET)
        list(APPEND os_list "unix")
    endif()

    if (NOT os_list)
        message(FATAL_ERROR "Windows or Linux target has to be enabled")
    endif()

    # "Regular" targets, targeting specific real ISA: sse/avx
    if (X86_ENABLED)
        foreach (target ${X86_TARGETS})
            foreach (bit 32 64)
                foreach (os ${os_list})
                    stdlib_to_cpp(${ispc_name} ${target} ${bit} ${os})
                endforeach()
            endforeach()
        endforeach()
    endif()

    # XE targets
    if (XE_ENABLED)
        foreach (target ${XE_TARGETS})
            foreach (os ${os_list})
                stdlib_to_cpp(${ispc_name} ${target} 64 ${os})
            endforeach()
        endforeach()
    endif()

    # ARM targets
    if (ARM_ENABLED)
        foreach (os ${os_list})
            foreach (target ${ARM_TARGETS})
                if (${os} STREQUAL "windows")
                    continue()
                endif()
                stdlib_to_cpp(${ispc_name} ${target} 32 ${os})
            endforeach()
            # Not all targets have 64bit
            stdlib_to_cpp(${ispc_name} neon-i32x4 64 ${os})
            stdlib_to_cpp(${ispc_name} neon-i32x8 64 ${os})
        endforeach()
    endif()

    # WASM targets
    if (WASM_ENABLED)
        foreach (target ${WASM_TARGETS})
            foreach (bit 32 64)
                stdlib_to_cpp(${ispc_name} ${target} ${bit} web)
            endforeach()
        endforeach()
    endif()

    set(STDLIB_BC_FILES ${STDLIB_BC_FILES} PARENT_SCOPE)
    set(STDLIB_CPP_FILES ${STDLIB_CPP_FILES} PARENT_SCOPE)
endfunction()

function (stdlib_header_cpp name)
    set(src ${INCLUDE_FOLDER}/${header})
    string(REPLACE "." "_" header ${header})
    set(cpp ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${header}.cpp)

    add_custom_command(
        OUTPUT ${cpp}
        COMMAND ${Python3_EXECUTABLE} bitcode2cpp.py ${src} --type=header ${cpp}
        DEPENDS bitcode2cpp.py ${src}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

    set(tmp_list ${STDLIB_HEADERS_CPP})
    list(APPEND tmp_list ${cpp})
    set(STDLIB_HEADERS_CPP ${tmp_list} PARENT_SCOPE)
endfunction()

function (stdlib_headers)
    foreach (header ${STDLIB_HEADERS})
        set(target_name stdlib-${header})
        set(src ${CMAKE_SOURCE_DIR}/${header})
        set(dest ${INCLUDE_FOLDER}/${header})
        list(APPEND stdlib_headers_list ${dest})

        add_custom_command(
            OUTPUT ${dest}
            DEPENDS ${src}
            COMMAND ${CMAKE_COMMAND} -E copy ${src} ${dest})

        stdlib_header_cpp(${header})
    endforeach()

    add_custom_target(stdlib-headers ALL DEPENDS ${stdlib_headers_list})

    set(STDLIB_HEADERS_CPP ${STDLIB_HEADERS_CPP} PARENT_SCOPE)
endfunction()

function (generate_stdlibs ispc_name)
    stdlib_headers()

    add_custom_target(stdlib-headers-cpp DEPENDS ${STDLIB_HEADERS_CPP})
    set_target_properties(stdlib-headers-cpp PROPERTIES SOURCE "${STDLIB_HEADERS_CPP}")

    generate_stdlibs_1(${ispc_name})

    add_custom_target(stdlibs-bc DEPENDS ${STDLIB_BC_FILES})
    # TODO! stdlibs-cpp is kind of empty
    add_custom_target(stdlibs-cpp DEPENDS stdlibs-bc)
    set_target_properties(stdlibs-cpp PROPERTIES SOURCE "${STDLIB_CPP_FILES}")

    add_library(stdlib OBJECT EXCLUDE_FROM_ALL ${STDLIB_CPP_FILES} ${STDLIB_HEADERS_CPP})
    add_dependencies(stdlib stdlibs-cpp)
    add_dependencies(stdlib stdlib-headers-cpp)

    if (MSVC)
        source_group("Generated Include Files" FILES ${STDLIB_HEADERS_CPP})
        source_group("Generated Stdlib Files" FILES ${STDLIB_CPP_FILES})
    endif()
    set_source_files_properties(${STDLIB_HEADERS_CPP} PROPERTIES GENERATED true)
    set_source_files_properties(${STDLIB_CPP_FILES} PROPERTIES GENERATED true)
endfunction()
