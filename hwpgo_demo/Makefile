CC = clang
CFLAGS = -O3 -march=native -Wall -Wextra
LDFLAGS = -lrt

SOURCES = main.c utils.c
HEADERS = utils.h
TARGET = hwpgo_demo

.PHONY: all clean profile hwpgo baseline test

all: baseline

baseline: $(TARGET)_baseline

$(TARGET)_baseline: $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -o $@ $(SOURCES) $(LDFLAGS)

profile: $(TARGET)_profile
	@echo "Running profile collection..."
	perf record -b -e cycles:u ./$(TARGET)_profile
	@echo "Converting profile to LLVM format..."
	llvm-profgen --binary=./$(TARGET)_profile --output=profile.prof --perfdata=perf.data

$(TARGET)_profile: $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -gline-tables-only -fdebug-info-for-profiling -funique-internal-linkage-names -o $@ $(SOURCES) $(LDFLAGS)

hwpgo: profile $(TARGET)_hwpgo

$(TARGET)_hwpgo: $(SOURCES) $(HEADERS) profile.prof
	$(CC) $(CFLAGS) -fprofile-sample-use=profile.prof -o $@ $(SOURCES) $(LDFLAGS)

test: baseline hwpgo
	@echo "=== Testing Baseline Version ==="
	./$(TARGET)_baseline
	@echo ""
	@echo "=== Testing HWPGO Version ==="
	./$(TARGET)_hwpgo
	@echo ""
	@echo "=== Performance Comparison ==="
	@echo "Run 'make benchmark' for detailed timing comparison"

benchmark: baseline hwpgo
	@echo "Benchmarking baseline version (3 runs)..."
	@time ./$(TARGET)_baseline > /dev/null
	@time ./$(TARGET)_baseline > /dev/null  
	@time ./$(TARGET)_baseline > /dev/null
	@echo ""
	@echo "Benchmarking HWPGO version (3 runs)..."
	@time ./$(TARGET)_hwpgo > /dev/null
	@time ./$(TARGET)_hwpgo > /dev/null
	@time ./$(TARGET)_hwpgo > /dev/null

clean:
	rm -f $(TARGET)_baseline $(TARGET)_profile $(TARGET)_hwpgo
	rm -f perf.data* profile.prof

help:
	@echo "Available targets:"
	@echo "  baseline  - Build without HWPGO (default)"
	@echo "  profile   - Build instrumented version and collect profile"
	@echo "  hwpgo     - Build with HWPGO optimization"
	@echo "  test      - Run both versions and show output"
	@echo "  benchmark - Time both versions for performance comparison"
	@echo "  clean     - Remove all generated files"
	@echo ""
	@echo "Usage example:"
	@echo "  make clean && make hwpgo && make test"