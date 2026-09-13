#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_DIR="$SCRIPT_DIR/build-coverage"
COVERAGE_DIR="$SCRIPT_DIR/coverage"
PROJECT_LIB="$ROOT_DIR/20-circa2020/lib"

echo "=== Cleaning previous build and coverage data ==="
rm -rf "$BUILD_DIR"
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

echo "=== Configuring coverage build ==="
cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_COMPILER=g++-10 \
    -DCMAKE_CXX_FLAGS="--coverage -O0 -g" \
    -DCMAKE_EXE_LINKER_FLAGS="--coverage"

echo "=== Building unit tests ==="
cmake --build "$BUILD_DIR" -j"$(nproc)"

echo "=== Capturing zero coverage baseline ==="
lcov --capture \
    --initial \
    --directory "$BUILD_DIR" \
    --output-file "$COVERAGE_DIR/baseline.info" \
    --gcov-tool gcov-10

echo "=== Running unit tests ==="
"$BUILD_DIR/circa_unit_tests"

echo "=== Capturing test coverage ==="
lcov --capture \
    --directory "$BUILD_DIR" \
    --output-file "$COVERAGE_DIR/coverage.info" \
    --gcov-tool gcov-10

echo "=== Combining baseline and runtime coverage ==="
lcov \
    -a "$COVERAGE_DIR/baseline.info" \
    -a "$COVERAGE_DIR/coverage.info" \
    -o "$COVERAGE_DIR/coverage_total.info"

echo "=== Filtering production code ==="
lcov --extract "$COVERAGE_DIR/coverage_total.info" \
    "$PROJECT_LIB/*" \
    --output-file "$COVERAGE_DIR/coverage_total_filtered.info"

echo "=== Generating HTML report ==="
genhtml "$COVERAGE_DIR/coverage_total_filtered.info" \
    --output-directory "$COVERAGE_DIR/html"

echo "=== Final coverage summary ==="
lcov --summary "$COVERAGE_DIR/coverage_total_filtered.info"

echo
echo "HTML report:"
echo "$COVERAGE_DIR/html/index.html"
