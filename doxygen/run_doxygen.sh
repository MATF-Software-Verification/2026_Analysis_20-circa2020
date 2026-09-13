#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

rm -rf "$SCRIPT_DIR/output"
rm -f "$SCRIPT_DIR/warnings.txt" "$SCRIPT_DIR/run.log"

doxygen "$SCRIPT_DIR/Doxyfile" > "$SCRIPT_DIR/run.log" 2>&1

echo "Doxygen analysis finished."
echo
echo "Warnings:"
cat "$SCRIPT_DIR/warnings.txt"
echo
echo "Opening documentation..."

xdg-open "$SCRIPT_DIR/output/html/index.html" >/dev/null 2>&1 &
