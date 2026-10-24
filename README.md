# lajur

[![proofs](https://github.com/elianiva/lajur/actions/workflows/proofs.yml/badge.svg)](https://github.com/elianiva/lajur)

Indonesian traffic law as named claims a compiler checks, next to the statutes
they come from.

Status: 8 instruments, 50 scenario rules, 109 sign rules, 358 laws. All proofs check with Bend
2.0.39, and the Lean 4.34.0 kernel accepts the verdict.

## The idea

A statute is a list of requirements. So a law file should be a list of claims,
one per requirement, named after what it requires:

```text
law bike_driver_must_wear_helmet:
  for b: Bool
  { R.contains(12, R.charges(R.with_bike(0, b, True{}))) == Bool.not(b) : Bool }

law a_motorway_is_100:
  { M.speed_limit(M.Motorway{}) == 100 : U32 }

law issuing_a_licence_runs_five_steps:
  { L.issue_steps() == 5 : U32 }

law leaving_a_crash_costs_three_years_and_75000000:
  { Bool.and(U32.is_eq(R.months_of(28), 36), U32.is_eq(R.fine_of(28), 75000000)) == True{} : Bool }

law stopping_at_a_no_stopping_sign_is_charged:
  { R.contains(8, R.charges(R.sign_stopping(M.NoStopping{}, True{}))) == True{} : Bool }
```

Change the speed table to 110 and `a_motorway_is_100` stops checking. Change
the helmet rule and `bike_driver_must_wear_helmet` stops checking. The verdict
and the text a player reads come from the same catalogue, so they cannot drift.

## Why this shape

A quiz tells you the answer. A driving situation makes you choose before you
know the answer, and the useful part comes after: which rule you broke, which
article says so, and what it costs.

That feedback needs one rule set, not two. So the rules are data. The
adjudicator returns rule ids; the catalogue turns an id into a citation, a
tier, and a sanction. The explanation reads the same catalogue, so the text a
player sees cannot drift from the logic that judged them.

Two more forces shape the model:

- **The law moves.** A third amendment to UU 22/2009 is in progress, with a
  target of 2026 for passage and 2027 for effect. Rules must carry an effective
  window, not sit in code.
- **Not every obligation has a sanction.** Pasal 108 requires the left lane,
  but the criminal chapter assigns no fine for a private driver. The model
  records zero, not a guess.

## Layout

```text
laws/     the statutes, unmodified, plus an index with checksums and sources
corpus/   every provision indexed by article, ayat and page
bend/     the model and the laws
docs/     categories, the model, known gaps
tools/    the extractor that builds corpus/
```

## The model

`bend/rules.bend` holds three things:

- **Scenario.** Six records: road, load, equipment, motion, priority, papers,
  plus a sign act: the posted duty and the actions a sign rule reads.
- **Catalogue.** 50 rules. Each carries `tier`, `months`, `days`, `fine`, the
  article that imposes the duty, and the article that punishes breaking it.
- **Adjudicator.** `charges(scenario)` returns violated rule ids in ascending
  order. Nothing else. Rule 8 applies the duty a sign posts.

`bend/model.bend` holds the vocabulary the laws share: the instruments, speed by
zone, sign families and duties, licence classes and validity, road classes.

Seven more modules hold what a moment cannot express:

| Module | Instrument | Content |
| --- | --- | --- |
| `signs.bend` | PM 13/2014 | 347 signs in seven tables, 109 operative sign rules, five supplement kinds |
| `network.bend` | PP 79/2013, PM 111/2015, PM 13/2014 | Road functions, class dimensions, grounds for lowering a limit, sign placement |
| `licence.bend` | Perpol 5/2021 | Requirements, health checks, test stages, pass mark, retakes, validity |
| `vehicle.bend` | UU 22/2009 | Type test, periodic test, the kit, the technical items |
| `safety.bend` | PP 37/2017 | Five pillars, plan periods, the ten elements of a safety system |
| `service.bend` | PP 30/2021, UU 22/2009 | Traffic impact analysis, terminals, papers, insurance |
| `works.bend` | UU 28/2014 | Copyright terms, and why a statute carries none |

## What is modelled

| Instrument | Laws | What the laws state |
| --- | --- | --- |
| UU 22/2009 | 68 + 13 | 51 behaviour laws over 50 rules, 9 penalties, 8 catalogue properties, and the vehicle: type test, periodic test, kit, technical items |
| Perpol 5/2021 | 32 | Classes, ages, validity, health checks, test stages, pass mark, retakes |
| PM 13/2014 | 195 | 347 signs, 109 operative sign rules, families, colours, placement, heights, warning distances, supplements |
| PP 30/2021 with UU 22/2009 | 12 | Impact analysis, approval authority, warnings, terminals, papers, insurance |
| PP 37/2017 | 11 | Pillars, plan periods, safety system elements, ratios |
| PP 79/2013 | 10 | Functions, class dimensions, axle load, signing |
| PM 111/2015 | 9 | Four ceilings, one floor, four grounds for lowering, the three-year window |
| UU 28/2014 | 8 | Five exemptions, five terms, and why this corpus may be stored |

`docs/taxonomy.md` explains the twelve categories a provision can fall into and
why definitions, standards and duties are each modelled differently.

## Run the checks

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
export PATH="$HOME/.bend/bin:$PATH"

cd bend
bend PROOF.bend
```

Expected output:

```text
ALL PROOFS CHECK
```

`bend PROOF.bend --verdict` re-checks every proof with Bend's Lean kernel. It
needs Lean 4.34.0, which `lean-toolchain` pins:

```sh
curl -fsSL https://elan.lean-lang.org/elan-init.sh |
  sh -s -- -y --default-toolchain "$(cat lean-toolchain)"
export PATH="$HOME/.elan/bin:$PATH"

cd bend
bend PROOF.bend --verdict
```

CI runs both checks on every push.

A fresh Amp orb gets this toolchain from `.agents/setup`, which also installs
the venv the corpus tools use and tesseract for the OCR step.

## Rebuild the corpus index

The index records where each article sits, page by page. It is how a law leads
back to the statute, not an input to the model.

```sh
uv venv .venv && uv pip install --python .venv/bin/python pymupdf
.venv/bin/python tools/build_corpus.py
```

Two instruments carry no usable text layer. `tools/ocr_pages.py` renders their
pages and OCRs them into `corpus/ocr/`; the extractor prefers a transcript when
one exists. Tesseract with the Indonesian model is needed for that step only.

## What the checks cover, and what they do not

Covered: every rule's condition, every sanction the catalogue states, every
numeric table the statutes set, the procedure deadlines, the competence rules,
the class and licence boundaries, every coded sign in PM 13/2014, every
prohibition and command sign's operative rule, and twelve golden verdicts with
a law each.

Not covered:

- **Legal reading.** The model encodes the plain text of the cited articles. It
  is not legal advice, and it does not resolve conflicting local practice.
- **Sequence.** A scenario is one moment. Following too closely, and the duty
  to slow before a hazard, need time, so they are out of the slice.
- **Unbounded counts.** The passenger law checks 0 to 3 passengers, the range
  the scenarios use. A proof for every natural number needs induction the
  current model does not carry.
- **Local rules.** Provincial and municipal regulations add signs and limits.
  They are out of scope until the rule package has a jurisdiction field.
- **Values printed on a leaf.** A length, height, width, following distance or
  speed sign carries its number on the leaf. The model records a variable sign
  with a limit of zero and does not charge until a scenario supplies the value.
- **Principles and transitions.** *Asas*, *tujuan*, effective dates and repeal
  state no requirement a moment can break. See `docs/taxonomy.md`.

## Roadmap

1. **v0.** 19 rules, 9 scenarios, 10 laws, one instrument.
2. **v1, this commit.** 8 instruments, 50 scenario rules, 109 sign rules, 358 laws, one per requirement,
   with the corpus indexed by page.
3. **v1.1.** Scenario JSON, a TypeScript port of the adjudicator, and a harness
   that runs the same corpus in both. The game needs the port; the proofs keep
   it honest.
4. **v2.** Rule packages with `effective_from` and `effective_to`, plus the
   third amendment once it is enacted.
5. **v3.** A playable slice: short situations, a verdict with the article, and
   a pre/post quiz that measures learning.

## Sources

| Instrument | Why it is here | File |
| --- | --- | --- |
| UU 22/2009 | The statute. Obligations, prohibitions, sanctions. | `laws/uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf` |
| PP 30/2021 | Implementing regulation: impact analysis, terminals, testing. | `laws/pp-30-2021-penyelenggaraan-llaj.pdf` |
| PP 37/2017 | Road safety plans and the company safety system. | `laws/pp-37-2017-keselamatan-llaj.pdf` |
| PP 79/2013 | Road network, functions and classes. | `laws/pp-79-2013-jaringan-llaj.pdf` |
| PM 13/2014 | Traffic signs, shapes, colours, placement. | `laws/pm-13-2014-rambu-lalu-lintas.pdf` |
| PM 111/2015 | The numeric speed limits. | `laws/pm-111-2015-batas-kecepatan.pdf` |
| Perpol 5/2021 | The SIM exam this audience prepares for. | `laws/perpol-5-2021-sim.pdf` |
| UU 28/2014 | Pasal 42: no copyright in statutes, so the text is reusable. | `laws/uu-28-2014-hak-cipta.pdf` |

See [`laws/README.md`](laws/README.md) for pages, checksums, and download
sources, and [`corpus/README.md`](corpus/README.md) for how the index is built.

## Reuse

The PDFs are statutes and regulations. Under Pasal 42 of UU 28/2014 they carry
no copyright, and they are stored here unmodified. Code in this repository is
MIT.

This project is not affiliated with, endorsed by, or connected to POLRI,
Korlantas, or Kementerian Perhubungan. Do not use their logos or present the
model as official guidance.
