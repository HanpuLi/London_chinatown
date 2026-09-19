#!/usr/bin/env python3
from __future__ import annotations

import csv
import sys
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "README.md",
    "REPRODUCIBILITY.md",
    "LICENSING.md",
    "SECURITY.md",
    "index.html",
    "data/all_osm_rawdata.csv",
    "data/food_data.csv",
    "data/map_summary_for_ppt.csv",
    "geographic/kml_original.geojson",
    "geographic/kml_50m_buffer.geojson",
    "scripts/data_cleaning_script.R",
    "scripts/cuisine_fix_script.R",
    "scripts/visualization_script.R",
    "scripts/create_comprehensive_report.R",
    "scripts/run_pipeline.sh",
]

EXPECTED_COUNTS = {
    "Chinese/Chinese Heritage": 77,
    "Other Asian": 19,
    "Other": 50,
}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_csv(rel: str) -> list[dict[str, str]]:
    with (ROOT / rel).open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


class LinkCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        for key in ("href", "src"):
            value = values.get(key)
            if value:
                self.links.append(value)


for rel in REQUIRED:
    if not (ROOT / rel).exists():
        fail(f"required path missing: {rel}")

raw = read_csv("data/all_osm_rawdata.csv")
food = read_csv("data/food_data.csv")
summary = read_csv("data/map_summary_for_ppt.csv")

if len(raw) != 259:
    fail(f"raw OSM snapshot row count drifted: expected 259, got {len(raw)}")
if len(food) != 146:
    fail(f"food dataset row count drifted: expected 146, got {len(food)}")

counts = Counter(row.get("culture_fixed", "") for row in food)
if dict(counts) != EXPECTED_COUNTS:
    fail(f"culture_fixed counts drifted: {dict(counts)!r}")

summary_counts = {row["Culture"]: int(float(row["Count"])) for row in summary}
if summary_counts != EXPECTED_COUNTS:
    fail(f"map summary disagrees with food_data.csv: {summary_counts!r}")

if sum(summary_counts.values()) != len(food):
    fail("summary counts do not total the food dataset row count")

parser = LinkCollector()
parser.feed((ROOT / "index.html").read_text(encoding="utf-8", errors="replace"))
missing_assets: list[str] = []
for raw_link in parser.links:
    parts = urlsplit(raw_link)
    if parts.scheme or parts.netloc or raw_link.startswith(("#", "mailto:", "javascript:", "data:")):
        continue
    rel = unquote(parts.path)
    if not rel:
        continue
    candidate = (ROOT / rel.lstrip("/")).resolve()
    try:
        candidate.relative_to(ROOT.resolve())
    except ValueError:
        fail(f"index.html links outside repository: {raw_link}")
    if not candidate.exists():
        missing_assets.append(raw_link)
if missing_assets:
    fail(f"index.html has missing local assets: {missing_assets}")

gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8", errors="replace")
if "build/" not in gitignore:
    fail("generated build/ directory is not ignored")

stale_inputs = {
    "london_chinatown_all_osm_rawdata.csv",
    "london_chinatown_food_only_cleaned.csv",
    "london_chinatown_food_cuisine_fixed.csv",
    "chinatown_kml_original.geojson",
    "chinatown_kml_50m_buffer.geojson",
}
for script in (ROOT / "scripts").glob("*.R"):
    text = script.read_text(encoding="utf-8", errors="replace")
    for stale in stale_inputs:
        if f'"{stale}"' in text:
            fail(f"{script.relative_to(ROOT)} still references obsolete root input {stale}")

print("repository boundary OK")
print(f"raw rows={len(raw)} food rows={len(food)} counts={dict(counts)}")
print(f"index local assets={len([x for x in parser.links if not urlsplit(x).scheme])}")
