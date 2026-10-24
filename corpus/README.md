# The corpus index

`provisions.json` records every provision of the eight statutes in `laws/`: the
instrument, article, ayat, page, chapter, and text. `index.json` records, per
instrument, the page count, how many pages are body text, how many articles the
extractor found, and any gap in the article sequence.

The index is provenance. A law in `bend/` names its article; the index says what
that article says and which page it is on. The model never reads this file, so
changing the index cannot change a verdict.

## Build

```sh
uv venv .venv && uv pip install --python .venv/bin/python pymupdf
.venv/bin/python tools/build_corpus.py
```

## Scanned instruments

PM 111/2015 has no text layer at all, and PP 30/2021 has one that loses article
headings (Pasal 5, 13, 22, 24, 32, 36, 42 and 46 are missing from it). Both are
scans, so they are read by OCR:

```sh
apt-get install tesseract-ocr tesseract-ocr-ind
python3 tools/ocr_pages.py pm-111-2015 pp-30-2021
```

Each run writes `ocr/<instrument>.txt`, a page-delimited transcript at 300 dpi
with the Indonesian model. The transcript is committed, so a rebuild does not
need Tesseract, and `tools/build_corpus.py` prefers it over the embedded layer.

## What the extractor guarantees

- Article numbers run 1..N. A heading only counts when it names the next
  expected number, which rejects `Pasal 12 ayat (3) mempunyai tugas:` in the
  middle of a sentence.
- Numbered ayat run 1, 2, 3 for the same reason: `(1)` also appears when a page
  breaks after `pada ayat`.
- Body, explanatory notes (`PENJELASAN`) and attachments (`LAMPIRAN`) are
  separated, so an article number in the notes cannot be mistaken for the
  article itself.
- A provision is kept only if it carries at least three letters and 15
  characters, which drops the `. . .` markers a page break leaves behind.

Every instrument currently runs 1..N with no gap. `index.json` records that, and
a regression would show up there first.

## Limits

- PP 30/2021's OCR drops some ayat markers, so its provisions are coarser than
  the other instruments: 92 records over 62 articles, against 786 over 326 for
  UU 22/2009. Article-level reading is unaffected.
- Text is a faithful read of the page, not a certified transcript. The PDF is
  the source of record; use the page number.
