# Stockfish 18 for Android, from the same vendored sources and the same flat C
# bridge the iOS app builds (ios/Vendor/Stockfish), plus a JNI layer over the
# bridge. GPLv3 — see ios/Vendor/Stockfish/Copying.txt.
cmake_minimum_required(VERSION 3.22)
project(brasspawn LANGUAGES CXX)

set(SF_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../ios/Vendor/Stockfish)
file(GLOB SF_SOURCES
    ${SF_ROOT}/src/*.cpp
    ${SF_ROOT}/src/nnue/*.cpp
    ${SF_ROOT}/src/nnue/features/*.cpp
    ${SF_ROOT}/src/syzygy/*.cpp)
# The standalone binary's entry point.
list(REMOVE_ITEM SF_SOURCES ${SF_ROOT}/src/main.cpp)

add_library(brasspawn SHARED
    ${SF_SOURCES}
    ${SF_ROOT}/bridge/sfbridge.cpp
    engine_jni.cpp)

target_include_directories(brasspawn PRIVATE ${SF_ROOT}/src ${SF_ROOT}/bridge/include ${SF_ROOT}/bridge)
set_target_properties(brasspawn PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)

# Networks are loaded from files at run time, as on iOS: they ship as assets
# and the app chooses the path.
target_compile_definitions(brasspawn PRIVATE NDEBUG NNUE_EMBEDDING_OFF USE_PTHREADS IS_64BIT USE_POPCNT)
target_compile_options(brasspawn PRIVATE -O3 -fno-exceptions -fvisibility=hidden -Wno-unused-parameter)

if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_definitions(brasspawn PRIVATE USE_NEON=8)
elseif(ANDROID_ABI STREQUAL "x86_64")
    # Every x86_64 Android device and emulator image has SSE4.2 and POPCNT.
    target_compile_definitions(brasspawn PRIVATE USE_SSE2 USE_SSSE3 USE_SSE41)
    target_compile_options(brasspawn PRIVATE -msse4.1 -mssse3 -mpopcnt)
endif()

target_link_libraries(brasspawn log)
# 16 KB pages: required for devices from Android 15.
target_link_options(brasspawn PRIVATE -Wl,-z,max-page-size=16384)
