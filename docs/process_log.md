# Process Log – Wafer 01 (DRIE grating)

## Session 1: UV photolithography – 2 October 2026
- Location: Tohoku University, Yashiro Laboratory
- Instructor: Hemmi-sensei
- Operator: Krzysztof Torczyński (IAESTE intern, Lodz University of Technology)

### Substrate preparation
- Substrate: silicon wafer (TODO: confirm "TiO2 base")
- Dehydration bake: 15 min at 150 °C
- Adhesion promoter: OAP primer

### Spin coating
| Step | Speed | Time |
|---|---|---|
| 1 – spreading | 500 rpm | 3 s |
| 2 – thinning | 3000 rpm | 20 s |

- Acceleration: 0.5 s
- Target resist thickness: approx. 1 µm
- Edge and backside cleaning with acetone

### Exposure
- Tool: SUSS MicroTec mask aligner
- Mask: chromium-on-glass, pitch 4 µm, UV transmittance 90%
- Lamp intensity: 45.6 mW/cm²
- Dose: 44 mJ/cm²
- Exposure time: 1.1 s (44 / (45.6 × 0.9))
- Mode: hard contact; alignment gap: 30 µm

### Development
- Developer: TMAH (toxic – PPE required), 2 min with continuous agitation
- Rinsing: DI water
- Drying: spin-dry

### Observed defects
| Defect | Likely cause |
|---|---|
| Bubbles in the resist | Improper resist dispensing |
| Particles | Dust contamination |
| Slip (wafer displacement) | Handling error |
| Water marks | Rinsing or drying |

### Open questions
- TODO: exact line width and duty cycle of the mask
- TODO: resist selectivity for a 16 µm DRIE etch
- TODO: date of the etching session

### Relevance to WaferInspector
The defects observed in this session (particles, bubbles, water marks) are
candidates for automated post-lithography optical inspection. CD-SEM is
currently the manual reference method, which the software aims to complement.

## Session 2: DRIE etching (planned)
