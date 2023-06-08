cmake_minimum_required(VERSION 3.5)
project(gtsam_catkin_example_project)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_compile_options(-O2)

set(SRC_FILES
  src/example.cpp
)

set(CATKIN_PACKAGE_DEPENDENCIES
  gtsam_catkin
)

find_package(Eigen3 REQUIRED)

find_package(catkin REQUIRED COMPONENTS
  ${CATKIN_PACKAGE_DEPENDENCIES}
)

catkin_package(
  INCLUDE_DIRS
  LIBRARIES gtsam
  CATKIN_DEPENDS ${CATKIN_PACKAGE_DEPENDENCIES}
  DEPENDS
)

include_directories(
  ${catkin_INCLUDE_DIRS}
  ${EIGEN3_INCLUDE_DIRS}
)

add_executable(${PROJECT_NAME}_node
  ${SRC_FILES}
)

add_dependencies(${PROJECT_NAME}_node
  ${catkin_EXPORTED_TARGETS}
)

target_link_libraries(${PROJECT_NAME}_node
  ${catkin_LIBRARIES}
)