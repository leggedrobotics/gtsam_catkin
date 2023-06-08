cmake_minimum_required(VERSION 3.16)
project(gtsam_catkin)

find_package(catkin REQUIRED)

set(CATKIN_PACKAGE_DEPENDENCIES
)

find_package(catkin REQUIRED COMPONENTS
  ${CATKIN_PACKAGE_DEPENDENCIES}
)

# Check whether gtsam can be found
find_package(gtsam QUIET)
find_package(Eigen3 REQUIRED)

# Color
if(NOT WIN32)
  string(ASCII 27 Esc)
  set(ColourReset "${Esc}[m")
  set(BoldMagenta "${Esc}[1;35m")
  set(Magenta     "${Esc}[35m")
endif()

# 1 - Check whether variable is set -----------------------------------------------------------
if(DEFINED ENV{gtsam_DIR})
  set(gtsam_DIR ENV{gtsam_DIR})
  find_package(gtsam CONFIG REQUIRED)
  message("${BoldMagenta}INFO: Found manually set path to gtsam. Using version located at $ENV{gtsam_DIR}.${ColourReset}")
  set(gtsam_INCLUDE_DIR_MAN "${gtsam_DIR}/../../../include/")
  message("gtsam include path: ${gtsam_INCLUDE_DIRS} , ${gtsam_INCLUDE_DIR_MAN}")
  message("gtsam libs: ${gtsam_LIBRARIES}")
  catkin_package(
  INCLUDE_DIRS 
    ${gtsam_INCLUDE_DIRS}
    ${gtsam_INCLUDE_DIR_MAN}
  LIBRARIES 
    ${gtsam_LIBRARIES} 
  CATKIN_DEPENDS
    ${CATKIN_PACKAGE_DEPENDENCIES}
  DEPENDS
    gtsam 
  )

# 2 - Check whether gtsam is installed -------------------------------------------------------
elseif(gtsam_FOUND)
  message("${BoldMagenta}INFO: Found gtsam.${ColourReset}")
  
  # Path differs whether installed from PPA or (locally) from source
  if(EXISTS "${gtsam_DIR}/../../../../include/")
    set(gtsam_INCLUDE_DIR_MAN "${gtsam_DIR}/../../../../include/")
  else()
    set(gtsam_INCLUDE_DIR_MAN "${gtsam_DIR}/../../../include/")
  endif()
  
  message("gtsam libraries: ${gtsam_LIBRARIES}")
  message("gtsam include path: ${gtsam_INCLUDE_DIRS} , ${gtsam_INCLUDE_DIR_MAN}")

# 3 - Compile in catkin workspace -------------------------------------------------------------
else()
  message("${BoldMagenta}INFO: Neither variable gtsam_DIR is set, nor could gtsam be found, hence compiling in workspace.${ColourReset}")

  # Newer version of CMake is required
  cmake_minimum_required(VERSION 3.18)

  # Catkinization of gtsam
  include(ExternalProject)
  file(MAKE_DIRECTORY ${CATKIN_DEVEL_PREFIX}/include)

  ExternalProject_Add(gtsam
    GIT_REPOSITORY "https://github.com/leggedrobotics/gtsam_fork.git"
    GIT_TAG "gtsam_rsl"
    GIT_SUBMODULES_RECURSE "true"
    GIT_PROGRESS "true"
    CMAKE_CACHE_ARGS "-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"
    PREFIX "${CMAKE_SOURCE_DIR}"
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/gtsam"
    BINARY_DIR "${CMAKE_SOURCE_DIR}/tmp"
    CMAKE_ARGS 
         -DCMAKE_BUILD_TYPE=Release
         -DGTSAM_POSE3_EXPMAP=ON
         -DGTSAM_ROT3_EXPMAP=ON
         -DGTSAM_USE_QUATERNIONS=ON
         -DGTSAM_USE_SYSTEM_EIGEN=ON
         -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF
         -DCMAKE_INSTALL_PREFIX=${CATKIN_DEVEL_PREFIX}
    INSTALL_COMMAND make install
  )

  add_dependencies(gtsam ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS})

  catkin_package(
    INCLUDE_DIRS 
      ${CATKIN_DEVEL_PREFIX}/include
    LIBRARIES
      ${CATKIN_DEVEL_PREFIX}/lib/libgtsam.so
      ${CATKIN_DEVEL_PREFIX}/lib/libgtsam_unstable.so
      ${CATKIN_DEVEL_PREFIX}/lib/libmetis-gtsam.so
    CATKIN_DEPENDS
      ${CATKIN_PACKAGE_DEPENDENCIES}
  )

  ExternalProject_Get_property(gtsam BINARY_DIR) 
  set(externBuildDirectory ${BINARY_DIR})
  message("extern's build directory is " ${externBuildDirectory})

  #############
  ## INSTALL ##
  #############
  message("Also installing Eigen3 headers: ${EIGEN3_INCLUDE_DIRS}")
  install(DIRECTORY ${CATKIN_DEVEL_PREFIX}/include/
    DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION}
  )

  install(DIRECTORY ${CATKIN_DEVEL_PREFIX}/lib/
    DESTINATION ${CATKIN_GLOBAL_LIB_DESTINATION}
  )

  # Exporting all run dependencies
  # Code snippet taken from catkin_simple: https://github.com/catkin/catkin_simple/blob/master/cmake/catkin_simple-extras.cmake.em
  
macro(cs_export)
  cmake_parse_arguments(CS_PROJECT
    "" "" "INCLUDE_DIRS;LIBRARIES;CATKIN_DEPENDS;DEPENDS;CFG_EXTRAS"
    ${ARGN})

  set(${PROJECT_NAME}_CATKIN_RUN_DEPENDS)
  foreach(dep ${${PROJECT_NAME}_RUN_DEPENDS})
    find_package(${dep} QUIET)
    if(${dep}_FOUND_CATKIN_PROJECT)
      list(APPEND ${PROJECT_NAME}_CATKIN_RUN_DEPENDS ${dep})
    endif()
  endforeach()

  catkin_package(
    INCLUDE_DIRS ${${PROJECT_NAME}_LOCAL_INCLUDE_DIR} ${CS_PROJECT_INCLUDE_DIRS}
    LIBRARIES ${${PROJECT_NAME}_LIBRARIES} ${CS_PROJECT_LIBRARIES}
    CATKIN_DEPENDS ${${PROJECT_NAME}_CATKIN_RUN_DEPENDS} ${CS_PROJECT_CATKIN_DEPENDS}
    DEPENDS ${CS_PROJECT_DEPENDS}
    CFG_EXTRAS ${CS_PROJECT_CFG_EXTRAS}
  )
endmacro()

  cs_export(INCLUDE_DIRS ${CATKIN_DEVEL_PREFIX}/include
          LIBRARIES CppUnitLite gtsam gtsam_unstable metis-gtsam tbb)
  
#   if(${MAKE_LOCAL_INSTALL})
#     message("${BoldMagenta}INFO: Making a local install.${ColourReset}")
#   	add_custom_command (OUTPUT run_install_script___OK 
#                         COMMAND ${CMAKE_SOURCE_DIR}/local_install.sh "${CMAKE_SOURCE_DIR}"
#                         WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/)         
#   	add_custom_target(
#   	  RunInstallScript ALL
#   	  DEPENDS run_install_script___OK)
#   endif()

endif()