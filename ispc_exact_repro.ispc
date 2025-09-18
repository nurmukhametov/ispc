// Exact reproduction of the MoonRay testLightIntersection pattern
// This matches the structure that was failing in the actual tests

export uniform bool foo(uniform float scl, uniform uint32 &isectsEqual) {
    uniform bool success = true;
    uint32 localIsectsEqual = 0;

    for (uniform uint32 y = 0; y < 2; y++) {
        float testValue = (float)y * scl;

        bool passed = true;
        bool asserted = false;

        if (!asserted) {
            if (testValue > 1.0f) {
                passed = false;
                if (testValue > 0.1f) {
                    asserted = true;
                }
            }
        }

        if (asserted) {
            success = false;
        }

        localIsectsEqual += passed ? 1 : 0;
    }

    isectsEqual = reduce_add(localIsectsEqual);

    return success;
}
