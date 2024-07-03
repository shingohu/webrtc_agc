# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(webrtc_agc_library VERSION 0.0.1 LANGUAGES C)

add_library(webrtc_agc SHARED
        "webrtc_agc.c"
        "agc.c"
        )

set_target_properties(webrtc_agc PROPERTIES
        PUBLIC_HEADER webrtc_agc.h
        OUTPUT_NAME "webrtc_agc"
        )

target_compile_definitions(webrtc_agc PUBLIC DART_SHARED_LIB)
