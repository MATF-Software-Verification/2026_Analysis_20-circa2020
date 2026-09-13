#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cppcheck \
  --enable=warning,performance,portability \
  --std=c++17 \
  --language=c++ \
  "$ROOT_DIR/20-circa2020/lib" \
  2> "$SCRIPT_DIR/results.txt"

cat "$SCRIPT_DIR/results.txt"
