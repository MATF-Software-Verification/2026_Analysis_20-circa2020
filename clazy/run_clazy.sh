#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
PROJECT_DIR="$ROOT_DIR/20-circa2020"

rm -rf "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_CXX_COMPILER=g++-10 \
  -DCMAKE_CXX_FLAGS="-DCATCH_CONFIG_NO_POSIX_SIGNALS"

cmake --build "$BUILD_DIR" --target Circa2020 -j"$(nproc)"

clazy-standalone \
  -p "$BUILD_DIR" \
  --checks=level1 \
  $(find "$PROJECT_DIR/lib" "$PROJECT_DIR/app" -name '*.cpp' -print) \
  > "$SCRIPT_DIR/results_level1.txt" 2>&1

grep 'warning:' "$SCRIPT_DIR/results_level1.txt" | sort -u \
  > "$SCRIPT_DIR/unique_warnings.txt"

cat "$SCRIPT_DIR/unique_warnings.txt"
