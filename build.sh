#!/usr/bin/env bash
mkdir -p build
conan install -r conan-center --build=missing -pr clang-libstdcpp.conan-profile -if build conanfile.txt
cmake -S . -B build -G Ninja -DCMAKE_CXX_COMPILER=clang++-12 -DCMAKE_C_COMPILER=clang-12
ninja -C build