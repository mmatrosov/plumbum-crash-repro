cmake_minimum_required(VERSION 3.19.0)

project(plumbum-repro-case CXX)

include("build/conan_paths.cmake")

find_package(
  Python3
  COMPONENTS Development
  REQUIRED)
find_package(Boost 1.76.0 EXACT REQUIRED python38)
target_link_libraries(Boost::python38 INTERFACE Python3::Module)

add_library(extension SHARED extension.cpp)
target_link_libraries(extension PRIVATE Boost::python38)
