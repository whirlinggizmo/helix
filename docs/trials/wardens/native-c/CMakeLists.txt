# Builds the game natively: every .c here, against raylib 5.5's desktop library (OpenGL 3.3) in lib/, into native/wardens. It reads
# assets/ (and shaders/) from this directory, its working directory when run.
#
#     cmake -B build && cmake --build build
cmake_minimum_required(VERSION 3.16)
project(wardens C)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_C_STANDARD 99)

file(GLOB SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/*.c")
add_executable(wardens ${SOURCES})
# native/ itself, not a folder of each configuration under it.
set_target_properties(wardens PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/native/$<0:>")
target_include_directories(wardens PRIVATE "${CMAKE_SOURCE_DIR}/include")
target_compile_definitions(wardens PRIVATE PLATFORM_DESKTOP _GNU_SOURCE)
if(NOT MSVC)
  target_compile_options(wardens PRIVATE -Wall)
endif()

# raylib's library, and what it needs of each system.
target_link_libraries(wardens PRIVATE
  "${CMAKE_SOURCE_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}raylib${CMAKE_STATIC_LIBRARY_SUFFIX}")
if(WIN32)
  target_link_libraries(wardens PRIVATE opengl32 gdi32 winmm)
elseif(APPLE)
  target_link_libraries(wardens PRIVATE "-framework Cocoa" "-framework IOKit" "-framework OpenGL" "-framework CoreVideo")
else()
  target_link_libraries(wardens PRIVATE GL m pthread dl rt X11)
endif()
