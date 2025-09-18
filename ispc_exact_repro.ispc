// Exact reproduction of the MoonRay testLightIntersection pattern
// This matches the structure that was failing in the actual tests

struct Vec3f {
    float x, y, z;
};

struct Range2d {
    uint32 mRowBegin;
    uint32 mRowEnd;
    uint32 mColBegin;  
    uint32 mColEnd;
};

// Simulate the exact pattern from testLightIntersection
export uniform bool testLightIntersectionPattern(
    uniform uint32 isectDataFieldsUsed,
    const uniform Vec3f &p,
    const uniform Range2d &range,
    uniform float scl, 
    uniform float ofs,
    uniform uint32 &isectsEqual,
    uniform uint32 &noIntersection,
    uniform uint32 &invalidSamples)
{
    // print("ISPC: testLightIntersectionPattern called\n");
    
    uniform bool success = true;
    
    uint32 localIsectsEqual = 0;
    uint32 localNoIntersection = 0;
    uint32 localInvalidSamples = 0;

    // Simulate the nested loop pattern from the original
    for (uniform uint32 y = range.mRowBegin; y < range.mRowEnd; y++) {
        foreach (x = range.mColBegin ... range.mColEnd) {
            varying Vec3f r;
            r.x = (float)y * scl + ofs;
            r.y = (float)x * scl + ofs;
            r.z = 0.0f;
            
            // Simulate some intersection calculations that could fail
            bool passed = true;
            bool asserted = false;
            
            // Simulate the tolerance checks that were failing
            if (!asserted) {
                // This simulates the pattern that was causing failures
                float testValue = r.x + r.y;
                float refValue = testValue + 0.001f; // Small difference
                
                if (!asserted && abs(testValue - refValue) > 0.001f) {
                    passed = false;
                    if (abs(testValue - refValue) > 0.01f) {
                        print("ISPC: Simulated intersection mismatch detected!\n");
                        asserted = true;
                    }
                }
            }
            
            if (asserted) {
                success = false;
            }
            
            localIsectsEqual += passed ? 1 : 0;
        }
    }
    
    isectsEqual = reduce_add(localIsectsEqual);
    noIntersection = reduce_add(localNoIntersection);
    invalidSamples = reduce_add(localInvalidSamples);
    
    if (success) {
        print("ISPC: testLightIntersectionPattern returning TRUE\n");
    } else {
        print("ISPC: testLightIntersectionPattern returning FALSE\n");
    }
    
    return success;
}

