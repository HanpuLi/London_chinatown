#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

: "${LONDON_CHINATOWN_BUILD_DIR:=build}"
export LONDON_CHINATOWN_BUILD_DIR
rm -rf "$LONDON_CHINATOWN_BUILD_DIR"
mkdir -p "$LONDON_CHINATOWN_BUILD_DIR"

Rscript scripts/data_cleaning_script.R
Rscript scripts/cuisine_fix_script.R
Rscript scripts/visualization_script.R
Rscript scripts/create_comprehensive_report.R
python3 tools/check_reproduction.py "$LONDON_CHINATOWN_BUILD_DIR/food_data.csv"

echo "Pipeline complete: $LONDON_CHINATOWN_BUILD_DIR"
