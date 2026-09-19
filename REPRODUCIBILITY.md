# Reproducibility

This repository contains both archived outputs and the scripts that produced the food-and-beverage classification workflow. The original OpenStreetMap snapshot is versioned in `data/all_osm_rawdata.csv`; the README records its collection date as 10 October 2025.

## Reproduction boundary

The current pipeline reads only versioned repository inputs and writes generated material under ignored `build/`. Running it must not overwrite the archived baseline in `data/` or the published Pages artifact at repository root.

```sh
./scripts/run_pipeline.sh
```

The final step compares the regenerated `build/food_data.csv` against the archived `data/food_data.csv` on stable identity/classification fields. On 19 September 2026 the current pipeline reproduced all 146 food-and-beverage rows with zero differences on `osm_id`, name, cultural classifications, cuisine classifications and coordinates.

The archived classification totals are:

- Chinese/Chinese Heritage: 77
- Other Asian: 19
- Other: 50
- Total: 146

## Validated local R environment

The 19 September 2026 validation used R 4.5.1 with:

- dplyr 1.1.4
- ggplot2 4.0.0
- leaflet 2.2.3
- htmlwidgets 1.6.4
- gridExtra 2.3
- RColorBrewer 1.1.3
- sf 1.0.21
- knitr 1.50
- rmarkdown 2.30

These versions document a known-good environment; they are not claimed to be the exact environment used for the original October 2025 analysis. Numerical/classification reproduction is tested separately from pixel-for-pixel rendering, because rendering libraries, fonts and map dependencies can change visual output.

## CI boundary

CI validates repository invariants, local asset links, R syntax and the deterministic data/classification stages. It does not fetch a fresh OpenStreetMap snapshot; doing so would turn a historical analysis into a moving-target reanalysis.
