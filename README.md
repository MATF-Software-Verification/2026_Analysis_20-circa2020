# Analiza projekta Circa2020

U ovom repozitorijumu nalazi se analiza softverskog projekta **Circa2020**, izrađena u okviru samostalnog projekta iz kursa *Verifikacija softvera* na Matematičkom fakultetu Univerziteta u Beogradu.

## Autor

Ime i prezime: Luka Djekic  
Broj indeksa: 1021/2025

## Opis projekta

**Circa2020** je C++/Qt aplikacija za kreiranje i simulaciju digitalnih logičkih kola.

Originalni projekat dostupan je na adresi:  
https://gitlab.com/matf-bg-ac-rs/course-rs/projects-2020-2021/20-circa2020

Analiza je izvršena nad:

- granom `master`
- commit-om `55a36b9ae4cb72a13f5f826ab4cceec112abf48d`

Originalni projekat uključen je kao Git submodule u direktorijumu `20-circa2020/`. Izvorni kod submodula nije menjan; svi dodatni testovi, skripte i rezultati analiza nalaze se u roditeljskom repozitorijumu.

## Preuzimanje projekta

Repozitorijum se može klonirati zajedno sa submodulom:

```bash
git clone --recurse-submodules https://github.com/MATF-Software-Verification/2026_Analysis_20-circa2020.git
cd 2026_Analysis_20-circa2020
```

Ako je repozitorijum već kloniran bez submodula:

```bash
git submodule update --init --recursive
```

## Prevođenje projekta

Za generisanje i izgradnju aplikacije koristi se CMake:

```bash
cmake -S 20-circa2020 \
      -B 20-circa2020/build \
      -DCMAKE_BUILD_TYPE=Debug

cmake --build 20-circa2020/build \
      --target Circa2020 \
      -j"$(nproc)"
```

## Pokretanje aplikacije

Nakon uspešne izgradnje aplikacija se pokreće komandom:

```bash
./20-circa2020/build/Circa2020
```

## Korišćene tehnike i alati

U okviru analize korišćene su sledeće tehnike:

1. Unit testiranje uz LCOV analizu pokrivenosti
2. Cppcheck
3. Valgrind Memcheck
4. Clazy
5. Doxygen uz Graphviz
6. perf
7. clang-format

Za svaku tehniku postoji skripta koja omogućava reprodukciju analize i odgovarajući rezultat analize.

# 1. Unit testiranje i LCOV

Za projekat su napisani dodatni unit testovi za klasu `Adder`, koji se nalaze u direktorijumu `unit_tests/`.

Pokretanje:

```bash
./unit_tests/run_tests.sh
```

Skripta pokreće testove i generiše LCOV izveštaj o pokrivenosti koda.

Rezultat:

```text
6 test case-ova
33 assertions
Line coverage:     5.2%
Function coverage: 6.2%
```

HTML coverage izveštaj nalazi se u:

```text
unit_tests/coverage/html/index.html
```
# 2. Cppcheck

Cppcheck 2.7 je korišćen za statičku analizu produkcionog `lib/` dela projekta.

Pokretanje:

```bash
./cppcheck/run_cppcheck.sh
```

Rezultat analize:

```text
3 upozorenja
```

Najvažniji nalazi odnose se na:

- poziv virtuelne funkcije iz destruktora klase `CircuitBoard`,
- nepotrebno prosleđivanje `std::set<Component *>` po vrednosti u dve funkcije klase `Converter`.

Kompletan rezultat nalazi se u:

```text
cppcheck/results.txt
```

# 3. Valgrind Memcheck

Valgrind Memcheck je korišćen za dinamičku analizu memorije Circa2020 GUI aplikacije.

Pokretanje:

```bash
./valgrind/run_valgrind.sh
```

Analiza je izvršena nad funkcionalnim scenarijem sa dve `Pin` komponente, AND kolom i `LightBulb` komponentom.

Memcheck je prijavio error/leak kontekste, ali analizirani stack trace-ovi nisu pokazali greške koje se mogu direktno pripisati Circa2020 izvornom kodu.

Rezultati se nalaze u:

```text
valgrind/results.txt
```

# 4. Clazy

Clazy 1.11 je korišćen za Qt-specifičnu statičku analizu `lib/` i `app/` delova projekta.

Pokretanje:

```bash
./clazy/run_clazy.sh
```

Nakon deduplikacije pronađeno je:

```text
26 jedinstvenih upozorenja
```

Najčešći nalazi odnose se na `connect-by-name`, `detaching-temporary`, `range-loop-reference` i `range-loop-detach`.

Rezultati se nalaze u:

```text
clazy/results_level0.txt
clazy/results_level1.txt
clazy/unique_warnings.txt
```

# 5. Doxygen i Graphviz

Doxygen 1.9.1 i Graphviz 2.43.0 korišćeni su za generisanje dokumentacije i pregled strukture projekta.

Pokretanje:

```bash
./doxygen/run_doxygen.sh
```

Analiza generiše HTML dokumentaciju sa class, inheritance, collaboration i include grafovima.

Pronađeno je jedno upozorenje vezano za zastarelu dokumentaciju parametra u funkciji `ComponentFactory::deepCopy`.

Rezultat se nalazi u:

```text
doxygen/warnings.txt
```

Generisana dokumentacija otvara se iz:

```text
doxygen/output/html/index.html
```

# 6. perf

Linux `perf` je korišćen za analizu performansi postojećeg test suite-a nad čistim `Release` build-om bez coverage instrumentacije.

Pokretanje:

```bash
./perf/run_perf.sh
```

Konačni `perf stat` rezultat uključuje:

```text
IPC:                    0.84
Frontend stalled cycles: 5.27%
Backend stalled cycles: 18.39%
Branch misses:           6.40%
```

`perf record` je korišćen za profilisanje funkcija koje se najčešće pojavljuju tokom izvršavanja testova.

Rezultati se nalaze u:

```text
perf/stat.txt
perf/report.txt
perf/project_report.txt
perf/test_output.txt
```

# 7. clang-format

clang-format 14 je korišćen za proveru usklađenosti izvornog koda sa postojećom `.clang-format` konfiguracijom projekta.

Pokretanje:

```bash
./clang-format/run_clang_format.sh
```

Analizirano je ukupno:

```text
183 C/C++ fajla
```

Rezultat:

```text
Non-compliant files: 0
```

Analiza koristi `--dry-run --Werror`, tako da izvorni kod nije menjan.

Rezultati se nalaze u:

```text
clang-format/results.txt
clang-format/noncompliant_files.txt
```
# CI

Repozitorijum koristi zvanični MATF Software Verification GitHub Actions CI.

Workflow fajlovi nalaze se u:

```text
.github/workflows/
```

# Struktura repozitorijuma

```text
.
├── .github/workflows/   # CI
├── 20-circa2020/        # originalni projekat kao Git submodule
├── unit_tests/          # dodatni testovi i LCOV coverage
├── cppcheck/            # Cppcheck analiza
├── valgrind/            # Valgrind Memcheck analiza
├── clazy/               # Clazy analiza
├── doxygen/             # Doxygen i Graphviz
├── perf/                # perf analiza
├── clang-format/        # provera formatiranja
├── README.md
├── ProjectAnalysisReport.tex
└── ProjectAnalysisReport.pdf
```

Generisani build direktorijumi i privremeni artefakti nisu deo repozitorijuma i mogu se ponovo napraviti odgovarajućim skriptama.

# Detaljni izveštaj

Detaljna metodologija, analiza rezultata, uočeni problemi i zaključci nalaze se u:

```text
ProjectAnalysisReport.pdf
```

# Zaključak

Analiza projekta Circa2020 obuhvatila je funkcionalno testiranje i coverage, statičku i dinamičku analizu, Qt-specifičnu analizu, pregled strukture i dokumentacije, profilisanje performansi i proveru formatiranja.

Najznačajniji nalazi uključuju dodatne testove za `Adder`, Cppcheck i Clazy upozorenja vezana za dizajn i performanse, jednu neusklađenost u Doxygen dokumentaciji i uspešnu proveru formatiranja svih analiziranih C/C++ fajlova.

Originalni Circa2020 submodule nije menjan tokom analize.
