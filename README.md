# WaferInspector

Automatyczna inspekcja NDT siatek DRIE na krzemie (pitch 8 µm, linia 4 µm, głębokość 12,8/16 µm) ze skanów kontrastu fazowego z NanoTerasu. Wynik: PASS/FAIL względem tolerancji geometrycznych.

## Start
```matlab
addpath("src")
gt = synth.makeSyntheticGratingStack("data/synth_fail");                     % z defektami
synth.makeSyntheticGratingStack("data/synth_pass", Defects=strings(0));      % bez defektów
[vol, meta] = io.loadTiffStack("data/synth_fail");
volshow(vol)                                                                  % podgląd 3D
results = runtests("tests"); table(results)
```

## Benchmark
| Dane | Rozmiar | Czas wczytania |
|---|---|---|
| synth 256×256×80 | – | – |
