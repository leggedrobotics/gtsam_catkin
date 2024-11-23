# Eigen alignment
set(EIGEN_ALIGNMENT_FLAGS "-DEIGEN_DONT_ALIGN")
add_compile_options(${EIGEN_ALIGNMENT_FLAGS})
# Build type
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native" CACHE STRING "" FORCE)