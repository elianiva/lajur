# lajur

[![proofs](https://github.com/elianiva/lajur/actions/workflows/proofs.yml/badge.svg)](https://github.com/elianiva/lajur)

Indonesian traffic law as named claims a compiler checks, next to the statutes
they come from.

## What it is

- `laws/` holds the statutes, unmodified, with checksums and download origins.
- `bend/` states what those statutes require as Bend claims: one claim per
  requirement, named after the requirement, each one proved.
- `web/` drives the result. Its street, traffic, speed ceiling and verdict come
  from the same model, so the rule that judges a player is the rule a proof
  covers.

A claim that stops checking stops the build. A wrong speed limit, a missing
article or a penalty that drifts from the statute cannot ship quietly.

## Why

A quiz asks you to recall an article. A drive asks you to decide before you know
the answer, and the useful part comes after it: which rule you broke, which
article says so, and what the statute allows as a penalty.

That feedback needs one rule set, not two. The adjudicator returns rule ids. The
catalogue turns an id into a citation, a tier and a sanction. The explanation
reads the same catalogue, so the words on screen cannot drift from the logic
that judged.

The goal is a drive whose every verdict traces to an article, and whose every
rule is proved.

## A statute as claims

A statute is a list of requirements. So a law file is a list of claims, one per
requirement, named after what it requires:

```text
law bike_driver_must_wear_helmet:
  for b: Bool
  { R.contains(12, R.charges(R.with_bike(0, b, True{}))) == Bool.not(b) : Bool }

law a_motorway_is_100:
  { M.speed_limit(M.Motorway{}) == 100 : U32 }

law leaving_a_crash_costs_three_years_and_75000000:
  { Bool.and(U32.is_eq(R.months_of(28), 36), U32.is_eq(R.fine_of(28), 75000000)) == True{} : Bool }
```

The helmet law starts from a clean road, one motorcycle, no passenger, and then
varies the rider's helmet. Everything else stays lawful, so the verdict isolates
the one thing the rule is about. Change the speed table to 110 and
`a_motorway_is_100` stops checking. The number appears twice on purpose: once in
the table the model uses, once in a law that pins it to the statute.

Five decisions keep that shape honest:

- **Rules are data.** The catalogue owns the citation, the tier and the
  sanction. The adjudicator detects violations and returns ids, and decides
  nothing else.
- **Every rule names its article.** No article, no rule.
- **Nothing is invented.** Where the statute assigns no fine to a private
  driver, the catalogue records zero. Pasal 108 requires the left lane, and the
  criminal chapter names no fine for it, so the model says none.
- **Precedence is explicit.** An officer's direction outranks a signal, a signal
  a sign, a sign a marking, and a marking the general rule.
- **A scenario is one moment.** Following too closely and slowing before a
  hazard need time, so they stay out until a scenario can carry a trace.

### Not every provision is a duty

A statute also defines terms, sets numbers, allocates powers and states
procedures. Each category gets the representation it can support: a definition
becomes a datatype, a number a table, a procedure a step count and a deadline, a
principle nothing at all. `docs/taxonomy.md` lists the twelve categories and why
they differ.

### The text is the source of record

`corpus/` indexes every provision by instrument, article, ayat and page. It is
how a claim leads back to the page that states it. The model never reads it, so
the index cannot change a verdict. `corpus/README.md` covers the rebuild, the
OCR step for the instruments without a text layer, and the extractor's
guarantees.

## The drive

`web/` is where the model is felt. `index.html` drives through the generated
world: an endless lattice of arterials and collectors, cut into cells of
kampung, ruko rows, sawah and civic courts. The car drives the main roads:
arterials, undivided with two lanes each way, and collectors with one lane
each way. In the last hundred metres before a crossing, the indicator chooses
the road: left, right, or straight on with no signal. Away from a crossing, a
tap up to sixty metres before a lokal street's mouth turns the car into the
kampung, at 30 km/h: the indicator picks each junction, a dead end is a
turning circle, and a mouth onto a main road turns out, left unless signalled
right.

Every cell is a function of (seed, i, j), so a worker makes the cells near the
car and the crossing ahead before the car gets there. The renderer bakes each
into a few meshes and drops the cells left behind.

Speed, lanes, lane changes, the gap to the car ahead and the verdict belong to
`logic/game.bend`. The town's lattice is `logic/town.bend`. `logic/PROOF.bend`
proves both, and the TypeScript in `src/` reads the result and draws it.

A crash ends the run: the panel lists each rule broken with its article and its
fine, or says that no article was broken.

`town.html` lays the model out instead of driving it: a warped lattice of
streets, framed whole. Geometry decides each junction's shape and duty, because
a T on a bend is a skew T and a T on a straight is a perpendicular one. The
proof bounds the town's tightest bend from three numbers instead of sampling
geometry.

`lab.html` shows the kit: every building, vehicle and street element on a shelf,
the town again, and the toon looks, with the knobs that tune them.

## The model

`bend/rules.bend` holds three things:

- **Scenario.** Six records — road, load, equipment, motion, priority, papers —
  plus an act: the posted duty, the manoeuvre, and the facts a single rule reads.
- **Catalogue.** One entry per rule, each carrying `tier`, `months`, `days`,
  `fine`, the article that imposes the duty and the article that punishes
  breaking it.
- **Adjudicator.** `charges(scenario)` returns violated rule ids in ascending
  order, and nothing else.

`bend/model.bend` adds the vocabulary those rules share: instruments, speed by
zone, sign families and duties, licence classes and validity, road classes.

The catalogue is about a driver in a moment. The other instruments say what a
moment cannot, so each has its own module and its own laws:

| Module | Instrument | What the laws state |
| --- | --- | --- |
| `signs.bend` | PM 13/2014 | Every coded sign, and the duty each prohibition and command sign posts |
| `network.bend` | PP 79/2013, PM 111/2015, PM 13/2014 | Road functions, class dimensions, grounds for lowering a limit, sign placement |
| `licence.bend` | Perpol 5/2021 | Requirements, health checks, test stages, pass mark, retakes, validity |
| `vehicle.bend` | UU 22/2009 | Type test, periodic test, the kit, the technical items |
| `safety.bend` | PP 37/2017 | Pillars, plan periods, the elements of a safety system |
| `service.bend` | PP 30/2021, UU 22/2009 | Traffic impact analysis, terminals, papers, insurance |
| `works.bend` | UU 28/2014 | Copyright terms, and why a statute carries none |

`bend/LAWS.bend` states every law, and `bend/PROOF.bend` proves them one def at
a time. `docs/model.md` covers the catalogue rule by rule, and
`docs/taxonomy.md` holds the current counts.

```text
laws/     the statutes, unmodified, with checksums and sources
corpus/   every provision indexed by article, ayat and page
bend/     the model and the laws
web/      the game: the same model as a Bend program, drawn with three.js
docs/     categories, the model, known gaps
tools/    the extractor that builds corpus/
```

## Checks

The laws and the game's model are Bend programs. A change is done when the
proofs check.

```sh
cd bend
bend PROOF.bend              # the checker
bend PROOF.bend --verdict    # the same proofs through the Lean kernel
```

The first prints `ALL PROOFS CHECK`. The second re-checks the same proofs
through the Lean kernel, so it needs Lean. `.agents/setup` installs Bend for a
fresh orb and runs no proofs. CI runs both commands on every push, and installs
Lean from `lean-toolchain`, which pins the version:

```sh
curl -fsSL https://elan.lean-lang.org/elan-init.sh |
  sh -s -- -y --default-toolchain "$(cat lean-toolchain)"
```

The kernel maps a 4 GiB stack, so a machine with less RAM also needs
`sudo sysctl -w vm.overcommit_memory=1`.

`tools/check_citations.py` runs with the proofs. It reads the catalogue against
the corpus and fails when the article that punishes a rule does not cite the
article that imposes it, or states other numbers:

```sh
.venv/bin/python tools/check_citations.py
```

The game has its own proofs, and its own build checks:

```sh
cd web
vp run proof    # proves logic/game.bend
vp check        # format, lint, types
vp dev          # serves on $PORT
```

`src/game.mjs` is generated from `logic/game.bend`, so never edit it. A rule
that would live in `src/` belongs in the model, with a law next to it.

## What the checks cover

Covered by the proofs: every scenario rule's condition, every sanction the
catalogue states, every numeric table the statutes set, procedure deadlines,
competence rules, class and licence boundaries, every coded sign in PM 13/2014,
every prohibition and command sign's operative rule, the road generator's
bounds, the town's junction duties, and a golden corpus of scenarios whose
verdicts must not change.

Not covered:

- **Legal reading.** The model encodes the plain text of the cited articles. It
  is not legal advice, and it does not resolve conflicting local practice.
- **Sequence.** A scenario is one moment. Following too closely, and whether a
  driver braked early enough for a hazard, need time; the grounds to slow are
  stated (rule 55), the timing is not.
- **Unbounded counts.** The passenger law checks the range the scenarios use. A
  proof for every natural number needs induction the current model does not
  carry.
- **Markings.** Pasal 106 ayat (4) huruf b is rule 9, but its instrument,
  PM 34/2014 tentang Marka Jalan, is not in the corpus yet.
- **Slowing for a warning sign.** Pasal 116 ayat (1) needs a duty on the
  warning table, which carries none: a warning sign only warns here.
- **Local rules.** Provincial and municipal regulations add signs and limits.
  They are out of scope until the rule package has a jurisdiction field.
- **Values printed on a leaf.** A length, height, width, following distance or
  speed sign carries its number on the leaf. The model records a variable sign
  with a limit of zero, and charges nothing until a scenario supplies the value.
- **Principles and transitions.** *Asas*, *tujuan*, effective dates and repeal
  state no requirement a moment can break. See `docs/taxonomy.md`.

## Direction

- **A clock.** Rule packages with an effective window, so an amendment re-dates
  a rule instead of rewriting it.
- **A trace.** A scenario that carries its history, so following distance and
  the timing of a brake can be stated at all.
- **Jurisdictions.** A jurisdiction field, and rule packages that override the
  national text, for the provincial and municipal signs and limits.
- **The town, driven.** The lattice is laid out and drawn. Driving it turns the
  junction geometry into a curriculum.
- **The teaching loop.** Short situations inside the drive, each ending in a
  verdict with the article, and a pre/post quiz that shows whether it taught
  anything.

## Sources

The PDFs are stored unmodified. `laws/README.md` gives pages, checksums,
download origins and the first-page check for each one.

| Instrument | File |
| --- | --- |
| UU 22/2009 | `laws/uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf` |
| PP 30/2021 | `laws/pp-30-2021-penyelenggaraan-llaj.pdf` |
| PP 37/2017 | `laws/pp-37-2017-keselamatan-llaj.pdf` |
| PP 79/2013 | `laws/pp-79-2013-jaringan-llaj.pdf` |
| PM 13/2014 | `laws/pm-13-2014-rambu-lalu-lintas.pdf` |
| PM 111/2015 | `laws/pm-111-2015-batas-kecepatan.pdf` |
| Perpol 5/2021 | `laws/perpol-5-2021-sim.pdf` |
| UU 28/2014 | `laws/uu-28-2014-hak-cipta.pdf` |

## Reuse

The PDFs are statutes and regulations. Under Pasal 42 of UU 28/2014 they carry
no copyright, and they are stored here unmodified. Code in this repository is
MIT.

This project is not affiliated with, endorsed by, or connected to POLRI,
Korlantas, or Kementerian Perhubungan. Do not use their logos or present the
model as official guidance.
