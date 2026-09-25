# London Chinatown Food & Beverage Analysis

A reproducible spatial snapshot of food-and-beverage establishments in London's Chinatown, based on an OpenStreetMap extract collected on 10 October 2025 and a user-defined study polygon with a 50 m buffer.

Live interactive map: https://hanpuli.github.io/London_chinatown/

**Author:** [Hanpu Li / 李函璞](https://hanpuli.github.io/)

## Archived baseline

The versioned analysis contains 146 food-and-beverage establishments:

| Cultural classification | Count | Share |
| --- | ---: | ---: |
| Chinese/Chinese Heritage | 77 | 52.7% |
| Other Asian | 19 | 13.0% |
| Other | 50 | 34.2% |

The archived cultural Simpson diversity index is 0.588 and the Shannon index is 0.97. Cuisine diversity is reported as Simpson 0.599 and Shannon 1.86.

These are results for the archived 10 October 2025 OSM snapshot, not claims about the current composition of Chinatown.

The citable repository snapshot is **v2026.09.19**. See [CITATION.cff](CITATION.cff),
[CHANGELOG.md](CHANGELOG.md), and [LICENSING.md](LICENSING.md) before reusing the
analysis, data, figures, or third-party images.

## What is published

- **Interactive site:** `index.html` and `interactive_map_files/`.
- **Archived reports:** `reports/comprehensive_analysis_report.html` and `reports/interactive_map.html`.
- **Versioned data:** `data/all_osm_rawdata.csv`, `data/food_data.csv`, and `data/map_summary_for_ppt.csv`.
- **Study geometry:** `geographic/kml_original.geojson` and `geographic/kml_50m_buffer.geojson`.
- **Analysis code:** the R scripts in `scripts/`.
- **Archived figures:** `visualizations/`.

## Reproduce the classification and report

The pipeline now reads only the versioned repository inputs and writes generated output to ignored `build/`:

```sh
./scripts/run_pipeline.sh
```

Its data stages regenerate the 146-row classification and compare stable identity/classification fields against the archived `data/food_data.csv`. The report/visualisation stages generate fresh material under `build/report/` and `build/visualizations/`.

For a quick repository integrity check:

```sh
python3 tools/check_repository.py
```

See [REPRODUCIBILITY.md](REPRODUCIBILITY.md) for the known-good R environment and the boundary between historical data reproduction and rendering-library drift.

## Method

1. Start from the archived OSM snapshot inside the study polygon and 50 m buffer.
2. Filter restaurant, cafe, bar, pub, fast-food, ice-cream and selected food-shop records.
3. Normalise cuisine labels and infer missing cuisine categories from names where the original workflow did so.
4. Classify establishments into Chinese/Chinese Heritage, Other Asian and Other.
5. Compute diversity metrics and generate maps/charts.

The cultural classification includes heuristic/manual rules and therefore contains researcher judgement. OSM completeness and tagging quality also limit the snapshot. See the source scripts and [REPRODUCIBILITY.md](REPRODUCIBILITY.md) before reusing the counts.

## Repository structure

```text
.
├── index.html
├── interactive_map_files/
├── data/
│   ├── all_osm_rawdata.csv
│   ├── food_data.csv
│   └── map_summary_for_ppt.csv
├── geographic/
├── reports/
├── scripts/
│   ├── data_cleaning_script.R
│   ├── cuisine_fix_script.R
│   ├── visualization_script.R
│   ├── create_comprehensive_report.R
│   └── run_pipeline.sh
├── tools/
│   ├── check_repository.py
│   └── check_reproduction.py
├── visualizations/
├── REPRODUCIBILITY.md
├── LICENSING.md
└── SECURITY.md
```

## Licensing and provenance

The repository contains OSM-derived data, authored analysis code/output, and some images whose rights status may differ. Do not infer one blanket licence from the repository being public. See [LICENSING.md](LICENSING.md).

## Contributing

Issues and pull requests are useful when they include the exact input snapshot, changed methodology, and whether the archived 146-row baseline still reproduces. Changes that alter classification counts are research-result changes, not merely refactors.
