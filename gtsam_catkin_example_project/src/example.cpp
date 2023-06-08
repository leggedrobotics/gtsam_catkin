#include "gtsam/navigation/CombinedImuFactor.h"

int main(int argc, char** argv) {
  // Create a factor
  gtsam::CombinedImuFactor factor;

  std::cout << "Successfully instantiated a factor!" << std::endl;

  return 0;
}