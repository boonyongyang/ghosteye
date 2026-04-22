# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(ghosteye_frame_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(ghosteye_frame_ffi SHARED
  "ghosteye_frame_ffi.c"
)

set_target_properties(ghosteye_frame_ffi PROPERTIES
  PUBLIC_HEADER ghosteye_frame_ffi.h
  OUTPUT_NAME "ghosteye_frame_ffi"
)

target_compile_definitions(ghosteye_frame_ffi PUBLIC DART_SHARED_LIB)
