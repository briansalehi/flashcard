cmake_minimum_required(VERSION 3.20)
project(Flashcard VERSION 0.1 LANGUAGES CXX)

find_package(Boost COMPONENTS program_options system)
find_package(OpenSSL)

file(GLOB source_files src/*)
add_executable(flashcard ${source_files})
target_include_directories(flashcard PRIVATE include)
target_link_libraries(flashcard PRIVATE Boost::program_options Boost::system ssl PUBLIC pthread)
