#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
tracked = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
errors: list[str] = []
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".heic", ".pdf", ".map"}
HOME_MARKERS = ("/" + "Users/", "/" + "home/")
MAIL = re.compile(r"[A-Za-z0-9._%+-]+@(gmail|outlook|hotmail|icloud)\.[A-Za-z]{2,}", re.I)


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

required = [
    "index.html",
    "reports/comprehensive_analysis_report.html",
    "reports/interactive_map.html",
    "data/food_data.csv",
    "data/all_osm_rawdata.csv",
    "geographic/kml_original.geojson",
    "geographic/kml_50m_buffer.geojson",
]
for rel in required:
    if not (ROOT / rel).is_file():
        errors.append(f"missing published analysis artifact: {rel}")

if errors:
    raise SystemExit("\n".join(errors))
print(f"repository check: {len(tracked)} tracked files; HTML references and public-tree boundaries OK")
