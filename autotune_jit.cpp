#include <iostream>
#include <vector>
#include <chrono>
#include <numeric>
#include <random>
#include "ispc/ispc.h"

using namespace std;
using namespace chrono;

// Function pointer type for the dot product kernel
typedef void (*DotProductFunc)(float*, float*, float*, int);

double benchmarkKernel(DotProductFunc func, const vector<float>& a, const vector<float>& b, 
                      int programCount, int iterations = 100) {
    int n = a.size();
    vector<float> partial_results(programCount);
    
    auto start = high_resolution_clock::now();
    
    for (int iter = 0; iter < iterations; iter++) {
        func(const_cast<float*>(a.data()), const_cast<float*>(b.data()), 
             partial_results.data(), n);
        
        // Reduce partial results
        float result = 0.0f;
        for (int i = 0; i < programCount; i++) {
            result += partial_results[i];
        }
    }
    
    auto end = high_resolution_clock::now();
    auto duration = duration_cast<microseconds>(end - start);
    
    return duration.count() / double(iterations);
}

int main() {
    const int N = 1000000;
    
    // Initialize test data
    vector<float> a(N), b(N);
    random_device rd;
    mt19937 gen(rd());
    uniform_real_distribution<float> dis(0.0f, 1.0f);
    
    for (int i = 0; i < N; i++) {
        a[i] = dis(gen);
        b[i] = dis(gen);
    }
    
    cout << "ISPC JIT Autotuning Benchmark\n";
    cout << "Vector size: " << N << "\n\n";
    
    // Parameter combinations to test
    vector<int> blockSizes = {256, 512, 1024, 2048, 4096};
    vector<int> unrollFactors = {2, 4, 8};
    
    double bestTime = 1e9;
    int bestBlock = 0, bestUnroll = 0;
    
    for (int blockSize : blockSizes) {
        for (int unrollFactor : unrollFactors) {
            cout << "Testing BLOCK_SIZE=" << blockSize 
                 << ", UNROLL_FACTOR=" << unrollFactor << "... ";
            cout.flush();
            
            // Create ISPC engine with defines for current parameters
            vector<string> args = {
                "--target=avx2-i32x8",
                "-DBLOCK_SIZE=" + to_string(blockSize),
                "-DUNROLL_FACTOR=" + to_string(unrollFactor)
            };

            if (!ispc::Initialize()) {
                cerr << "Failed to initialize ISPC library" << endl;
                return 1;
            }

            {
                auto engine = ispc::ISPCEngine::CreateFromArgs(args);

                if (!engine) {
                    cout << "Failed to create ISPC engine\n";
                    continue;
                }

                // Compile to JIT
                if (engine->CompileFromFileToJit("autotune_dotproduct.ispc") != 0) {
                    cout << "Compilation failed\n";
                    continue;
                }

                // Get function pointer
                auto func = (DotProductFunc)engine->GetJitFunction("dot_product");
                if (!func) {
                    cout << "Failed to get function pointer\n";
                    continue;
                }

                // Warmup
                benchmarkKernel(func, a, b, 8, 5);

                // Benchmark
                double avgTime = benchmarkKernel(func, a, b, 8, 50);
                double gflops = (N * 2.0 / avgTime) / 1000.0;

                cout << avgTime << " μs, " << gflops << " GFLOPS";

                if (avgTime < bestTime) {
                    bestTime = avgTime;
                    bestBlock = blockSize;
                    bestUnroll = unrollFactor;
                    cout << " (BEST)";
                }

                cout << "\n";

                engine->ClearJitCode();
            }

            ispc::Shutdown();
        }
    }
    
    cout << "\nBest configuration:\n";
    cout << "BLOCK_SIZE=" << bestBlock << ", UNROLL_FACTOR=" << bestUnroll << "\n";
    cout << "Best time: " << bestTime << " μs\n";
    cout << "Best throughput: " << (N * 2.0 / bestTime) / 1000.0 << " GFLOPS\n";
    
    return 0;
}
