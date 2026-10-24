#!/usr/bin/env python3
"""Index every article of the statutes in laws/ with the page it starts on.

The PDFs are the source of record. This tool reads them, splits each instrument
into body, explanatory notes and attachments, and writes one record per ayat
(or per item of a definition list) with its article number, page, chapter and
text. corpus/provisions.json is the index a reader uses to find the page behind
a law in bend/, not an input to the model.

Two instruments carry no usable text layer: PM 111/2015 is a pure scan, and
PP 30/2021's layer loses article headings. tools/ocr_pages.py renders those
pages and records what they say; a transcript in corpus/ocr/ wins over the
layer.

Run:
  uv venv .venv && uv pip install --python .venv/bin/python pymupdf
  .venv/bin/python tools/build_corpus.py

Output:
  corpus/provisions.json   one record per provision, grouped by instrument
  corpus/index.json        pages, article counts and gaps per instrument
"""

import hashlib
import json
import re
import unicodedata
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
LAWS = ROOT / "laws"
CORPUS = ROOT / "corpus"

INSTRUMENTS = [
    {
        "id": "uu-22-2009",
        "file": "uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf",
        "title": "Lalu Lintas dan Angkutan Jalan",
    },
    {
        "id": "uu-28-2014",
        "file": "uu-28-2014-hak-cipta.pdf",
        "title": "Hak Cipta",
    },
    {
        "id": "pp-30-2021",
        "file": "pp-30-2021-penyelenggaraan-llaj.pdf",
        "title": "Penyelenggaraan Bidang Lalu Lintas dan Angkutan Jalan",
    },
    {
        "id": "pp-37-2017",
        "file": "pp-37-2017-keselamatan-llaj.pdf",
        "title": "Keselamatan Lalu Lintas dan Angkutan Jalan",
    },
    {
        "id": "pp-79-2013",
        "file": "pp-79-2013-jaringan-llaj.pdf",
        "title": "Jaringan Lalu Lintas dan Angkutan Jalan",
    },
    {
        "id": "pm-13-2014",
        "file": "pm-13-2014-rambu-lalu-lintas.pdf",
        "title": "Rambu Lalu Lintas",
    },
    {
        "id": "pm-111-2015",
        "file": "pm-111-2015-batas-kecepatan.pdf",
        "title": "Tata Cara Penetapan Batas Kecepatan",
    },
    {
        "id": "perpol-5-2021",
        "file": "perpol-5-2021-sim.pdf",
        "title": "Penerbitan dan Penandaan Surat Izin Mengemudi",
    },
]

# Lines that carry page furniture rather than law text.
FURNITURE = [
    re.compile(r"^-\s*\d+\s*-$"),
    re.compile(r"^\d{1,3}$"),
    re.compile(r"^BAB\s+[IVXLC]+\s*(\.\s*)+$"),
    re.compile(r"^Pasal\s+\d+\s*(\.\s*)+$"),
    re.compile(r"^SK\s+No\s+\S+$"),
    re.compile(r"^(PRESIDEN|SALINAN)\s*$"),
    re.compile(r"^REPUBLIK\s+INDONESIA$"),
    re.compile(r"^PRES\s*IDEN$"),
    re.compile(r"^REPUBLIK\s+tNDONESiA$"),
]

# A heading starts with `Pasal N`. OCR sometimes spaces the number ("Pasal 1 1"),
# merges the heading with the first line of the article, or reads a digit as a
# letter ("Pasal 6O"). Article numbers run 1..N without gaps, so a match only
# counts as a heading when it names the next expected number; that rejects
# "Pasal 12 ayat (3) mempunyai tugas:" mid-sentence.
RE_PASAL = re.compile(r"^Pasal\s+(\d(?:\s?\d)*)")
RE_BAB = re.compile(r"^BAB\s+([IVXLC]+)\s*\.?\s*$")
RE_BAB_TITLE = re.compile(r"^BAB\s+([IVXLC]+)\s+(.+)$")
RE_BAGIAN = re.compile(r"^(Bagian|Paragraf)\s+(\w+)\s*$")
RE_AYAT = re.compile(r"^\((\d+)\)\s*(.*)$")


def normalise(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    return text.replace("\xa0", " ").replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"')


def clean_page(text: str) -> list[str]:
    out = []
    for raw in normalise(text).split("\n"):
        line = re.sub(r"[ \t]+", " ", raw).strip()
        if not line or any(p.match(line) for p in FURNITURE):
            continue
        out.append(line)
    return out


def split_parts(pages: list[list[str]]) -> tuple[int, int]:
    """Return (body_end, attachment_start) as page indexes."""
    body_end = len(pages)
    lampiran = len(pages)
    for i, lines in enumerate(pages):
        head = [re.sub(r"\s+", "", l).upper() for l in lines[:6]]
        if body_end == len(pages) and any(
            h.startswith("PENJELASAN") for h in head
        ):
            body_end = i
        if lampiran == len(pages) and any(h == "LAMPIRAN" for h in head):
            lampiran = i
    return min(body_end, lampiran), lampiran


def article_number(token: str, rest: str, expected: int) -> int | None:
    """Read an article number from a heading, tolerating OCR noise."""
    digits = re.sub(r"\s+", "", token)
    candidates = [digits]
    if rest[:1] in "OoQ":
        candidates.append(digits + "0")
    for c in candidates:
        if c.isdigit() and int(c) >= expected:
            return int(c)
    return None


def load_pages(inst: dict) -> tuple[list[list[str]], int]:
    transcript = CORPUS / "ocr" / f'{inst["id"]}.txt'
    doc = pymupdf.open(LAWS / inst["file"])
    if transcript.exists():
        pages = []
        for block in transcript.read_text(encoding="utf-8").split("=== PAGE ")[1:]:
            _number, _, body = block.partition("\n")
            pages.append(clean_page(body))
        return pages, len(pages)
    return [clean_page(p.get_text()) for p in doc], doc.page_count


def parse_instrument(inst: dict) -> dict:
    pages, page_count = load_pages(inst)
    body_end, attachment = split_parts(pages)

    articles: list[dict] = []
    bab = None
    bab_title = None
    section = None
    current = None
    pending = None
    expected = 1
    rejected: list[str] = []

    def flush():
        nonlocal current
        if current is not None and current["ayat"]:
            articles.append(current)
        current = None

    for page_index in range(body_end):
        lines = pages[page_index]
        i = 0
        while i < len(lines):
            line = lines[i]
            if line.strip() == "Pasal" and i + 1 < len(lines) and re.match(r"^\d", lines[i + 1]):
                line = "Pasal " + lines[i + 1]
                i += 1

            m_pasal = RE_PASAL.match(line)
            if m_pasal:
                rest = line[m_pasal.end():]
                low_rest = rest.lower().lstrip(" .,:")
                citation = low_rest.startswith("ayat") or "tahun" in low_rest[:30]
                number = None if citation else article_number(m_pasal.group(1), rest, expected)
                if number is not None and not (number == expected or expected < number <= expected + 2):
                    number = None
                if number is None:
                    rejected.append(line[:80])
                else:
                    flush()
                    current = {
                        "instrument": inst["id"],
                        "article": number,
                        "page": page_index + 1,
                        "bab": bab,
                        "bab_title": bab_title,
                        "section": section,
                        "ayat": [],
                    }
                    pending = None
                    expected = number + 1
                    rest = rest.lstrip(" .,:")
                    if rest:
                        pending = {"number": 0, "text": rest}
                        current["ayat"].append(pending)
                    i += 1
                    continue

            m_bab = RE_BAB.match(line) or RE_BAB_TITLE.match(line)
            if m_bab:
                flush()
                bab = m_bab.group(1)
                if m_bab.lastindex and m_bab.lastindex >= 2:
                    bab_title = m_bab.group(2).strip()
                elif i + 1 < len(lines):
                    bab_title = lines[i + 1].strip()
                else:
                    bab_title = None
                section = None
                i += 1
                continue
            if RE_BAGIAN.match(line):
                flush()
                section = line.strip()
                i += 1
                continue
            if current is None:
                i += 1
                continue
            m_ayat = RE_AYAT.match(line)
            if m_ayat:
                number = int(m_ayat.group(1))
                next_ayat = len([a for a in current["ayat"] if a["number"] > 0]) + 1
                # "(1)" also appears mid-sentence when a page breaks after
                # "pada ayat". Numbered ayat run 1, 2, 3, so only the next
                # number is a marker; anything else is body text.
                if number == next_ayat:
                    pending = {"number": number, "text": m_ayat.group(2).strip()}
                    current["ayat"].append(pending)
                    i += 1
                    continue
            if pending is None:
                pending = {"number": 0, "text": ""}
                current["ayat"].append(pending)
            pending["text"] = (pending["text"] + " " + line).strip()
            i += 1

    flush()

    return {
        "instrument": inst["id"],
        "pages": page_count,
        "body_pages": body_end,
        "attachment_page": attachment + 1 if attachment < page_count else None,
        "articles": len(articles),
        "articles_max": max((a["article"] for a in articles), default=0),
        "articles_missing": sorted(set(range(1, expected)) - {a["article"] for a in articles}),
        "rejected_headings": rejected[:20],
        "provisions": emit(articles),
    }


def emit(articles: list[dict]) -> list[dict]:
    """One record per ayat, and per item of a definition list, which Indonesian
    statutes use instead of numbered ayat in the opening chapter."""
    out = []
    for a in articles:
        rows = []
        definition_chapter = "ketentuan umum" in (a["bab_title"] or "").lower()
        for ay in a["ayat"]:
            text = re.sub(r"\s+", " ", ay["text"]).strip()
            text = re.sub(r"(\s*\.\s*){3,}$", "", text).strip()
            if not text:
                continue
            parts = [text]
            if definition_chapter and ay["number"] == 0:
                parts = [s.strip() for s in re.split(r"(?<=\s)(?=\d{1,3}\.\s)", text) if s.strip()]
            for index, part in enumerate(parts):
                rows.append((ay["number"], index if len(parts) > 1 else 0, part))

        for ay, item, text in rows:
            if not re.search(r"[A-Za-z]{3}", text) or len(text) < 15:
                continue
            out.append({
                "instrument": a["instrument"],
                "article": a["article"],
                "ayat": ay,
                "item": item,
                "page": a["page"],
                "bab": a["bab"],
                "bab_title": a["bab_title"],
                "hash": hashlib.sha256(text.encode("utf-8")).hexdigest()[:16],
                "text": text,
            })
    return out


def main() -> None:
    CORPUS.mkdir(exist_ok=True)
    provisions = []
    index = []

    for inst in INSTRUMENTS:
        parsed = parse_instrument(inst)
        provisions.extend(parsed.pop("provisions"))
        index.append({**parsed, "title": inst["title"]})
        print(
            f'{inst["id"]:16s} pages={parsed["pages"]:4d} '
            f'articles={parsed["articles"]:4d} '
            f'provisions={sum(1 for p in provisions if p["instrument"] == inst["id"]):5d} '
            f'missing={parsed["articles_missing"]}'
        )

    (CORPUS / "provisions.json").write_text(
        json.dumps(provisions, indent=1, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (CORPUS / "index.json").write_text(
        json.dumps(index, indent=1, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print("provisions", len(provisions))


if __name__ == "__main__":
    main()
