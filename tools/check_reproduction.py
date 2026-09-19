#!/usr/bin/env python3
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

if len(sys.argv) != 2:
    raise SystemExit("usage: check_reproduction.py <generated-food-data.csv>")

generated = Path(sys.argv[1])
archived = ROOT / "data" / "food_data.csv"
KEYS = [
    "osm_id", "name", "culture", "culture_fixed",
    "cuisine_inferred", "cuisine_fixed", "lat", "lng",
]

def load(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))

left = load(generated)
right = load(archived)
if len(left) != len(right):
    raise SystemExit(f"row-count mismatch: generated={len(left)} archived={len(right)}")
if list(left[0]) != list(right[0]):
    raise SystemExit("column schema mismatch")

diffs = []
for index, (a, b) in enumerate(zip(left, right)):
    for key in KEYS:
        if (a.get(key) or "") != (b.get(key) or ""):
            diffs.append((index, key, a.get(key), b.get(key)))
            if len(diffs) >= 20:
                break
    if len(diffs) >= 20:
        break

if diffs:
    for diff in diffs:
        print("DIFF", diff, file=sys.stderr)
    raise SystemExit("generated classification does not match archived baseline")

print(f"reproduction baseline OK: {len(left)} rows, {len(KEYS)} key fields exact")
