CC = clang
CFLAGS = -O3 -march=native -Wall -Wextra
LDFLAGS = -lrt
PROFILE_FLAGS = -gline-tables-only -fdebug-info-for-profiling -funique-internal-linkage-names

HEADERS = utils.h
TARGET = hwpgo_demo

.PHONY: all clean test baseline profile hwpgo benchmark help

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

clean:
	rm -f $(TARGET)_baseline $(TARGET)_profile $(TARGET)_hwpgo
	rm -f perf.data* profile.prof
	rm -f main_profile.o utils_profile.o main_regular_debug.o

help:
	@echo "HWPGO Demo Makefile"
	@echo "=================="
	@echo "Targets:"
	@echo "  baseline   - Build baseline version (no optimization)"
	@echo "  profile    - Build instrumented version and collect profile"
	@echo "  hwpgo      - Build HWPGO optimized version"
	@echo "  test       - Run both versions and compare output"
	@echo "  benchmark  - Time both versions for performance comparison"
	@echo "  complete   - Full workflow: clean -> profile -> hwpgo -> test"
	@echo "  clean      - Remove all generated files"
	@echo "  help       - Show this help"
	@echo ""
	@echo "Usage examples:"
	@echo "  make complete        # Full HWPGO workflow"
	@echo "  make baseline test   # Just test baseline"
	@echo "  make benchmark       # Performance comparison"