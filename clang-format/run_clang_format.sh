#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/20-circa2020"
STYLE_FILE="$PROJECT_DIR/.clang-format"

RESULT="$SCRIPT_DIR/noncompliant_files.txt"
SUMMARY="$SCRIPT_DIR/results.txt"

: > "$RESULT"

TOTAL=0

while IFS= read -r file; do
    TOTAL=$((TOTAL + 1))

    if ! clang-format \
        --style="file:$STYLE_FILE" \
        --dry-run \
        --Werror \
        "$file" >/dev/null 2>&1; then
        echo "$file" >> "$RESULT"
    fi
done < <(
    find "$PROJECT_DIR/lib" "$PROJECT_DIR/app" \
        -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' \) \
        | sort
)

NONCOMPLIANT=$(wc -l < "$RESULT")

{
    echo "clang-format version: $(clang-format --version)"
    echo "Style: $STYLE_FILE"
    echo "Checked files: $TOTAL"
    echo "Non-compliant files: $NONCOMPLIANT"
} > "$SUMMARY"

cat "$SUMMARY"

if [ "$NONCOMPLIANT" -gt 0 ]; then
    echo
    echo "Files that require formatting:"
    cat "$RESULT"
fi
