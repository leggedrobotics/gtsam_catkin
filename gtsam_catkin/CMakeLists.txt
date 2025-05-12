cmake_minimum_required(VERSION 3.16)
project(gtsam_catkin)

find_package(catkin REQUIRED)

set(CATKIN_PACKAGE_DEPENDENCIES
        )

find_package(catkin REQUIRED COMPONENTS
        ${CATKIN_PACKAGE_DEPENDENCIES}
        )

# Check whether gtsam can be found
set(GTSAM_MIN_VERSION 4.2.0)
set(GTSAM_TAG ${GTSAM_MIN_VERSION})
find_package(GTSAM ${GTSAM_MIN_VERSION} QUIET)
find_package(Eigen3 REQUIRED)

# Color
if (NOT WIN32)
    string(ASCII 27 Esc)
    set(ColourReset "${Esc}[m")
    set(BoldMagenta "${Esc}[1;35m")
    set(Magenta "${Esc}[35m")
endif ()

# Code snippet taken from catkin_simple: https://github.com/catkin/catkin_simple/blob/master/cmake/catkin_simple-extras.cmake.em
macro(get_run_deps)
    cmake_parse_arguments(CS_PROJECT
            "" "" "INCLUDE_DIRS;LIBRARIES;CATKIN_DEPENDS;DEPENDS;CFG_EXTRAS"
            ${ARGN})

    set(${PROJECT_NAME}_CATKIN_RUN_DEPENDS)
    foreach (dep ${${PROJECT_NAME}_RUN_DEPENDS})
        find_package(${dep} QUIET)
        if (${dep}_FOUND_CATKIN_PROJECT)
            list(APPEND ${PROJECT_NAME}_CATKIN_RUN_DEPENDS ${dep})
        endif ()
    endforeach ()
endmacro()

get_run_deps(INCLUDE_DIRS ${CATKIN_DEVEL_PREFIX}/include LIBRARIES tbb)

# 1 - Check whether variable is set -----------------------------------------------------------
if (DEFINED ENV{GTSAM_DIR})
    message("${BoldMagenta}INFO: Found GTSAM via environment variable at $ENV{GTSAM_DIR}.${ColourReset}")

    set(GTSAM_DIR ENV{GTSAM_DIR})
    find_package(GTSAM ${GTSAM_MIN_VERSION} CONFIG REQUIRED)
    message("GTSAM include path: ${GTSAM_INCLUDE_DIR}")
    message("GTSAM libs: ${GTSAM_LIBRARY_DIR}")

    catkin_package(
        INCLUDE_DIRS
            ${GTSAM_INCLUDE_DIR}
        LIBRARIES
            gtsam
            gtsam_unstable
            metis-gtsam
            ${CS_PROJECT_LIBRARIES}
        CATKIN_DEPENDS
            ${CATKIN_PACKAGE_DEPENDENCIES}
            ${${PROJECT_NAME}_CATKIN_RUN_DEPENDS}
        DEPENDS GTSAM
    )
# 2 - Check whether GTSAM is installed -------------------------------------------------------
elseif (GTSAM_FOUND)
    message("${BoldMagenta}INFO: Found GTSAM installation at ${GTSAM_DIR}.${ColourReset}")

    find_package(GTSAM_UNSTABLE REQUIRED)

    catkin_package(
        INCLUDE_DIRS
            ${GTSAM_INCLUDE_DIR}
        LIBRARIES
            gtsam
            gtsam_unstable
            metis-gtsam
            ${CS_PROJECT_LIBRARIES}
        CATKIN_DEPENDS
            ${CATKIN_PACKAGE_DEPENDENCIES}
            ${${PROJECT_NAME}_CATKIN_RUN_DEPENDS}
        DEPENDS GTSAM
    )
# 3 - Compile in catkin workspace -------------------------------------------------------------
else ()
    message("${BoldMagenta}INFO: Neither variable GTSAM_DIR is set, nor could GTSAM be found, hence compiling in workspace.${ColourReset}")

    # Catkinization of GTSAM
    include(ExternalProject)
    file(MAKE_DIRECTORY ${CATKIN_DEVEL_PREFIX}/include)

    ExternalProject_Add(GTSAM
        GIT_REPOSITORY "https://github.com/borglab/gtsam.git"
        GIT_TAG "${GTSAM_TAG}"
        GIT_PROGRESS "true"
        PREFIX      "${CMAKE_SOURCE_DIR}"
        TMP_DIR     "${CMAKE_BINARY_DIR}/gtsam/tmp"
        BINARY_DIR  "${CMAKE_BINARY_DIR}/gtsam/build"
        INSTALL_DIR "${CATKIN_DEVEL_PREFIX}"
        CMAKE_CACHE_ARGS "-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"
        CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=Release
            -DGTSAM_POSE3_EXPMAP=ON
            -DGTSAM_ROT3_EXPMAP=ON
            -DGTSAM_USE_QUATERNIONS=ON
            -DGTSAM_USE_SYSTEM_EIGEN=ON
            -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF
            -DCMAKE_INSTALL_PREFIX=${CATKIN_DEVEL_PREFIX}
    )

    # Dependencies ---------------------------------------------------------
    add_dependencies(GTSAM ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS})

    #############
    ## INSTALL ##
    #############

    install(DIRECTORY ${CATKIN_DEVEL_PREFIX}/include/
            DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION}
            )

    install(DIRECTORY ${CATKIN_DEVEL_PREFIX}/lib/
            DESTINATION ${CATKIN_GLOBAL_LIB_DESTINATION}
            )

    # Final catkin package --------------------------------------------------
    catkin_package(
        INCLUDE_DIRS
            ${CATKIN_DEVEL_PREFIX}/include
        LIBRARIES
            ${CATKIN_DEVEL_PREFIX}/lib/libgtsam.so
            ${CATKIN_DEVEL_PREFIX}/lib/libgtsam_unstable.so
            ${CATKIN_DEVEL_PREFIX}/lib/libmetis-gtsam.so
            ${CS_PROJECT_LIBRARIES}
        CATKIN_DEPENDS
            ${${PROJECT_NAME}_CATKIN_RUN_DEPENDS}
            ${CATKIN_PACKAGE_DEPENDENCIES}
    )

endif ()
