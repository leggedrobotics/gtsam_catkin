cmake_minimum_required(VERSION 3.16)
project(gtsam_catkin)

option(GTSAM_CATKIN_FORCE_LOCAL_GTSAM
        "Force building GTSAM in the catkin workspace instead of using an existing installation"
        OFF)

find_package(catkin REQUIRED)

set(CATKIN_PACKAGE_DEPENDENCIES
        )

find_package(catkin REQUIRED COMPONENTS
        ${CATKIN_PACKAGE_DEPENDENCIES}
        )

# Check whether gtsam can be found unless local workspace build is forced
if (NOT GTSAM_CATKIN_FORCE_LOCAL_GTSAM)
    find_package(GTSAM QUIET)
endif ()

find_package(Eigen3 REQUIRED)

# Color
if (NOT WIN32)
    string(ASCII 27 Esc)
    set(ColourReset "${Esc}[m")
    set(BoldMagenta "${Esc}[1;35m")
    set(Magenta "${Esc}[35m")
endif ()

macro(resolve_gtsam_install_paths)
    if (NOT GTSAM_DIR)
        message(FATAL_ERROR "GTSAM_DIR is not set, cannot resolve GTSAM install paths.")
    endif ()

    get_filename_component(_GTSAM_CONFIG_DIR "${GTSAM_DIR}" ABSOLUTE)
    get_filename_component(_GTSAM_INSTALL_PREFIX "${_GTSAM_CONFIG_DIR}/../../.." ABSOLUTE)

    if (NOT GTSAM_INCLUDE_DIR OR NOT EXISTS "${GTSAM_INCLUDE_DIR}/gtsam")
        set(GTSAM_INCLUDE_DIR "${_GTSAM_INSTALL_PREFIX}/include")
    endif ()

    if (NOT GTSAM_LIBRARY_DIR OR NOT EXISTS "${GTSAM_LIBRARY_DIR}/libgtsam.so")
        set(GTSAM_LIBRARY_DIR "${_GTSAM_INSTALL_PREFIX}/lib")
    endif ()

    if (NOT EXISTS "${GTSAM_LIBRARY_DIR}/libgtsam.so")
        message(FATAL_ERROR "Could not find libgtsam.so under ${GTSAM_LIBRARY_DIR}.")
    endif ()

    if (NOT EXISTS "${GTSAM_LIBRARY_DIR}/libgtsam_unstable.so")
        message(FATAL_ERROR "Could not find libgtsam_unstable.so under ${GTSAM_LIBRARY_DIR}.")
    endif ()
endmacro()

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

get_run_deps(INCLUDE_DIRS ${CATKIN_DEVEL_PREFIX}/include
        LIBRARIES tbb
        )

set(USE_LOCAL_GTSAM FALSE)

# Select GTSAM source -------------------------------------------------------------------------
if (GTSAM_CATKIN_FORCE_LOCAL_GTSAM)
    set(USE_LOCAL_GTSAM TRUE)
    set(GTSAM_LOCAL_BUILD_REASON
            "GTSAM_CATKIN_FORCE_LOCAL_GTSAM is enabled, hence compiling GTSAM in workspace.")
elseif (DEFINED ENV{GTSAM_DIR})
    message("${BoldMagenta}INFO: Found manually set path to GTSAM. Using version located at $ENV{GTSAM_DIR}.${ColourReset}")

    set(GTSAM_DIR "$ENV{GTSAM_DIR}")
    find_package(GTSAM CONFIG REQUIRED)
    resolve_gtsam_install_paths()
    message("GTSAM include path: ${GTSAM_INCLUDE_DIR}")
    message("GTSAM libs: ${GTSAM_LIBRARY_DIR}")

    catkin_package(
            CATKIN_DEPENDS ${CATKIN_PACKAGE_DEPENDENCIES}
            DEPENDS GTSAM
            INCLUDE_DIRS ${GTSAM_INCLUDE_DIR}
            LIBRARIES
            ${GTSAM_LIBRARY_DIR}/libgtsam.so
            ${GTSAM_LIBRARY_DIR}/libgtsam_unstable.so
            ${CS_PROJECT_LIBRARIES}
    )

    # 2 - Check whether GTSAM is installed ------------------------------------------------------
elseif (GTSAM_FOUND)
    message("${BoldMagenta}INFO: Found GTSAM installation.${ColourReset}")

    resolve_gtsam_install_paths()
    message("GTSAM include path: ${GTSAM_INCLUDE_DIR}")
    message("GTSAM libs: ${GTSAM_LIBRARY_DIR}")

    catkin_package(
            CATKIN_DEPENDS ${CATKIN_PACKAGE_DEPENDENCIES}
            DEPENDS GTSAM
            INCLUDE_DIRS ${GTSAM_INCLUDE_DIR}
            LIBRARIES
            ${GTSAM_LIBRARY_DIR}/libgtsam.so
            ${GTSAM_LIBRARY_DIR}/libgtsam_unstable.so
            ${CS_PROJECT_LIBRARIES}
    )

    # Path differs whether installed from PPA or (locally) from source
#    if (EXISTS "${GTSAM_DIR}/../../../../include/")
#        set(GTSAM_INCLUDE_DIR_MAN "${GTSAM_DIR}/../../../../include/")
#    else ()
#        set(GTSAM_INCLUDE_DIR_MAN "${GTSAM_DIR}/../../../include/")
#    endif ()

    # 3 - Compile in catkin workspace ------------------------------------------------------------
else ()
    set(USE_LOCAL_GTSAM TRUE)
    set(GTSAM_LOCAL_BUILD_REASON
            "Neither variable GTSAM_DIR is set, nor could GTSAM be found, hence compiling in workspace.")

endif ()

if (USE_LOCAL_GTSAM)
    message("${BoldMagenta}INFO: ${GTSAM_LOCAL_BUILD_REASON}${ColourReset}")

    # Newer version of CMake is required
    # cmake_minimum_required(VERSION 3.18)

    # Catkinization of GTSAM
    include(ExternalProject)
    file(MAKE_DIRECTORY ${CATKIN_DEVEL_PREFIX}/include)

    set(GTSAM_VERSION "6ec49ac5de01fe5cf384069ac8d40cfebef40147")

    ExternalProject_Add(GTSAM
            GIT_REPOSITORY "https://github.com/borglab/gtsam.git"
            # ExternalProject_Add uses GIT_TAG for tags, branches, or commit hashes.
            GIT_TAG "${GTSAM_VERSION}"
            GIT_PROGRESS "true"
            CMAKE_CACHE_ARGS "-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true"
            PREFIX "${CMAKE_BINARY_DIR}/gtsam_external"
            SOURCE_DIR "${CMAKE_BINARY_DIR}/gtsam_external/src/gtsam"
            BINARY_DIR "${CMAKE_BINARY_DIR}/gtsam_external/build"
            CMAKE_ARGS
            -DCMAKE_BUILD_TYPE=Release
            -DGTSAM_POSE3_EXPMAP=ON
            -DGTSAM_ROT3_EXPMAP=ON
            -DGTSAM_USE_QUATERNIONS=ON
            -DGTSAM_USE_SYSTEM_EIGEN=ON
            -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF
            -DCMAKE_INSTALL_PREFIX=${CATKIN_DEVEL_PREFIX}
            -DGTSAM_WITH_TBB=OFF
            INSTALL_COMMAND make install
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
