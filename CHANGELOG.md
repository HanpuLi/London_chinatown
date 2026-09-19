# Changelog

## [2026.09.19] - 2026-09-19

First citable reproducibility snapshot.

- Preserves the 10 October 2025 OpenStreetMap source snapshot and 146-row food/beverage classification baseline.
- Repairs the R pipeline after the repository reorganisation and isolates regenerated output under ignored `build/`.
- Reproduces all 146 archived rows exactly across eight stable identity/classification fields.
- Adds repository/data/link invariants, R syntax checks, deterministic classification CI, CodeQL and gitleaks.
- Documents the mixed-rights boundary for OSM-derived data, authored analysis and third-party images.
