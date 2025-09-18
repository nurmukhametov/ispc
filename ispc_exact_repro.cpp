// Exact reproduction of the MoonRay boolean conversion issue
#include <iostream>
#include <cstdint>
#include "ispc_exact_repro_ispc_stubs.h"

// Original asCppBool from MoonRay
inline bool asCppBool(bool ispcBool) {
    int i = ispcBool ? 1 : 0;
    return (bool)i;
}

int main() {
    std::cout << "=== Exact MoonRay Pattern Reproduction ===" << std::endl;
    
    // Set up the same parameters as the failing tests
    ispc::Vec3f p = {0.1f, -2.0f, 0.3f};
    ispc::Range2d range = {0, 2, 0, 4};  // Small range for testing
    float scl = 0.001f;
    float ofs = 0.0f;
    uint32_t isectsEqual = 0;
    uint32_t noIntersection = 0;
    uint32_t invalidSamples = 0;
    
    std::cout << "Calling testLightIntersectionPattern..." << std::endl;
    
    // This should reproduce the exact same call pattern as MoonRay
    bool rawResult = ispc::testLightIntersectionPattern(
        4,  // isectDataFieldsUsed
        p,
        range,
        scl,
        ofs,
        isectsEqual,
        noIntersection,
        invalidSamples
    );
    
    bool convertedResult = asCppBool(rawResult);
    
    std::cout << "Raw ISPC result: " << (int)rawResult << " (as int)" << std::endl;
    std::cout << "Raw ISPC result: " << rawResult << " (as bool)" << std::endl;
    std::cout << "asCppBool result: " << (int)convertedResult << " (as int)" << std::endl;
    std::cout << "asCppBool result: " << convertedResult << " (as bool)" << std::endl;
    
    return 0;
}
