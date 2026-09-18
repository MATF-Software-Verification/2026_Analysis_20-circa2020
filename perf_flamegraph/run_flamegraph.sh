#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PERF_DATA="$ROOT_DIR/perf/perf.data"
FLAMEGRAPH_DIR="$HOME/tools/FlameGraph"

PERF_SCRIPT="$SCRIPT_DIR/perf_script.txt"
FOLDED_STACKS="$SCRIPT_DIR/folded_stacks.txt"
FLAMEGRAPH_SVG="$SCRIPT_DIR/flamegraph.svg"

echo "=== 1. Provera potrebnih fajlova ==="

if [ ! -f "$PERF_DATA" ]; then
    echo "GRESKA: perf.data nije pronadjen:"
    echo "$PERF_DATA"
    echo "Prvo pokreni perf/run_perf.sh."
    exit 1
fi

if [ ! -x "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" ]; then
    echo "GRESKA: stackcollapse-perf.pl nije pronadjen:"
    echo "$FLAMEGRAPH_DIR/stackcollapse-perf.pl"
    exit 1
fi

if [ ! -x "$FLAMEGRAPH_DIR/flamegraph.pl" ]; then
    echo "GRESKA: flamegraph.pl nije pronadjen:"
    echo "$FLAMEGRAPH_DIR/flamegraph.pl"
    exit 1
fi

echo "Potrebni fajlovi su pronadjeni."

echo
echo "=== 2. Pretvaranje perf.data u tekstualne stack trace-ove ==="

perf script \
    -i "$PERF_DATA" \
    > "$PERF_SCRIPT"

echo "Rezultat sacuvan u:"
echo "  $PERF_SCRIPT"

echo
echo "=== 3. Grupisanje stack trace-ova ==="

"$FLAMEGRAPH_DIR/stackcollapse-perf.pl" \
    "$PERF_SCRIPT" \
    > "$FOLDED_STACKS"

echo "Rezultat sacuvan u:"
echo "  $FOLDED_STACKS"

echo
echo "=== 4. Generisanje Flame Graph-a ==="

"$FLAMEGRAPH_DIR/flamegraph.pl" \
    "$FOLDED_STACKS" \
    > "$FLAMEGRAPH_SVG"

echo "Flame Graph sacuvan u:"
echo "  $FLAMEGRAPH_SVG"

echo
echo "=== Flame Graph analiza zavrsena ==="
echo
echo "Generisani fajlovi:"
echo "  $PERF_SCRIPT"
echo "  $FOLDED_STACKS"
echo "  $FLAMEGRAPH_SVG"
