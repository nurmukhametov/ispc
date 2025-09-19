CC = clang
CFLAGS = -O3 -march=native -Wall -Wextra
LDFLAGS = -lrt
PROFILE_FLAGS = -gline-tables-only -fdebug-info-for-profiling -funique-internal-linkage-names

HEADERS = utils.h
TARGET = hwpgo_demo

.PHONY: all clean test baseline profile hwpgo benchmark help asm compare-asm

all: baseline

# Baseline version (no profiling)
baseline: $(TARGET)_baseline

$(TARGET)_baseline: main.c utils.c $(HEADERS)
	$(CC) $(CFLAGS) -o $@ main.c utils.c $(LDFLAGS)

# Profile collection step
profile: $(TARGET)_profile perf.data

$(TARGET)_profile: main.c utils.c $(HEADERS)
	$(CC) $(CFLAGS) $(PROFILE_FLAGS) -o $@ main.c utils.c $(LDFLAGS)

perf.data: $(TARGET)_profile
	@echo "Running profile collection..."
	perf record -b -e cycles:u ./$(TARGET)_profile || perf record -e task-clock:u ./$(TARGET)_profile

# Convert profile data
profile.prof: perf.data $(TARGET)_profile
	@echo "Converting profile to LLVM format..."
	@if llvm-profgen --binary=./$(TARGET)_profile --output=profile.prof --perfdata=perf.data 2>/dev/null; then \
		echo "Profile converted successfully with llvm-profgen"; \
	elif create_llvm_prof --binary=./$(TARGET)_profile --out=profile.prof 2>/dev/null; then \
		echo "Profile converted successfully with create_llvm_prof"; \
	else \
		echo "Warning: Cannot convert profile automatically."; \
		echo "Available options:"; \
		echo "1. Install AutoFDO: https://github.com/google/autofdo"; \
		echo "2. Use newer LLVM with better AMD support"; \
		echo "3. Create dummy profile for testing:"; \
		echo "   echo 'main:1000:0' > profile.prof"; \
		echo "Creating dummy profile for demonstration..."; \
		echo 'main:1000:0' > profile.prof; \
		echo ' 1: 500' >> profile.prof; \
		echo ' 2: 300' >> profile.prof; \
		echo ' 3: 200' >> profile.prof; \
		echo "Dummy profile created - not real data but allows HWPGO testing"; \
	fi

# HWPGO version (with actual profile optimization)
hwpgo: profile.prof $(TARGET)_hwpgo

$(TARGET)_hwpgo: main.c utils.c $(HEADERS) profile.prof
	$(CC) $(CFLAGS) -fprofile-sample-use=profile.prof -o $@ main.c utils.c $(LDFLAGS)

# Test both versions
test: baseline hwpgo
	@echo "=== Testing Baseline Version ==="
	./$(TARGET)_baseline
	@echo ""
	@echo "=== Testing HWPGO Optimized Version ==="
	./$(TARGET)_hwpgo

# Performance benchmark
benchmark: baseline hwpgo
	@echo "=== Performance Benchmark ==="
	@echo "Baseline version (3 runs):"
	@time ./$(TARGET)_baseline > /dev/null
	@time ./$(TARGET)_baseline > /dev/null
	@time ./$(TARGET)_baseline > /dev/null
	@echo ""
	@echo "HWPGO version (3 runs):"
	@time ./$(TARGET)_hwpgo > /dev/null
	@time ./$(TARGET)_hwpgo > /dev/null
	@time ./$(TARGET)_hwpgo > /dev/null

# Complete workflow
complete: clean profile hwpgo test

# Assembly generation and comparison
asm: $(TARGET)_baseline.s $(TARGET)_hwpgo.s

$(TARGET)_baseline.s: main.c utils.c $(HEADERS)
	$(CC) $(CFLAGS) -S -masm=intel -o $@ main.c -DMAIN_ONLY
	@echo "Generated baseline assembly (Intel syntax): $(TARGET)_baseline.s"

$(TARGET)_hwpgo.s: main.c utils.c $(HEADERS) profile.prof
	$(CC) $(CFLAGS) -fprofile-sample-use=profile.prof -S -masm=intel -o $@ main.c -DMAIN_ONLY
	@echo "Generated HWPGO assembly (Intel syntax): $(TARGET)_hwpgo.s"

# Compare assembly of key functions
compare-asm: asm
	@echo "=== Assembly Comparison for Key Functions ==="
	@echo ""
	@echo "=== process_biased_branches function ==="
	@echo "--- Baseline version ---"
	@grep -A 50 "process_biased_branches:" $(TARGET)_baseline.s | head -50 || echo "Function not found in baseline"
	@echo ""
	@echo "--- HWPGO version ---"
	@grep -A 50 "process_biased_branches:" $(TARGET)_hwpgo.s | head -50 || echo "Function not found in HWPGO"
	@echo ""
	@echo "=== cheap_hot_function (should be inlined in HWPGO) ==="
	@echo "--- Baseline version ---"
	@grep -A 10 "cheap_hot_function:" $(TARGET)_baseline.s || echo "Function inlined or not found"
	@echo ""
	@echo "--- HWPGO version ---"
	@grep -A 10 "cheap_hot_function:" $(TARGET)_hwpgo.s || echo "Function inlined or not found"
	@echo ""
	@echo "=== Branch instruction analysis ==="
	@echo "Baseline conditional jumps:"
	@grep -c "\bj[a-z]*\b" $(TARGET)_baseline.s || echo "0"
	@echo "HWPGO conditional jumps:"
	@grep -c "\bj[a-z]*\b" $(TARGET)_hwpgo.s || echo "0"
	@echo "Baseline CMOV instructions:"
	@grep -c "\bcmov[a-z]*\b" $(TARGET)_baseline.s || echo "0"
	@echo "HWPGO CMOV instructions:"
	@grep -c "\bcmov[a-z]*\b" $(TARGET)_hwpgo.s || echo "0"
	@echo ""
	@echo "Use 'make asm-diff' for detailed side-by-side comparison"

# Detailed side-by-side diff of assembly
asm-diff: asm
	@echo "=== Detailed Assembly Diff ==="
	@echo "Key function differences (process_biased_branches):"
	@echo ""
	@# Extract just the key function for comparison
	@grep -A 100 "process_biased_branches:" $(TARGET)_baseline.s | head -100 > baseline_func.s 2>/dev/null || echo "baseline function not found"
	@grep -A 100 "process_biased_branches:" $(TARGET)_hwpgo.s | head -100 > hwpgo_func.s 2>/dev/null || echo "hwpgo function not found"
	@if [ -f baseline_func.s ] && [ -f hwpgo_func.s ]; then \
		echo "Side-by-side comparison:"; \
		diff -y --width=120 baseline_func.s hwpgo_func.s || true; \
	else \
		echo "Could not extract functions for comparison"; \
	fi
	@rm -f baseline_func.s hwpgo_func.s

clean:
	rm -f $(TARGET)_baseline $(TARGET)_profile $(TARGET)_hwpgo
	rm -f $(TARGET)_baseline.s $(TARGET)_hwpgo.s
	rm -f perf.data* profile.prof
	rm -f main_profile.o utils_profile.o main_regular_debug.o
	rm -f baseline_func.s hwpgo_func.s

help:
	@echo "HWPGO Demo Makefile"
	@echo "=================="
	@echo "Targets:"
	@echo "  baseline     - Build baseline version (no optimization)"
	@echo "  profile      - Build instrumented version and collect profile"
	@echo "  hwpgo        - Build HWPGO optimized version"
	@echo "  test         - Run both versions and compare output"
	@echo "  benchmark    - Time both versions for performance comparison"
	@echo "  complete     - Full workflow: clean -> profile -> hwpgo -> test"
	@echo "  asm          - Generate assembly for both baseline and HWPGO"
	@echo "  compare-asm  - Compare assembly of key functions"
	@echo "  asm-diff     - Detailed side-by-side assembly diff"
	@echo "  clean        - Remove all generated files"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Usage examples:"
	@echo "  make complete        # Full HWPGO workflow"
	@echo "  make baseline test   # Just test baseline"
	@echo "  make benchmark       # Performance comparison"
	@echo "  make compare-asm     # See HWPGO assembly optimizations"