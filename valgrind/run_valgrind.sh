#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_DIR="$ROOT_DIR/20-circa2020"
BUILD_DIR="$SCRIPT_DIR/build"
APP="$PROJECT_DIR/build/Circa2020"
RESULT="$SCRIPT_DIR/results.txt"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: cmake is not installed."
    exit 1
fi

if ! command -v valgrind >/dev/null 2>&1; then
    echo "Error: valgrind is not installed."
    exit 1
fi

echo "Configuring Circa2020..."
cmake \
    -S "$PROJECT_DIR" \
    -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Debug

echo
echo "Building Circa2020..."
cmake --build "$BUILD_DIR" --target Circa2020 -j"$(nproc)"

if [ ! -x "$APP" ]; then
    echo "Error: Circa2020 executable was not created at:"
    echo "$APP"
    exit 1
fi

echo "Run the predefined GUI test scenario, then close the application normally."

valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --log-file="$RESULT" \
    "$APP"

echo
echo "Valgrind report saved to:"
echo "$RESULT"

tail -35 "$RESULT"
