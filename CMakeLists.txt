# Copyright (C) 2023 George Mitchell
# See License.txt for details


cmake_minimum_required(VERSION 3.14...3.28)


option(FetchLua_PROJECT_BUILD_COMPILER "Build the Lua interpreter" OFF)

option(FetchLua_PROJECT_BUILD_INTERPRETER "Build the Lua Compiler" OFF)

option(BUILD_SHARED_LIBS "Build Lua as a shared library" OFF)

set(FetchLua_PROJECT_LUA_VERSION 5.4.6 CACHE STRING "Lua version to use")

set(FetchLua_PROJECT_LUA_INCLUDE_DIR_NAME lua CACHE STRING
  "Directory name for Lua headers")

set(FetchLua_PROJECT_LUA_LIBRARY_DEBUG_SUFFIX d CACHE STRING
  "Lua debug library filename suffix")


project(FetchLua
  VERSION 0.2.0.0
  DESCRIPTION "A CMake module for interfacing with Lua"
  LANGUAGES C)


set(FetchLua_LUA_PROJECT_DIR "${PROJECT_BINARY_DIR}/${PROJECT_NAME}")

set(FetchLua_BUILD_COMPILER ${FetchLua_PROJECT_BUILD_COMPILER})

set(FetchLua_BUILD_INTERPRETER ${FetchLua_PROJECT_BUILD_INTERPRETER})

set(FetchLua_LUA_VERSION ${FetchLua_PROJECT_LUA_VERSION})

set(FetchLua_LUA_INCLUDE_DIR_NAME ${FetchLua_PROJECT_LUA_INCLUDE_DIR_NAME})

set(FetchLua_LUA_LIBRARY_DEBUG_SUFFIX
  ${FetchLua_PROJECT_LUA_LIBRARY_DEBUG_SUFFIX})

include(FetchLua.cmake)

FetchLua_Declare()

FetchLua_MakeAvailable()
