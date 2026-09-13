cmake_minimum_required(VERSION 3.14)

project(Circa2020UnitTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../20-circa2020/lib")

include("${LIB_PATH}/lib.cmake")

include(FetchContent)

FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v2.13.10
)

FetchContent_MakeAvailable(Catch2)

add_executable(circa_unit_tests
    tests/adder_tests.cpp
)

target_link_libraries(circa_unit_tests
    PRIVATE
    ${LIB_NAME}
    Catch2::Catch2
)

enable_testing()

add_test(
    NAME circa_unit_tests
    COMMAND circa_unit_tests
)
