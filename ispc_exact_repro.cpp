#include <iostream>
#include "ispc_exact_repro_ispc_stubs.h"

inline bool asCppBool(bool ispcBool) {
    int i = ispcBool ? 1 : 0;
    return (bool)i;
}

int main() {
    float scl = 0.001f;
    uint32_t isectsEqual = 0;
    
    bool rawResult = ispc::foo(scl, isectsEqual);
    
    bool convertedResult = asCppBool(rawResult);
    
    std::cout << "Raw ISPC result: " << (int)rawResult << " (as int)" << std::endl;
    std::cout << "Raw ISPC result: " << rawResult << " (as bool)" << std::endl;
    std::cout << "asCppBool result: " << (int)convertedResult << " (as int)" << std::endl;
    std::cout << "asCppBool result: " << convertedResult << " (as bool)" << std::endl;
    
    return 0;
}
