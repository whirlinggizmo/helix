# The platform's C-only tests (tools/native_build.py configures and builds them): each compiles an adapter's C with a test of its own,
# against the SDL3 the build links, with GCC or Clang, or MSVC on Windows.
#
#   cmake -S platform/tests/native -B build/native-tests -DHELIX_ROOT=<checkout> -DSDL3_LIBRARY=<library> "-DSDL3_RUNTIME=<files>"
#
# SDL3_LIBRARY is the library to link (tools/sdl3.py's find), SDL3_RUNTIME what each program needs beside it (SDL3.dll on Windows).
cmake_minimum_required(VERSION 3.20)
project(helix_native_tests C)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
# Optimized, with asserts kept: the tests check with them.
if(MSVC)
  set(CMAKE_C_FLAGS_RELEASE "/O2")
else()
  set(CMAKE_C_FLAGS_RELEASE "-O3")
endif()
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release)
endif()
foreach(config IN ITEMS "" _RELEASE _DEBUG)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY${config} ${CMAKE_BINARY_DIR}/bin)
endforeach()

set(ADAPTERS ${HELIX_ROOT}/platform/src/helix/platform/adapters)
set(MIXER ${HELIX_ROOT}/platform/vendor/sdl3_mixer)
set(AUDIO ${ADAPTERS}/audio/sdl3mixer/internal)
file(GLOB MIXER_SOURCES ${MIXER}/src/*.c)

function(native_test name)
  add_executable(${name} ${ARGN})
  target_include_directories(${name} PRIVATE ${HELIX_ROOT}/platform/vendor ${HELIX_ROOT}/platform/vendor/sdl3 ${ADAPTERS}/shared
    ${ADAPTERS}/graphics/sokol/internal)
  target_link_libraries(${name} PRIVATE ${SDL3_LIBRARY})
  if(WIN32)
    target_link_libraries(${name} PRIVATE dwmapi shell32)
  elseif(UNIX AND NOT APPLE)
    target_compile_definitions(${name} PRIVATE _POSIX_C_SOURCE=200809L)
    target_link_libraries(${name} PRIVATE m pthread dl)
  endif()
  foreach(runtime IN LISTS SDL3_RUNTIME)
    add_custom_command(TARGET ${name} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy_if_different ${runtime} $<TARGET_FILE_DIR:${name}>)
  endforeach()
endfunction()

native_test(native-sdl3-events-test ${HELIX_ROOT}/platform/tests/native/native_sdl3_events.c ${ADAPTERS}/events/sdl3/internal/events_sdl3.c
  ${ADAPTERS}/shared/sdl3/sdl3.c)
target_include_directories(native-sdl3-events-test PRIVATE ${ADAPTERS}/shared/sdl3 ${ADAPTERS}/events/sdl3/internal)

foreach(name IN ITEMS native-sdl3mixer-audio-test native-sdl3mixer-device-probe)
  if(name STREQUAL native-sdl3mixer-audio-test)
    set(test native_sdl3mixer_audio.c)
  else()
    set(test native_sdl3mixer_device.c)
  endif()
  native_test(${name} ${HELIX_ROOT}/platform/tests/native/${test} ${AUDIO}/audio_sdl3mixer.c ${MIXER_SOURCES})
  target_include_directories(${name} PRIVATE ${MIXER}/include ${MIXER}/src ${AUDIO})
  target_compile_definitions(${name} PRIVATE DECODER_WAV DECODER_OGGVORBIS_STB DECODER_MP3_DRMP3 DECODER_FLAC_DRFLAC)
endforeach()
