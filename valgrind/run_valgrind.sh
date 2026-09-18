#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/20-circa2020"
BUILD_DIR="$SCRIPT_DIR/build"

# Originalni Circa2020 CMake hardkoduje output executable-a
# u 20-circa2020/build/.
TEST_BIN="$PROJECT_DIR/build/Circa2020_test"

RESULTS_FILE="$SCRIPT_DIR/results.txt"
TEST_OUTPUT="$SCRIPT_DIR/test_output.txt"

echo "=== 1. Kreiranje Debug build-a testova ==="

rm -rf "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_COMPILER=g++-10 \
    -DCMAKE_CXX_FLAGS="-DCATCH_CONFIG_NO_POSIX_SIGNALS"

cmake --build "$BUILD_DIR" \
    --target Circa2020_test \
    -j"$(nproc)"

if [ ! -x "$TEST_BIN" ]; then
    echo "GRESKA: Circa2020_test executable nije pronadjen:"
    echo "$TEST_BIN"
    exit 1
fi

echo
echo "=== 2. Provera testova bez Valgrind-a ==="

"$TEST_BIN" 2>&1 | tee "$TEST_OUTPUT"

echo
echo "=== 3. Pokretanje testova pod Valgrind Memcheck-om ==="

rm -f "$RESULTS_FILE"

valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --num-callers=30 \
    --log-file="$RESULTS_FILE" \
    "$TEST_BIN"

echo
echo "=== Valgrind analiza zavrsena ==="
echo
echo "Rezultati:"
echo "  Test output:      $TEST_OUTPUT"
echo "  Valgrind rezultat: $RESULTS_FILE"
