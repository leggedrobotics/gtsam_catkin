# GTSAM Catkin

This package is a catkin wrapper around GTSAM.

*Contact:* Julian Nubert (nubertj@ethz.ch), Turcan Tuna (tutuna@ethz.ch)

## 1 - Overview

If no GTSAM installation is present on the system, *GTSAM_catkin* is built by compiling the gtsam libraries within the catkin workspace. On a modern desktop computer this takes about 3 minutes. 
If a GTSAM installation exists on the system, this is used instead and wrapped as a catkin package automatically. The latter can be particularly useful if multiple workspaces with these packages are compiled on the computer, or *GTSAM_catkin* is intended for longer-term usage. 

The places it will look for for GTSAM are 
* `~/.local/` and 
* `/usr/local`

If it does not find any GTSAM installation at these two places, it will automatically pull the raw files from GitHub and build it from source in your catkin workspace.

For an example on how to build GTSAM (locally) on your system, refer to [this link](https://github.com/leggedrobotics/graph_msf/blob/main/doc/installation.md).

## 2 - Automatic Compilation of GTSAM in Workspace

### 2.0 - Requirements
No additional requirements known at this point.

## 2.1 - GTSAM_catkin Compilation
Compilation of *GTSAM_catkin* is really straightforward.
Make sure you have a catkin workspace with this repository:
```bash
git clone https://github.com/leggedrobotics/GTSAM_catkin.git
```
Then you can build the package in release mode.
```bash
catkin build GTSAM_catkin -DCMAKE_BUILD_TYPE=Release
```
As introduced before, the 3 compilation options are chosen automatically in the following order:
1. GTSAM is installed locally and the `$GTSAM_DIR` environment variable is pointing to the installation location. The success of this is indicated through the message *INFO: Found manually set path to GTSAM. Using version located at (some user-specified location)*.
   * This can e.g. be done by setting `export GTSAM_DIR=/home/nubertj/.local/lib/cmake/GTSAM/`.
2. GTSAM is installed globally.
Both of these options should compile within a few seconds.
3. If none of the before cases holds, GTSAM is automatically pulled locally and compiled inside the workspace.

## 3 - Usage of GTSAM_catkin in your project
Usage in your catkin project is then straightforward.

### CMakeLists.txt
```cmake
set(CATKIN_PACKAGE_DEPENDENCIES
  GTSAM_catkin
)
...
find_package(catkin REQUIRED COMPONENTS
  ${CATKIN_PACKAGE_DEPENDENCIES}
)
...

catkin_package(
  ...
  CATKIN_DEPENDS
    ${CATKIN_PACKAGE_DEPENDENCIES}
  DEPENDS 
)
...
include_directories(
  ${catkin_INCLUDE_DIRS}
  ...
)
...
target_link_libraries(${PROJECT_NAME}
  ${catkin_LIBRARIES}
  ...
)

```

An example of this can be seen in [./gtsam_catkin_example_project/CMakeLists.txt](https://github.com/leggedrobotics/gtsam_catkin/blob/main/gtsam_catkin_example_project/CMakeLists.txt).

You can also build it by running:
```bash
catkin build GTSAM_catkin_example_project
```

### Code Usage
Headers from gtsam, gtsam_unstable, etc., can then be included as usual:
```cpp
#include <gtsam/...>
```