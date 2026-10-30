cmake_minimum_required(VERSION 3.21)

project(wallpaper-picker VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Widgets Concurrent Network)
find_package(LayerShellQt REQUIRED)

qt_add_executable(wallpaper-picker
    src/main.cpp
)

target_link_libraries(wallpaper-picker PRIVATE
    Qt6::Widgets
    Qt6::Concurrent
    Qt6::Network
    LayerShellQt::Interface
)

install(TARGETS wallpaper-picker
    RUNTIME DESTINATION lib/wallpaper-picker
)

install(PROGRAMS scripts/wallpaper-picker.csh
    DESTINATION bin
    RENAME wallpaper-picker
)
