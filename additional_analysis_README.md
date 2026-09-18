# Dodatne analize

Nakon osnovne analize projekta urađene su još dve izmene u načinu korišćenja alata `perf` i Valgrind Memcheck. Ideja je bila da `perf` radi nad stvarnom GUI aplikacijom, dok se Valgrind koristi nad postojećim testovima. Na osnovu `perf` profila dodatno je generisan i Flame Graph.

## Perf nad GUI aplikacijom

`perf` je prvobitno bio pokretan nad testovima, ali je analiza kasnije prebačena na samu Circa2020 GUI aplikaciju. Aplikacija se gradi u Release režimu, bez coverage instrumentacije.

Tokom profilisanja korišćen je jednostavan scenario koji uključuje dodavanje dve `Pin` komponente, jednog AND kola i `LightBulb` komponente, njihovo povezivanje i nekoliko promena stanja ulaza.

Za osnovne metrike korišćen je `perf stat`. U jednom od pokretanja dobijene su, između ostalog, sledeće vrednosti:

```text
task-clock:              3734.39 ms
cycles:                  5,717,976,209
instructions:            6,219,357,375
IPC:                     1.09
branch-misses:           2.82%
frontend stalled cycles: 7.61%
backend stalled cycles:  24.47%
```

Ukupno trajanje scenarija bilo je oko 44.5 sekundi, dok je aktivno CPU vreme bilo znatno manje. To je očekivano za GUI aplikaciju, pošto veliki deo vremena aplikacija čeka korisničku interakciju.

Za detaljniji profil korišćeni su `perf record` i `perf report`. Profil je sadržao oko 11 hiljada uzoraka, bez izgubljenih uzoraka.

Od funkcija koje pripadaju samom Circa2020 projektu najviše se izdvaja:

```text
Scene::drawBackground(...)    ~0.44%
```

Ostale projektne funkcije, kao što su `ComponentGraphicsItem::boundingRect`, `Scene::mouseMoveEvent`, `ComponentGraphicsItem::paint` i `LightBulbItem::paint`, pojavljuju se sa dosta manjim procentima.

Na osnovu ovog scenarija nije uočena jedna projektna funkcija koja predstavlja očigledno CPU usko grlo. Značajan deo profila pripada Qt grafičkom sloju, XCB-u i sistemskim bibliotekama, što je očekivano za Qt GUI aplikaciju.

Skripta za reprodukciju ove analize nalazi se u:

```text
perf/run_perf.sh
```

## Flame Graph

Na osnovu `perf.data` fajla generisan je i Flame Graph, kako bi se profil mogao lakše vizuelno analizirati.

Za generisanje je korišćen Brendan Gregg FlameGraph alat. Proces izgleda ovako:

```text
perf.data
    |
    v
perf script
    |
    v
perf_script.txt
    |
    v
stackcollapse-perf.pl
    |
    v
folded_stacks.txt
    |
    v
flamegraph.pl
    |
    v
flamegraph.svg
```

`perf script` prvo pretvara binarni `perf.data` u tekstualne stack trace-ove. Nakon toga `stackcollapse-perf.pl` grupiše iste stack-ove, a `flamegraph.pl` od tih podataka generiše SVG Flame Graph.

Širina pojedinačnog bloka na Flame Graph-u predstavlja koliko se često određena funkcija ili call stack pojavljivao u uzorcima.

Dobijeni Flame Graph potvrđuje rezultat iz `perf report` analize. Ne postoji jedna dominantna funkcija iz aplikacionog koda, dok se među Circa2020 funkcijama najviše izdvaja `Scene::drawBackground`.

Skripta za generisanje Flame Graph-a nalazi se u:

```text
perf_flamegraph/run_flamegraph.sh
```

Krajnji rezultat je:

```text
perf_flamegraph/flamegraph.svg
```

## Valgrind Memcheck nad testovima

Valgrind Memcheck je prvobitno korišćen nad GUI aplikacijom. U dodatnoj analizi je promenjen scenario tako da se Memcheck pokreće nad postojećim `Circa2020_test` testovima.

Testovi se prvo grade u Debug režimu, a zatim se kompletan test suite pokreće pod Memcheck-om.

Dobijeni rezultat je:

```text
definitely lost: 720 bytes in 10 blocks
indirectly lost: 2456 bytes in 28 blocks
possibly lost: 0 bytes in 0 blocks
still reachable: 0 bytes in 0 blocks

ERROR SUMMARY: 10 errors from 10 contexts
```

Za razliku od prethodne analize GUI aplikacije, gde su prijavljeni problemi uglavnom dolazili iz spoljašnjih biblioteka, ovde stack trace-ovi vode do funkcija iz projekta, između ostalog:

```text
ComponentFactory::makePin(...)
ComponentFactory::makeLightBulb()
```

Na primer:

```text
ComponentFactory::makePin(Signal::State)
    componentfactory.cpp:76

ComponentFactory::makeLightBulb()
    componentfactory.cpp:81
```

Ove funkcije dinamički alociraju objekte:

```cpp
Pin *ComponentFactory::makePin(Signal::State s)
{
    return new Pin(s);
}

LightBulb *ComponentFactory::makeLightBulb()
{
    return new LightBulb();
}
```

Daljom proverom testova utvrđeno je da se pojedini privremeni `Pin` i `LightBulb` objekti prave unutar Catch2 `SECTION` blokova, koriste u testu, ali se ne dodaju u `CircuitBoard` niti se kasnije eksplicitno brišu.

Ovo je bitno zato što `CircuitBoard` preuzima odgovornost za komponente koje su mu dodate preko `add()` metode. U destruktoru poziva `removeAll()`, koji prolazi kroz sve komponente i oslobađa ih pomoću `delete`.

Objekti koji nisu dodati u `CircuitBoard` ne prolaze kroz ovaj mehanizam za oslobađanje memorije.

Zbog toga se pronađeni memory leak-ovi mogu povezati sa načinom na koji su napisani pojedini testovi, odnosno sa privremenim objektima koji ostaju neoslobođeni nakon završetka test sekcije. Rezultat zato ne ukazuje direktno na grešku u funkcionalnosti same GUI aplikacije, već na problem upravljanja memorijom u test kodu.

Skripta za reprodukciju ove analize nalazi se u:

```text
valgrind/run_valgrind.sh
```

Kompletan Valgrind izlaz nalazi se u:

```text
valgrind/results.txt
```

## Zaključak

Ovim izmenama su `perf` i Valgrind korišćeni u scenarijima koji bolje odgovaraju njihovoj nameni.

`perf` sada profilira stvarnu GUI aplikaciju i daje pregled ponašanja aplikacije tokom realnog korisničkog scenarija. Flame Graph dodatno olakšava pregled call stack-ova i raspodele CPU uzoraka.

Valgrind Memcheck se pokreće nad testovima, gde je uspeo da pronađe konkretne memory leak-ove koji se mogu pratiti do objekata kreiranih u test kodu.

Na ovaj način su obe analize postale lakše za reprodukciju i dale konkretnije rezultate nego u prvobitnoj verziji.
