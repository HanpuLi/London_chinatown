#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import subprocess
import sys
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
tracked = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True).splitlines()
errors: list[str] = []
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".heic", ".pdf", ".map"}
HOME_MARKERS = ("/" + "Users/", "/" + "home/")
MAIL = re.compile(r"[A-Za-z0-9._%+-]+@(gmail|outlook|hotmail|icloud)\.[A-Za-z]{2,}", re.I)

REQUIRED = [
    "README.md",
    "REPRODUCIBILITY.md",
    "LICENSING.md",
    "SECURITY.md",
    "CITATION.cff",
    "CHANGELOG.md",
    "VERSION",
    "index.html",
    "reports/comprehensive_analysis_report.html",
    "reports/interactive_map.html",
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


class Refs(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.refs: list[tuple[int, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        for key in ("href", "src"):
            value = values.get(key)
            if value:
                self.refs.append((self.getpos()[0], value))


def read_csv(rel: str) -> list[dict[str, str]]:
    with (ROOT / rel).open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


for rel in tracked:
    path = ROOT / rel
    if not path.is_file() or path.suffix.lower() in SKIP_SUFFIXES:
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    if any(marker in text for marker in HOME_MARKERS):
        errors.append(f"machine-local absolute home path in tracked text: {rel}")
    if MAIL.search(text):
        errors.append(f"personal mailbox in tracked text: {rel}")

for rel in tracked:
    if not rel.endswith(".html"):
        continue
    source = ROOT / rel
    parser = Refs()
    try:
        parser.feed(source.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, OSError) as exc:
        errors.append(f"cannot parse HTML {rel}: {exc}")
        continue
    for line, ref in parser.refs:
        parsed = urlsplit(ref)
        if parsed.scheme or parsed.netloc or ref.startswith(("#", "//", "data:", "javascript:", "mailto:")):
            continue
        local = unquote(parsed.path)
        if not local:
            continue
        target = (source.parent / local).resolve()
        if local.endswith("/"):
            target /= "index.html"
        try:
            target.relative_to(ROOT)
        except ValueError:
            errors.append(f"{rel}:{line}: local reference escapes repository: {ref}")
            continue
        if not target.exists():
            errors.append(f"{rel}:{line}: missing local reference: {ref}")

for rel in REQUIRED:
    if not (ROOT / rel).is_file():
        errors.append(f"required analysis artifact missing: {rel}")

raw = read_csv("data/all_osm_rawdata.csv")
food = read_csv("data/food_data.csv")
summary = read_csv("data/map_summary_for_ppt.csv")
if len(raw) != 259:
    errors.append(f"raw OSM snapshot row count drifted: expected 259, got {len(raw)}")
if len(food) != 146:
    errors.append(f"food dataset row count drifted: expected 146, got {len(food)}")

counts = Counter(row.get("culture_fixed", "") for row in food)
if dict(counts) != EXPECTED_COUNTS:
    errors.append(f"culture_fixed counts drifted: {dict(counts)!r}")

try:
    summary_counts = {row["Culture"]: int(float(row["Count"])) for row in summary}
except (KeyError, ValueError) as exc:
    summary_counts = {}
    errors.append(f"invalid map summary schema/value: {exc}")
if summary_counts and summary_counts != EXPECTED_COUNTS:
    errors.append(f"map summary disagrees with food_data.csv: {summary_counts!r}")

gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8", errors="replace")
if "build/" not in gitignore:
    errors.append("generated build/ directory is not ignored")

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
            errors.append(f"{script.relative_to(ROOT)} still references obsolete root input {stale}")

version = (ROOT / "VERSION").read_text().strip() if (ROOT / "VERSION").exists() else None
citation = (ROOT / "CITATION.cff").read_text(encoding="utf-8") if (ROOT / "CITATION.cff").exists() else ""
readme = (ROOT / "README.md").read_text(encoding="utf-8")
if version != "2026.09.19":
    errors.append(f"unexpected release snapshot version: {version!r}")
if f'version: "{version}"' not in citation or 'date-released: "2026-09-19"' not in citation:
    errors.append("CITATION.cff release metadata does not match VERSION/release date")
if "v2026.09.19" not in readme:
    errors.append("README does not identify the citable release snapshot")

if errors:
    raise SystemExit("\n".join(errors))

print(
    f"repository check: {len(tracked)} tracked files; HTML references, public boundary and data invariants OK"
)
print(f"raw rows={len(raw)} food rows={len(food)} counts={dict(counts)}")
