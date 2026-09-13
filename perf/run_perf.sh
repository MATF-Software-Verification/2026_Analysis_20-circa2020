#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/20-circa2020"
BUILD_DIR="$SCRIPT_DIR/build"
TEST_BIN="$PROJECT_DIR/build/Circa2020_test"
PERF_DATA="$SCRIPT_DIR/perf.data"

# Perf zahteva odgovarajuće sistemske dozvole.
PARANOID="$(cat /proc/sys/kernel/perf_event_paranoid)"
if [ "$PARANOID" -gt 0 ]; then
    echo "perf_event_paranoid=$PARANOID"
    echo "Pre pokretanja izvršiti:"
    echo "sudo sysctl kernel.perf_event_paranoid=0"
    exit 1
fi

echo "=== 1. Kreiranje Release build-a bez coverage instrumentacije ==="

rm -rf "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
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
echo "=== 2. Provera da executable ne sadrzi gcov simbole ==="

if nm -C "$TEST_BIN" | grep -Eq 'gcov_do_dump|gcov_read_words|__gcov'; then
    echo "GRESKA: pronadjeni su coverage/gcov simboli."
    exit 1
fi

echo "Nisu pronadjeni gcov simboli."

echo
echo "=== 3. Pokretanje testova ==="

"$TEST_BIN" 2>&1 | tee "$SCRIPT_DIR/test_output.txt"

echo
echo "=== 4. perf stat - 5 ponavljanja ==="

perf stat -r 5 \
    -o "$SCRIPT_DIR/stat.txt" \
    -- "$TEST_BIN" \
    >/dev/null 2>&1

echo "Rezultat sacuvan u perf/stat.txt"

echo
echo "=== 5. perf record - 100 pokretanja test suite-a ==="

rm -f "$PERF_DATA"

perf record -g \
    -o "$PERF_DATA" \
    -- bash -c \
    'for i in $(seq 1 100); do "$1" >/dev/null 2>&1; done' \
    _ "$TEST_BIN"

echo
echo "=== 6. Generisanje kompletnog perf report-a ==="

perf report \
    -i "$PERF_DATA" \
    --stdio \
    --no-children \
    --sort comm,dso,symbol \
    > "$SCRIPT_DIR/report.txt"

echo
echo "=== 7. Generisanje report-a fokusiranog na Circa2020_test ==="

perf report \
    -i "$PERF_DATA" \
    --stdio \
    --no-children \
    --dsos=Circa2020_test \
    --sort symbol \
    > "$SCRIPT_DIR/project_report.txt"

echo
echo "=== Perf analiza zavrsena ==="
echo
echo "Rezultati:"
echo "  $SCRIPT_DIR/test_output.txt"
echo "  $SCRIPT_DIR/stat.txt"
echo "  $SCRIPT_DIR/report.txt"
echo "  $SCRIPT_DIR/project_report.txt"
echo
echo "Privremeni binarni profil:"
echo "  $PERF_DATA"
