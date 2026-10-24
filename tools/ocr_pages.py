#!/usr/bin/env python3
"""Render scanned pages and OCR them into corpus/ocr/<instrument>.txt.

Two instruments in laws/ carry no usable text layer: PM 111/2015 is a pure scan,
and PP 30/2021 has a text layer that loses article headings (Pasal 5, 13, 22, 24,
32, 36, 42 and 46 are missing from it). This tool renders every page at 300 dpi
and runs Tesseract with the Indonesian model, writing a page-delimited transcript
that build_corpus.py reads in place of the embedded text.

Tesseract is not part of the repository. Install it first:
  apt-get install tesseract-ocr tesseract-ocr-ind     (or unpack the .deb files)

Run:
  TESSERACT=/path/to/tesseract python3 tools/ocr_pages.py pm-111-2015 pp-30-2021
"""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
LAWS = ROOT / "laws"
OUT = ROOT / "corpus" / "ocr"

FILES = {
    "pm-111-2015": "pm-111-2015-batas-kecepatan.pdf",
    "pp-30-2021": "pp-30-2021-penyelenggaraan-llaj.pdf",
}


def main(targets: list[str]) -> None:
    binary = os.environ.get("TESSERACT") or shutil.which("tesseract")
    if not binary:
        sys.exit("tesseract not found; set TESSERACT to its path")
    lang = os.environ.get("TESSERACT_LANG", "ind")
    OUT.mkdir(parents=True, exist_ok=True)

    for ident in targets or list(FILES):
        doc = pymupdf.open(LAWS / FILES[ident])
        lines = []
        with tempfile.TemporaryDirectory() as tmp:
            for index in range(doc.page_count):
                png = Path(tmp) / f"{index:03d}.png"
                doc[index].get_pixmap(dpi=300).save(png)
                text = subprocess.run(
                    [binary, str(png), "stdout", "-l", lang],
                    capture_output=True, text=True, check=True,
                ).stdout
                lines.append(f"=== PAGE {index + 1:03d}\n{text}")
                print(f"{ident} page {index + 1}/{doc.page_count}", flush=True)
        (OUT / f"{ident}.txt").write_text("".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1:])
