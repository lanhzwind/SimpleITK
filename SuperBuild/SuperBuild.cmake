#-----------------------------------------------------------------------------
# CTest Related Settings
#-----------------------------------------------------------------------------
set(BUILDNAME "NoBuldNameGiven")
set(SITE      "NoSiteGiven")
set(BUILD_TESTING_DEFAULT ON)
if(CMAKE_VERSION VERSION_LESS 2.8.11)
  set(BUILD_TESTING_DEFAULT OFF)
endif()
option( BUILD_TESTING "Turn on Testing for SimpleITK" ${BUILD_TESTING_DEFAULT} )

# 2.8.11 required for ExternalData.cmake.
if( BUILD_TESTING AND CMAKE_VERSION VERSION_LESS 2.8.11 )
  message( FATAL_ERROR "BUILD_TESTING ON requires CMake 2.8.11 or newer." )
endif()


configure_file(../CMake/CTestCustom.cmake.in CTestCustom.cmake)


enable_language(C)
enable_language(CXX)

#-----------------------------------------------------------------------------
# Platform check
#-----------------------------------------------------------------------------
set(PLATFORM_CHECK true)
if(PLATFORM_CHECK)
  # See CMake/Modules/Platform/Darwin.cmake)
  #   6.x == Mac OSX 10.2 (Jaguar)
  #   7.x == Mac OSX 10.3 (Panther)
  #   8.x == Mac OSX 10.4 (Tiger)
  #   9.x == Mac OSX 10.5 (Leopard)
  #  10.x == Mac OSX 10.6 (Snow Leopard)
  if (DARWIN_MAJOR_VERSION LESS "9")
    message(FATAL_ERROR "Only Mac OSX >= 10.5 are supported !")
  endif()
endif()

#-----------------------------------------------------------------------------
# Update CMake module path
#------------------------------------------------------------------------------

set(CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/CMake
  ${CMAKE_SOURCE_DIR}/SuperBuild
  ${CMAKE_BINARY_DIR}/CMake
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../CMake #  CMake directory
  ${CMAKE_CURRENT_SOURCE_DIR}/../Wrapping
  ${CMAKE_MODULE_PATH}
  )

include(sitkPreventInSourceBuilds)
include(sitkPreventInBuildInstalls)
include(VariableList)


#-----------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------
#

# Compute -G arg for configuring external projects with the same CMake generator:
if(CMAKE_EXTRA_GENERATOR)
  set(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
else()
  set(gen "${CMAKE_GENERATOR}")
endif()

#-----------------------------------------------------------------------------
# Use GIT protocol
#------------------------------------------------------------------------------
find_package(Git)
set(SITK_GIT_PROTOCOL_default "https")
if (GIT_VERSION_STRING VERSION_LESS "1.7.10")
  # minimum version for https support
  set(SITK_GIT_PROTOCOL_default "git")
endif()
set(SITK_GIT_PROTOCOL  ${SITK_GIT_PROTOCOL_default} CACHE STRING "If behind a firewall turn set this to 'https' or 'http'." )
mark_as_advanced(SITK_GIT_PROTOCOL)
set_property(CACHE SITK_GIT_PROTOCOL PROPERTY STRINGS "https;http;git")
set(git_protocol ${SITK_GIT_PROTOCOL})


#-----------------------------------------------------------------------------
# SimpleITK options
#------------------------------------------------------------------------------

option( BUILD_EXAMPLES "Enable Building of the SimpleITK Examples as a separate project." ON )

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Default to build shared libraries off
option(BUILD_SHARED_LIBS "Build SimpleITK ITK with shared libraries. This does not effect wrapped languages." OFF)

# as this option does not robustly work across platforms it will be marked as advanced
mark_as_advanced( FORCE BUILD_SHARED_LIBS )

option( SITK_4D_IMAGES "Add Image and I/O support for four spatial dimensions." OFF )
mark_as_advanced( SITK_4D_IMAGES )

#-----------------------------------------------------------------------------
# Setup build type
#------------------------------------------------------------------------------

# By default, let's build as Debug
if(NOT DEFINED CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()

# let a dashboard override the default.
if(CTEST_BUILD_CONFIGURATION)
  set(CMAKE_BUILD_TYPE "${CTEST_BUILD_CONFIGURATION}")
endif()

#-------------------------------------------------------------------------
# augment compiler flags
#-------------------------------------------------------------------------
include(sitkCheckRequiredFlags)
set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SimpleITK_REQUIRED_CXX_FLAGS}" )

#------------------------------------------------------------------------------
# BuildName used for dashboard reporting
#------------------------------------------------------------------------------
if(NOT BUILDNAME)
  set(BUILDNAME "Unknown-build" CACHE STRING "Name of build to report to dashboard")
endif()


#------------------------------------------------------------------------------
# WIN32 /bigobj is required for windows builds because of the size of
#------------------------------------------------------------------------------
if (MSVC)
  # some object files (CastImage for instance)
  set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj" )
  set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /bigobj" )
  # Avoid some warnings
  add_definitions ( -D_SCL_SECURE_NO_WARNINGS )
endif()

#------------------------------------------------------------------------------
# Setup build locations.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Common Build Options to pass to all subsequent tools
#------------------------------------------------------------------------------
list( APPEND ep_common_list
  MAKECOMMAND
  CMAKE_BUILD_TYPE
  CMAKE_MAKE_PROGRAM

  CMAKE_C_COMPILER
  CMAKE_C_COMPILER_ARG1

  CMAKE_C_FLAGS
  CMAKE_C_FLAGS_DEBUG
  CMAKE_C_FLAGS_MINSIZEREL
  CMAKE_C_FLAGS_RELEASE
  CMAKE_C_FLAGS_RELWITHDEBINFO

  CMAKE_CXX_COMPILER
  CMAKE_CXX_COMPILER_ARG1

  CMAKE_CXX_FLAGS
  CMAKE_CXX_FLAGS_DEBUG
  CMAKE_CXX_FLAGS_MINSIZEREL
  CMAKE_CXX_FLAGS_RELEASE
  CMAKE_CXX_FLAGS_RELWITHDEBINFO

  CMAKE_LINKER

  CMAKE_EXE_LINKER_FLAGS
  CMAKE_EXE_LINKER_FLAGS_DEBUG
  CMAKE_EXE_LINKER_FLAGS_MINSIZEREL
  CMAKE_EXE_LINKER_FLAGS_RELEASE
  CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO
  CMAKE_MODULE_LINKER_FLAGS
  CMAKE_MODULE_LINKER_FLAGS_DEBUG
  CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL
  CMAKE_MODULE_LINKER_FLAGS_RELEASE
  CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO
  CMAKE_SHARED_LINKER_FLAGS
  CMAKE_SHARED_LINKER_FLAGS_DEBUG
  CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL
  CMAKE_SHARED_LINKER_FLAGS_RELEASE
  CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO

  CMAKE_STRIP

  CMAKE_PREFIX_PATH
  CMAKE_FRAMEWORK_PATH
  CMAKE_SYSTEM_PREFIX_PATH
  CMAKE_SYSTEM_INCLUDE_PATH
  CMAKE_SYSTEM_LIBRARY_PATH
  CMAKE_SYSTEM_PROGRAM_PATH
  CMAKE_SYSTEM_IGNORE_PATH


  CMAKE_GENERATOR
  CMAKE_EXTRA_GENERATOR
  MEMORYCHECK_COMMAND_OPTIONS
  MEMORYCHECK_SUPPRESSIONS_FILE
  MEMORYCHECK_COMMAND
  SITE
  BUILDNAME )

if( APPLE )
  list( APPEND ep_common_list
    CMAKE_OSX_SYSROOT
    CMAKE_OSX_DEPLOYMENT_TARGET )
endif()

if( DEFINED CMAKE_STRIP_FLAGS )
  list( APPEND ep_common_list
    CMAKE_STRIP_FLAGS )
endif()

VariableListToArgs( ep_common_list ep_common_args )

if( APPLE )
  list( APPEND ep_common_list CMAKE_OSX_ARCHITECTURES )
endif()
VariableListToCache( ep_common_list ep_common_cache )

#
# Use CMake file which present options for wrapped languages, and finds languages as needed
#
include(sitkLanguageOptions)


#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
include(ExternalProject)

#------------------------------------------------------------------------------
# Lua
#------------------------------------------------------------------------------
option ( USE_SYSTEM_LUA "Use a pre-compiled version of LUA 5.1 previously configured for your system" OFF )
mark_as_advanced(USE_SYSTEM_LUA)
if ( USE_SYSTEM_LUA )
  find_package( LuaInterp REQUIRED 5.1 )
  set( SITK_LUA_EXECUTABLE ${LUA_EXECUTABLE} CACHE PATH "Lua executable used for code generation." )
  mark_as_advanced( SITK_LUA_EXECUTABLE )
  unset( LUA_EXECUTABLE CACHE )
else()
  include(External_Lua)
  list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES Lua)
  set( SITK_LUA_EXECUTABLE ${SITK_LUA_EXECUTABLE} CACHE PATH "Lua executable used for code generation." )
  mark_as_advanced( SITK_LUA_EXECUTABLE )
endif()

#------------------------------------------------------------------------------
# Swig
#------------------------------------------------------------------------------
option ( USE_SYSTEM_SWIG "Use a pre-compiled version of SWIG 2.0 previously configured for your system" OFF )
mark_as_advanced(USE_SYSTEM_SWIG)
if(USE_SYSTEM_SWIG)
  find_package ( SWIG 2 REQUIRED )
else()
  include(External_Swig)
  list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES Swig)
endif()

#------------------------------------------------------------------------------
# Google Test
#------------------------------------------------------------------------------
option( USE_SYSTEM_GTEST "Use a pre-compiled version of GoogleTest. " OFF )
mark_as_advanced(USE_SYSTEM_GTEST)
if ( BUILD_TESTING )
  if (USE_SYSTEM_GTEST)
    find_package( GTest REQUIRED )
    list(APPEND SimpleITK_VARS GTEST_LIBRARIES GTEST_INCLUDE_DIRS GTEST_MAIN_LIBRARIES)
  else()
    include(External_GTest)
    set( GTEST_ROOT ${GTEST_ROOT} )
    list(APPEND SimpleITK_VARS GTEST_ROOT)
    list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES GTest)
  endif()
endif()

#------------------------------------------------------------------------------
# Python virtualenv
#------------------------------------------------------------------------------
option( USE_SYSTEM_VIRTUALENV "Use a system version of Python's virtualenv. " OFF )
mark_as_advanced(USE_SYSTEM_VIRTUALENV)
if ( USE_SYSTEM_VIRTUALENV )
  find_package( PythonVirtualEnv REQUIRED)
else()
  include(External_virtualenv)
  if ( WRAP_PYTHON )
    list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES virtualenv)
  endif()
endif()
list(APPEND SimpleITK_VARS PYTHON_VIRTUALENV_SCRIPT)

#------------------------------------------------------------------------------
# ITK
#------------------------------------------------------------------------------

set(ITK_WRAPPING OFF CACHE BOOL "Turn OFF wrapping ITK with WrapITK")
mark_as_advanced( FORCE ITK_WRAPPING )
if(ITK_WRAPPING)
  list(APPEND ITK_DEPENDENCIES Swig)
endif()
option(USE_SYSTEM_ITK "Use a pre-built version of ITK" OFF)
mark_as_advanced(USE_SYSTEM_ITK)
if(USE_SYSTEM_ITK)
  find_package(ITK REQUIRED)
  #we require certain packages be turned on in ITK
  include(sitkCheckForITKModuleDependencies)
else()
  include(External_ITK)
  list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES ITK)
endif()



get_cmake_property( _varNames VARIABLES )

foreach (_varName ${_varNames})
  if(_varName MATCHES "^SimpleITK_" OR _varName MATCHES "^SITK_" )
    if (NOT _varName MATCHES "^SITK_LANGUAGES_VARS"
          AND
        NOT _varName MATCHES "^SimpleITK_VARS"
          AND
        NOT _varName MATCHES "^SimpleITK_REQUIRED_"
          AND
        NOT _varName MATCHES "^SITK_UNDEFINED_SYMBOLS_ALLOWED")
      message( STATUS "Passing variable \"${_varName}=${${_varName}}\" to SimpleITK external project.")
      list(APPEND SimpleITK_VARS ${_varName})
    endif()
  endif()
endforeach()


VariableListToCache( SimpleITK_VARS  ep_simpleitk_cache )
VariableListToArgs( SimpleITK_VARS  ep_simpleitk_args )
VariableListToCache( SITK_LANGUAGES_VARS  ep_languages_cache )
VariableListToArgs( SITK_LANGUAGES_VARS  ep_languages_args )

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/SimpleITK-build/CMakeCacheInit.txt" "${ep_simpleitk_cache}${ep_common_cache}\n${ep_languages_cache}" )

set(proj SimpleITK)
ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
  BINARY_DIR SimpleITK-build
  INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    --no-warn-unused-cli
    -C "${CMAKE_CURRENT_BINARY_DIR}/SimpleITK-build/CMakeCacheInit.txt"
    ${ep_simpleitk_args}
    ${ep_common_args}
    -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
    -DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}
    -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=<BINARY_DIR>/lib
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=<BINARY_DIR>/lib
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=<BINARY_DIR>/bin
    -DCMAKE_BUNDLE_OUTPUT_DIRECTORY:PATH=<BINARY_DIR>/bin
    ${ep_languages_args}
    # ITK
    -DITK_DIR:PATH=${ITK_DIR}
    # Swig
    -DSWIG_DIR:PATH=${SWIG_DIR}
    -DSWIG_EXECUTABLE:PATH=${SWIG_EXECUTABLE}
    -DBUILD_TESTING:BOOL=${BUILD_TESTING}
    -DWRAP_LUA:BOOL=${WRAP_LUA}
    -DWRAP_PYTHON:BOOL=${WRAP_PYTHON}
    -DWRAP_RUBY:BOOL=${WRAP_RUBY}
    -DWRAP_JAVA:BOOL=${WRAP_JAVA}
    -DWRAP_TCL:BOOL=${WRAP_TCL}
    -DWRAP_CSHARP:BOOL=${WRAP_CSHARP}
    -DWRAP_R:BOOL=${WRAP_R}
    -DBUILD_EXAMPLES:BOOL=${BUILD_EXAMPLES}
    -DSimpleITK_BUILD_DISTRIBUTE:BOOL=${SimpleITK_BUILD_DISTRIBUTE}
    -DSimpleITK_PYTHON_THREADS:BOOL=${SimpleITK_PYTHON_THREADS}
  DEPENDS ${${CMAKE_PROJECT_NAME}_DEPENDENCIES}
)

ExternalProject_Add_Step(${proj} forcebuild
  COMMAND ${CMAKE_COMMAND} -E remove
    ${CMAKE_CURRENT_BUILD_DIR}/${proj}-prefix/src/${proj}-stamp/${prog}-build
  DEPENDEES configure
  DEPENDERS build
  ALWAYS 1
)


#------------------------------------------------------------------------------
# SimpleITKExamples
#------------------------------------------------------------------------------

# We build SimpleITKExamples as an enternal project to verify
# installation of SimpleITK

include(External_SimpleITKExamples)


#------------------------------------------------------------------------------
# List of external projects
#------------------------------------------------------------------------------
set(external_project_list ITK Swig SimpleITKExamples PCRE Lua GTest virtualenv ${CMAKE_PROJECT_NAME})


#-----------------------------------------------------------------------------
# Dump external project dependencies
#-----------------------------------------------------------------------------
set(ep_dependency_graph "# External project dependencies")
foreach(ep ${external_project_list})
  set(ep_dependency_graph "${ep_dependency_graph}\n${ep}: ${${ep}_DEPENDENCIES}")
endforeach()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/ExternalProjectDependencies.txt "${ep_dependency_graph}\n")
