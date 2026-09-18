#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/20-circa2020"
BUILD_DIR="$SCRIPT_DIR/build"

# Originalni CMakeLists.txt Circa2020 projekta hardkoduje
# output executable-a u 20-circa2020/build/.
APP_BIN="$PROJECT_DIR/build/Circa2020"

PERF_DATA="$SCRIPT_DIR/perf.data"

# Perf zahteva odgovarajuce sistemske dozvole.
PARANOID="$(cat /proc/sys/kernel/perf_event_paranoid)"

if [ "$PARANOID" -gt 0 ]; then
    echo "perf_event_paranoid=$PARANOID"
    echo "Pre pokretanja izvrsi:"
    echo "sudo sysctl kernel.perf_event_paranoid=0"
    exit 1
fi

echo "=== 1. Kreiranje Release build-a GUI aplikacije ==="

rm -rf "$BUILD_DIR"

cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++-10

cmake --build "$BUILD_DIR" \
    --target Circa2020 \
    -j"$(nproc)"

if [ ! -x "$APP_BIN" ]; then
    echo "GRESKA: Circa2020 executable nije pronadjen:"
    echo "$APP_BIN"
    exit 1
fi

echo
echo "=== 2. Provera da executable ne sadrzi gcov simbole ==="

if nm -C "$APP_BIN" | grep -Eq 'gcov_do_dump|gcov_read_words|__gcov'; then
    echo "GRESKA: pronadjeni su coverage/gcov simboli."
    exit 1
fi


perf stat \
    -o "$SCRIPT_DIR/stat.txt" \
    -- "$APP_BIN"

echo
echo "perf stat rezultat sacuvan u:"
echo "  $SCRIPT_DIR/stat.txt"

echo
echo "=== 4. perf record nad GUI aplikacijom ==="
echo
echo "GUI ce se sada otvoriti PONOVO."
echo "Ponovi isti scenario kao prethodni put i zatvori aplikaciju."
echo

rm -f "$PERF_DATA"

perf record \
    -g \
    -o "$PERF_DATA" \
    -- "$APP_BIN"

echo
echo "perf record zavrsen."
echo "Binarni profil sacuvan u:"
echo "  $PERF_DATA"

echo
echo "=== 5. Generisanje kompletnog perf report-a ==="

perf report \
    -i "$PERF_DATA" \
    --stdio \
    --no-children \
    --sort comm,dso,symbol \
    > "$SCRIPT_DIR/report.txt"

echo "Kompletan report sacuvan u:"
echo "  $SCRIPT_DIR/report.txt"

echo
echo "=== 6. Generisanje report-a fokusiranog na Circa2020 ==="

perf report \
    -i "$PERF_DATA" \
    --stdio \
    --no-children \
    --dsos=Circa2020 \
    --sort symbol \
    > "$SCRIPT_DIR/project_report.txt"

echo "Report fokusiran na Circa2020 sacuvan u:"
echo "  $SCRIPT_DIR/project_report.txt"

echo
echo "=== Perf analiza zavrsena ==="
echo
echo "Rezultati:"
echo "  $SCRIPT_DIR/stat.txt"
echo "  $SCRIPT_DIR/report.txt"
echo "  $SCRIPT_DIR/project_report.txt"
echo
echo "Binarni profil:"
echo "  $PERF_DATA"
