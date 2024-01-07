#[============================================================================[
  Copyright (C) 2023 George Mitchell

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY  AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#]============================================================================]

#[======================================================================[.rst:
FetchLua
--------

Provides an interface to the Lua library and executables.

This module provides the following targets:

``FetchLua::Lua``
  The Lua library

Commands
^^^^^^^^

.. command:: FetchLua_Declare

  .. code-block:: cmake

    FetchLua_Declare()

  FetchContent_Declare wrapper for declaring Lua content.

..  command:: FetchLua_MakeAvailable

  .. code-block:: cmake

    FetchLua_MakeAvailable()

  Exports the FetchLua::Lua library. The interpreter and compiler are also
  built and installed if specified.

Variables
^^^^^^^^^

None of FetchLua's variables are set through the cache. The intention is for
FetchLua to be configured only by the project developer. If there are FetchLua
behaviors you would like exposed to the client, it is recommended to provide
your own cache variables for achieving this.

.. variable:: FetchLua_LUA_VERSION

  The version of Lua to download and configure. The default Lua version is
  currently set to 5.4.6.

.. variable: FetchLua_LUA_PROJECT_DIR

  FetchLua's root project directory.
  Defaults to ${PROJECT_BINARY_DIR}/FetchLua

.. variable: FetchLua_LUA_INCLUDE_DIR_NAME

  Name of the directory prefix for including Lua headers
  (#include <${FetchLua_LUA_INCLUDE_DIR_NAME}/lua.h>). FetchLua modifies all
  Lua source files to accomodate this variable. Defaults to "lua".

.. variable: FetchLua_LUA_LIBRARY_DEBUG_SUFFIX

  Filename suffix appended to Lua's library filename when performing a Debug
  or RelWithDebInfo build. Defaults to "d".

.. variable: FetchLua_BUILD_INTERPRETER

  Enables compilation of Lua's interpreter.

.. variable: FetchLua_BUILD_COMPILER

  Enables compilation of Lua's compiler. As of Lua version 5.4.6, this target
  is only supported when building Lua as a static library.
#]======================================================================]

cmake_minimum_required(VERSION 3.14...3.28)


# ExternalProject ignores timestamps in archives by default
# See https://cmake.org/cmake/help/latest/policy/CMP0135.html for details
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()


include(GNUInstallDirs)
include(FetchContent)


set(PARENT_SCOPE)

if(NOT FetchLua_LUA_VERSION)
  set(FetchLua_LUA_VERSION 5.4.6)
endif()

if(NOT FetchLua_LUA_PROJECT_DIR)
  set(FetchLua_LUA_PROJECT_DIR "${PROJECT_BINARY_DIR}/FetchLua")
endif()

if(NOT FetchLua_LUA_INCLUDE_DIR_NAME)
  set(FetchLua_LUA_INCLUDE_DIR_NAME lua)
endif()

if(NOT FetchLua_LUA_LIBRARY_DEBUG_SUFFIX)
  set(FetchLua_LUA_LIBRARY_DEBUG_SUFFIX d)
endif()

if(NOT FetchLua_BUILD_INTERPRETER)
  set(FetchLua_BUILD_INTERPRETER OFF)
endif()

if(NOT FetchLua_BUILD_COMPILER)
  set(FetchLua_BUILD_COMPILER OFF)
endif()

unset(PARENT_SCOPE)


function(__FetchLua_EditLuaFileIncludes)

  foreach(lua_file IN LISTS ARGV)

    file(READ ${lua_file} in_data)

    string(REGEX REPLACE
      "([ \t]*)#([ \t]*)include([ \t]+)\"([a-z|A-Z|0-9]+\.h)\""
      "\\1#\\2include\\3<${FetchLua_LUA_INCLUDE_DIR_NAME}/\\4>"
      out_data "${in_data}")

    file(WRITE ${lua_file} "${out_data}")

  endforeach()

endfunction()


function(FetchLua_Declare)

  FetchContent_Declare(FetchLua_lua_content
    URL https://www.lua.org/ftp/lua-${FetchLua_LUA_VERSION}.tar.gz)

endfunction()


function(FetchLua_MakeAvailable)

  FetchContent_MakeAvailable(FetchLua_lua_content)

  file(GLOB lua_content_files
    "${fetchlua_lua_content_SOURCE_DIR}/src/*.c*"
    "${fetchlua_lua_content_SOURCE_DIR}/src/*.h*")

  set(FetchLua_LUA_SOURCE_DIR
    "${FetchLua_LUA_PROJECT_DIR}/${FetchLua_LUA_INCLUDE_DIR_NAME}")

  if(NOT EXISTS ${FetchLua_LUA_SOURCE_DIR})

    file(MAKE_DIRECTORY ${FetchLua_LUA_SOURCE_DIR})

    file(COPY ${lua_content_files} DESTINATION ${FetchLua_LUA_SOURCE_DIR})

    file(GLOB lua_files ${FetchLua_LUA_SOURCE_DIR}/*)

    __FetchLua_EditLuaFileIncludes(${lua_files})

  else()

    file(GLOB lua_files ${FetchLua_LUA_SOURCE_DIR}/*)

    list(LENGTH lua_files lua_files_length)

    if(NOT lua_files_length)

      file(COPY ${lua_content_files} DESTINATION ${FetchLua_LUA_SOURCE_DIR})

      file(GLOB lua_files "${FetchLua_LUA_SOURCE_DIR}/*")

      __FetchLua_EditLuaFileIncludes(${lua_files})

    endif()

  endif()

  set(lua_interpreter_srcs "${FetchLua_LUA_SOURCE_DIR}/lua.c")

  set(lua_compiler_srcs "${FetchLua_LUA_SOURCE_DIR}/luac.c")

  set(lua_lib_srcs ${lua_files})
  list(REMOVE_ITEM lua_lib_srcs ${lua_interpreter_srcs} ${lua_compiler_srcs})
  list(FILTER lua_lib_srcs INCLUDE REGEX .+\\.c|.+\\.cpp)

  set(lua_headers ${lua_files})
  list(FILTER lua_headers INCLUDE REGEX .+\\.h|.+\\.hpp)

  #
  # Lua library target
  #

  set(is_debug_build "$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>")
  set(is_gnu_compiler "$<OR:$<CXX_COMPILER_ID:GNU>,$<C_COMPILER_ID:GNU>>")
  set(is_clang_compiler
    "$<OR:$<CXX_COMPILER_ID:Clang>,$<C_COMPILER_ID:Clang>>")

  add_library(lua_lib_tgt ${lua_lib_srcs} ${lua_headers})

  target_compile_features(lua_lib_tgt PUBLIC c_std_99)

  target_include_directories(lua_lib_tgt PUBLIC ${FetchLua_LUA_PROJECT_DIR})

  target_link_libraries(lua_lib_tgt PRIVATE
    "$<${is_gnu_compiler}:m>" "$<${is_gnu_compiler}:dl>")

  # Lua version 5.4.6 Clang 17.0.1:
  # "lundump.c:233: warning: adding 'int' to a string does not append to
  #  the string [-Wstring-plus-int]"
  target_compile_options(lua_lib_tgt PRIVATE
    "$<${is_clang_compiler}:-Wno-string-plus-int>")

  target_compile_definitions(lua_lib_tgt
    PUBLIC
      "$<$<BOOL:${BUILD_SHARED_LIBS}>:LUA_BUILD_AS_DLL>")

  set(lua_lib_tgt_name
    "$<IF:${is_debug_build},lua${FetchLua_LUA_LIBRARY_DEBUG_SUFFIX},lua>")

  set_target_properties(lua_lib_tgt
    PROPERTIES
      POSITION_INDEPENDENT_CODE ${BUILD_SHARED_LIBS}
      OUTPUT_NAME ${lua_lib_tgt_name})

  add_library(FetchLua::Lua ALIAS lua_lib_tgt)

  install(TARGETS lua_lib_tgt EXPORT FetchLua::Lua)

  install(FILES ${lua_headers}
    DESTINATION include/${FetchLua_LUA_INCLUDE_DIR_NAME})

  #
  # Lua Interpreter Target
  #

  if(FetchLua_BUILD_INTERPRETER)

    add_executable(lua_interpreter_tgt ${lua_interpreter_srcs} ${lua_headers})

    target_link_libraries(lua_interpreter_tgt PRIVATE FetchLua::Lua)

    set_target_properties(lua_interpreter_tgt PROPERTIES OUTPUT_NAME lua)

    add_executable(FetchLua::LuaInterpreter ALIAS lua_interpreter_tgt)

    install(TARGETS lua_interpreter_tgt EXPORT FetchLua::LuaInterpreter)

  endif()

  #
  # Lua Compiler Target
  #

  if(FetchLua_BUILD_COMPILER)

    if(BUILD_SHARED_LIBS)

      message(FATAL_ERROR
        "The Lua compiler does not support linking with a shared Lua library.")

      message(AUTHOR_WARNING
        "Disable building the Lua compiler or build Lua as a static library.")

    endif()

    add_executable(lua_compiler_tgt ${lua_compiler_srcs} ${lua_headers})

    target_link_libraries(lua_compiler_tgt PRIVATE FetchLua::Lua)

    set_target_properties(lua_compiler_tgt PROPERTIES OUTPUT_NAME luac)

    add_executable(FetchLua::LuaCompiler ALIAS lua_compiler_tgt)

    install(TARGETS lua_compiler_tgt EXPORT FetchLua::LuaCompiler)

  endif()

endfunction()
